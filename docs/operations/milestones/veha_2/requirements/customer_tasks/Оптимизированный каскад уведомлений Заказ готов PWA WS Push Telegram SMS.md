# Оптимизированный каскад уведомлений «Заказ готов» (PWA WS + Push + Telegram -> SMS.ru)

> **SUPERSEDED 2026-08-04:** ревизия без Telegram — см. [`Каскад уведомлений Заказ готов PWA WS Push WebPush Apple Wallet SMS.md`](Каскад%20уведомлений%20Заказ%20готов%20PWA%20WS%20Push%20WebPush%20Apple%20Wallet%20SMS.md) · artifacts `order_ready_cascade_ws_push_sms/`.

**Дата интейка:** 2026-08-03  
**Источник:** ТЗ заказчика в чате  
**Артефакты:** `docs/operations/milestones/veha_2/artifacts/order_ready_cascade_ws_telegram_sms/`

---

## Текст заказчика (1:1)

# Оптимизированный каскад уведомлений «Заказ готов» (PWA WS + Push + Telegram -> SMS.ru)


**Бизнес-цель:** Гарантированно уведомить клиента о готовности заказа с минимальной себестоимостью. Приоритет: бесплатные каналы (WebSocket, Android WebPush, iOS Apple Wallet) → прямой Telegram Bot. При отсутствии Telegram или блокировке бота — автоматический фоллбэк на SMS через sms.ru.


## Глобальные ограничения
- **Секреты:** Переменные `TELEGRAM_BOT_TOKEN`, `SMS_RU_API_ID`, `SMS_RU_SENDER` читаются строго из `.env`. Хардкод запрещен.
- **Лимит SMS:** Текст SMS-сообщения строго валидируется на длину `<= 70` символов (1 кириллический сегмент). Превышение должно генерировать ошибку валидации до вызова API.
- **Fault Tolerance:** Ошибки сети (timeout, 5xx) или блокировка бота (403 Forbidden) в Telegram не должны ронять фоновые задачи (Sidekiq). Воркер обязан перехватывать исключения и автоматически переключать отправку на SMS.ru.
- **Запрещено:** Изменять существующие контракты API без обеспечения обратной совместимости. Запрещено выполнять синхронные HTTP-запросы к внешним API в основном потоке запроса (только через Sidekiq).


## Сценарии и чек-лист (Для todo.md)
*Каждый пункт `- [ ]` — атомарный таск для TDD-цикла (сначала красный тест, затем зеленый код).*


### Шаг 1: API Endpoint и бесплатные мгновенные каналы
- [ ] **Шаг 1.1: TDD для обновления статуса и WS Broadcast**
  - **Given:** Заказ находится в статусе `in_progress`, существует активный бариста.
  - **When:** Бариста отправляет `POST /api/v1/barista/orders/:id/ready`.
  - **Then:** 
    - Статус заказа в БД обновляется на `ready`.
    - Инициируется WebSocket Broadcast в `OrderChannel` (payload: `{ order_id, status: 'ready' }`).
    - Асинхронно ставятся в очередь джобы: `WebPushService` (Android) и `AppleWalletNotificationService` (iOS APNs).
    - При ошибке сети (500/502) в WS Broadcast: ошибка логируется, но HTTP-ответ 200 OK баристе возвращается (фоновая деградация).


### Шаг 2: Проверка активности (Presence Filter)
- [ ] **Шаг 2.1: TDD для OrderReadyCascadeJob (Presence Check)**
  - **Given:** Заказ переведен в статус `ready`, запущен `OrderReadyCascadeJob`.
  - **When:** Джоба проверяет наличие активной WS-сессии клиента в Redis по ключу `order:{id}:online`.
  - **Then:** 
    - Если `online == true`: Каскад завершается. В лог пишется: `[Cascade][Order #X] User is online via WebSocket. Paid channels skipped.` Внешние API не вызываются.
    - Если `online == false` или ключ отсутствует: Переход к Шагу 3.
    - При краше Redis (500): Джоба падает с retry (Sidekiq default), внешние API не вызываются.


### Шаг 3: Канал 1 — Telegram Bot API (Бесплатно)
- [ ] **Шаг 3.1: TDD для успешной отправки в Telegram**
  - **Given:** Пользователь офлайн (`online == false`), у пользователя заполнен `telegram_chat_id`.
  - **When:** `OrderReadyCascadeJob` вызывает `TelegramBotClient.send_message`.
  - **Then:** 
    - Выполняется `POST https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/sendMessage` с текстом: `Ваш заказ в CODE:BLACK готов к выдаче! codeblack.xyz/o/{order_hash}`.
    - При ответе `200 OK`: Каскад завершается. Лог: `[Cascade][Order #X] Telegram message delivered.`
    - При ответе `400 Bad Request` (неверный chat_id): Переход к Шагу 4, chat_id очищается/логируется.


