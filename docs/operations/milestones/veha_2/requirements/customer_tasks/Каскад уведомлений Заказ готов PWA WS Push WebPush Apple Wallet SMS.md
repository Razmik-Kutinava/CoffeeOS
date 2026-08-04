# Каскад уведомлений «Заказ готов»: PWA WS + Push (WebPush / Apple Wallet) → SMS.ru

**Артефакты:** `docs/operations/milestones/veha_2/artifacts/order_ready_cascade_ws_push_sms/`  
**CBR:** #39 rewrite (v2) — supersedes `Оптимизированный каскад уведомлений Заказ готов PWA WS Push Telegram SMS.md`  
**Дата интейка:** 2026-08-04

---

Каскад уведомлений «Заказ готов»: PWA WS + Push (WebPush / Apple Wallet) → SMS.ru

Бизнес-цель: Гарантированно уведомить клиента о готовности заказа с минимальной себестоимостью. Приоритет отдается бесплатным встроенным каналам (WebSocket, Android WebPush, iOS Apple Wallet Pass). Если клиент не смотрит на экран и офлайн — инициируется автоматический фоллбэк на прямой SMS-канал через sms.ru.

1. Глобальные ограничения

Секреты: Переменные SMS_RU_API_ID, SMS_RU_SENDER, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY читаются строго из .env. Хардкод секретов в коде запрещен.

Лимит SMS: Текст SMS-сообщения строго валидируется на длину <= 70 символов (1 кириллический сегмент). Превышение лимита должно генерировать исключение ValidationError до выполнения HTTP-запроса к API.

Fault Tolerance: Ошибки сети (timeouts, 5xx) от внешней платформы sms.ru не должны ронять фоновые задачи (Sidekiq/GoodJob). Воркер обязан перехватывать исключения, логировать ошибку в БД и завершаться без падения процесса.

Асинхронность: Запрещено выполнять синхронные HTTP-запросы к сторонним сервисам в основном потоке запроса баристы (все пуши и SMS отправляются строго через фоновые воркеры).

2. Сценарии и чек-лист (Для todo.md)

Каждый пункт - [ ] — атомарная задача для TDD-цикла (сначала пишется падающий тест, затем реализация).

Шаг 1: API Endpoint и бесплатные мгновенные каналы

[ ] Шаг 1.1: TDD для обновления статуса заказа и отправки пушей

Given: Заказ находится в статусе in_progress.

When: Бариста отправляет запрос POST /api/v1/barista/orders/:id/ready.

Then:

Статус заказа в БД меняется на ready.

Инициируется WebSocket Broadcast в OrderChannel (payload: { order_id, status: 'ready' }).

Асинхронно запускаются сервисы отправки пушей: WebPushService (для Android/Desktop) и AppleWalletNotificationService (обновление карточки через APNs для iOS).

В фоновую очередь планируется OrderReadyCascadeJob.

Шаг 2: Проверка активности (Presence Filter)

[ ] Шаг 2.1: TDD для OrderReadyCascadeJob (Presence Check)

Given: Заказ переведен в статус ready, запускается OrderReadyCascadeJob.

When: Джоба проверяет наличие активной WS-сессии клиента в Redis по ключу order:{id}:online.

Then:

Если online == true: Каскад завершается. В лог пишется: [Cascade][Order #X] User is online via WebSocket. SMS skipped. Вызов SmsRuClient не происходит.

Если online == false или ключ отсутствует: Переход к Шагу 3.

При сбое подключения к Redis: ошибка перехватывается, джоба делает стандартный retry без потери логики.

Шаг 3: Канал SMS.ru (Платный SMS Fallback)

[ ] Шаг 3.1: TDD для валидации длины и отправки SMS

Given: Пользователь офлайн (online == false).

When: Вызывается SmsRuClient.send_sms.

Then:

Текст сообщения CODE:BLACK. Заказ готов! codeblack.xyz/o/{order_hash} валидируется на длину <= 70 символов.

Если длина > 70 символов: Генерируется ValidationError, джоба переходит в статус failed без выполнения сетевого запроса (защита от лишних списаний за 2+ SMS).

Если валидация пройдена: Выполняется POST https://sms.ru/sms/send с параметрами api_id, to, msg, json=1.

Результат (успех или код ошибки от API sms.ru) сохраняется в таблице notification_histories (связанной с order_id).

[ ] Шаг 3.2: TDD для обработки сетевых сбоев SMS.ru

Given: Пользователь офлайн, запускается SmsRuClient.send_sms.

When: API sms.ru возвращает HTTP-ошибку (500 Internal Server Error, 502 Bad Gateway или Net::OpenTimeout).

Then:

Сетевое исключение перехватывается.

В notification_histories создается запись со статусом failed и текстом ошибки.

В лог записывается: [Cascade][Order #X] SMS.ru delivery failed: <error_message>.

Основной процесс не падает с Unhandled Exception.

3. Стратегия тестирования

Фреймворк: RSpec + WebMock (для мокирования вызовов WebPush, APNs и SMS.ru) + FactoryBot.

Пути к файлам тестов:

spec/requests/api/v1/barista/orders_spec.rb

spec/jobs/order_ready_cascade_job_spec.rb

spec/services/web_push_service_spec.rb

spec/services/apple_wallet_notification_service_spec.rb

spec/services/sms_ru_client_spec.rb

Критичные тест-кейсы (Edge Cases):

Presence Check (Online): Если order:{id}:online == true, то вызов SmsRuClient.send_sms никогда не происходит (expect(SmsRuClient).not_to receive(:send_sms)).

Presence Check (Offline): Если order:{id}:online == false, вызывается SmsRuClient.send_sms.

SMS Validation Failure: Передача строки из 71+ символа блокирует отправку до вызова HTTP-клиента.

Push Services Parallel Run: Запуск задачи ready инициирует отправку и WebPushService, и AppleWalletNotificationService параллельно, не блокируя друг друга.

4. Критерии приемки (Exit Criteria)

[ ] Все новые тесты успешно проходят (rspec без ошибок).

[ ] Линтер и статический анализатор (rubocop / tsc) выполняются без предупреждений.

[ ] Цепочка последовательно и корректно отрабатывает логику: PWA WS / Push -> Redis Presence Check -> SMS.ru.

[ ] Все секреты (SMS_RU_API_ID, SMS_RU_SENDER, VAPID/APNs ключи) вынесены в .env и не содержатся в коде.

[ ] Покрытие тестами (Coverage) новых сервисов и джобы составляет 100%.

[ ] Сетевые сбои sms.ru корректно логируются и не приводят к критическому падению Sidekiq-воркеров.

---

## Заметки агента

- Ревизия #39: Telegram **убран** из каскада (v1: WS→TG→SMS).
- Стек CoffeeOS: Minitest / Solid Queue / Rails.cache / FCM+Wallet уже есть / `order_notification_logs` вместо `notification_histories`.
- Маппинг имён — в `docs/operations/session/todo.md`.