- [ ] **Шаг 3.2: TDD для фоллбэка при блокировке или сбое Telegram**
  - **Given:** Пользователь офлайн, `telegram_chat_id` присутствует.
  - **When:** `TelegramBotClient` получает ответ `403 Forbidden` (бот заблокирован) или `5xx` / `Timeout` (сетевая ошибка).
  - **Then:** 
    - Ошибка перехватывается без падения Sidekiq-джобы.
    - Лог: `[Cascade][Order #X] Telegram failed (403/5xx). Fallback to SMS initiated.`
    - Управление передается на Шаг 4.


### Шаг 4: Канал 2 — SMS.ru (Платный SMS Fallback)
- [ ] **Шаг 4.1: TDD для валидации и отправки SMS**
  - **Given:** Telegram недоступен, отсутствует или заблокирован.
  - **When:** Вызывается `SmsRuClient.send_sms`.
  - **Then:** 
    - Текст сообщения `CODE:BLACK. Заказ готов! codeblack.xyz/o/{order_hash}` валидируется на длину `<= 70` символов.
    - Если длина > 70: Генерируется `ValidationError`, джоба фейлится без вызова API (защита от списания).
    - Если валидация пройдена: Выполняется `POST https://sms.ru/sms/send` с параметрами `api_id`, `to`, `msg`, `json=1`.
    - Результат (успех или ошибка API) логируется в БД в историю уведомлений заказа (`NotificationHistory`).
    - При ошибке сети (500/400) от sms.ru: Ошибка логируется в БД как `failed`, джоба завершается (или идет в retry в зависимости от политики, но без бесконечного цикла).


## Стратегия тестирования
- **Фреймворк:** RSpec + WebMock (для мокирования внешних HTTP-вызовов) + FactoryBot.
- **Путь к файлам тестов:**
  - `spec/requests/api/v1/barista/orders_spec.rb`
  - `spec/jobs/order_ready_cascade_job_spec.rb`
  - `spec/services/telegram_bot_client_spec.rb`
  - `spec/services/sms_ru_client_spec.rb`
- **Критические кейсы (Edge cases):**
  1. **Presence Check:** При активной WS-сессии (`order:{id}:online == true`) моки Telegram и SMS.ru *никогда* не должны быть вызваны (`expect(WebMock).not_to have_requested(...)`).
  2. **Telegram Success:** При успешном ответе `200 OK` от Telegram, вызов `SmsRuClient` не происходит.
  3. **Telegram Fallback to SMS:** При ответе Telegram `403 Forbidden` или `Net::ReadTimeout`, автоматически и единожды срабатывает вызов `SmsRuClient.send_sms`.
  4. **SMS Length Validation:** Попытка отправить строку длиной 71+ символ генерирует кастомную ошибку валидации *до* любого HTTP-запроса к sms.ru.
  5. **Sidekiq Resilience:** Мокирование `Net::OpenTimeout` для Telegram не должно приводить к статусу джобы `failed` без попытки фоллбэка.


## Exit Criteria (Критерии выхода)
1. Все новые тесты проходят (зеленый статус, `rspec` без failures).
2. Линтер (`rubocop`) и тайпчекер (`tsc` / `steep` / `sorbet`, если применимо) выполняются без ошибок.
3. Каскад последовательно и атомарно проходит этапы: WS -> Presence Check -> Telegram Bot -> SMS.ru.
4. Все секреты (`TELEGRAM_BOT_TOKEN`, `SMS_RU_API_ID`, `SMS_RU_SENDER`) вынесены в `.env` и не фигурируют в коде или логах в открытом виде.
5. Написаны unit-тесты с покрытием всех сценариев ветвления (100% coverage для новых файлов сервисов и джобы).
6. Ошибки внешних API (4xx, 5xx, timeout) перехватываются, логируются и не приводят к крашу воркеров Sidekiq.

---

## Заметки агента

- Интейк PHASE 0 (2026-08-03): текст выше — 1:1 из чата.
- Связь: #35 compact status + Push, #37 OS detect Wallet/WebPush, #38 FCM progress + Apple Wallet.
- **PHASE 1 SPEC (2026-08-03):** канон в `docs/operations/session/todo.md` — Minitest/Solid Queue (не RSpec/Sidekiq); `preparing`+`PATCH update_status` (не `in_progress` / `/api/v1/…/ready`); reuse GuestOrderBroadcaster+FCM+Wallet; presence = `Rails.cache` (не Redis); `Shop::TelegramBotClient` + `mobile_customers.telegram_chat_id`; SMS через расширенный `Shop::SmsRuClient` (`SMS_RU_FROM`); лог = `order_notification_logs`; Migration Gate на DDL.
