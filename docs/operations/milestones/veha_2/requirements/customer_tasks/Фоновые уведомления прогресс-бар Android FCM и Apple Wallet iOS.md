# Фоновые уведомления, прогресс-бар (Android FCM) и интеграция Apple Wallet (iOS)

**Дата интейка:** 2026-08-03  
**Источник:** ТЗ заказчика в чате  
**Артефакты:** `docs/operations/milestones/veha_2/artifacts/background_notifications_fcm_apple_wallet/`

---

## Текст заказчика (1:1)

# Фоновые уведомления, прогресс-бар (Android FCM) и интеграция Apple Wallet (iOS)

**Бизнес-цель:** Обеспечить пользователя актуальным статусом заказа, визуальным прогрессом и контекстными действиями в фоновом режиме (шторка уведомлений Android / Apple Wallet iOS) без необходимости держать PWA открытым, снижая нагрузку на поддержку и повышая CX.

## Глобальные ограничения
- **Запрещено изменять:** `Barista::OrdersController`, `Barista::OrderStatusUpdateService` (логика БД и логов).
- **Запрещено изобретать UI:** Строго запрещено добавлять новые CSS-переменные, кастомные Tailwind-классы, анимации или отступы. Все новые компоненты (прогресс-бар, кнопки, формы чаевых, `strip.png` для Wallet) должны на 100% использовать существующий UI-кит и стили из кодовой базы.
- **Запрещено менять архитектуру источника правды:** Смена статуса остается через `PATCH /barista/orders/:id/update_status`. Вся новая логика рассылки инкапсулируется строго в `Shop::GuestOrderBroadcaster` и вызываемых сервисах.

## Сценарии и чек-лист (Для todo.md)

- [ ] Шаг 1: Обогащение FCM Payload и дедупликация (Android)
  - **Given:** Заказ находится в статусах `accepted`, `preparing` или `ready`. Сервис `Shop::OrderStatusPushNotifier` готов к отправке.
  - **When:** Бариста меняет статус заказа (триггер `PATCH /barista/orders/:id/update_status`).
  - **Then:** FCM payload содержит ключ `tag: "order-#{order.id}"` (пуши заменяют друг друга). Массив `actions` сформирован согласно Матрице состояний. Текст уведомления содержит Юникод-индикатор прогресса (🟩⬜⬜ / 🟩🟩⬜ / 🟩🟩🟩). При ошибке генерации payload (500) сервис логирует ошибку и прерывает отправку без краша основного потока.

- [ ] Шаг 2: Обработка кликов по Action Buttons в Service Worker (Android)
  - **Given:** Пользователь получил обогащенный FCM push в шторке Android.
  - **When:** Пользователь кликает по кнопке действия (Cancel, Chat, Tips) в уведомлении.
  - **Then:** Для `cancel` выполняется фоновый `fetch` к API отмены. Для `chat`/`tips` происходит фокус на PWA и переход по deep link. При сетевой ошибке (400/500) во время фонового `fetch` на отмену, Service Worker показывает локальное уведомление об ошибке ("Не удалось отменить, проверьте сеть") и не блокирует UI.

- [ ] Шаг 3: Генерация и скашивание .pkpass карты (iOS Backend)
  - **Given:** Заказ в статусе `accepted`. На фронтенде нажата кнопка "Добавить в Apple Wallet".
  - **When:** Фронтенд запрашивает генерацию passes у бэкенда.
  - **Then:** Бэкенд генерирует валидный `.pkpass` файл. Лицевая сторона содержит крупный QR-код (для `ready`) или статус. Оборотная сторона содержит ссылки на Чат и Чаевые. `strip.png` генерируется с использованием строго существующих UI-компонентов прогресс-бара PWA. При ошибке чтения сертификата Wallet (500) API возвращает 500 с понятным сообщением, фронтенд показывает toast-ошибку.

- [ ] Шаг 4: Динамическое обновление Apple Wallet через APNs
  - **Given:** Пользователь добавил карту в Apple Wallet. Бариста меняет статус заказа.
  - **When:** Срабатывает `Shop::GuestOrderBroadcaster.call`.
  - **Then:** Вызывается новый `Shop::AppleWalletPassUpdater.call`. Сервис отправляет push-сигнал в APNs. Карта на устройстве обновляется: меняется текст статуса и подменяется `strip.png` (Шаг 1 -> Шаг 2 -> Шаг 3). На заблокированный экран приходит уведомление. При таймауте APNs или невалидном token устройства сервис корректно обрабатывает ошибку, логирует её и не прерывает работу Broadcaster.

- [ ] Шаг 5: PWA UI State Machine (Карточка заказа)
  - **Given:** Пользователь открыт PWA, находится на экране карточки заказа.
  - **When:** Статус заказа меняется через WebSocket/SSE от `GuestOrderBroadcaster`.
  - **Then:** UI карточки обновляется согласно Матрице состояний. В `accepted` отображаются [Отменить] и [Включить Push/Wallet]. В `preparing` кнопка [Отменить] исчезает, появляются [Чат] и [Чаевые/Wallet]. Максимум 2 кнопки. Все элементы отрисованы с использованием только существующих CSS-переменных и Tailwind-классов. При обрыве WebSocket (ошибка сети) UI сохраняет последнее известное состояние и показывает индикатор переподключения.

## Стратегия тестирования
- **Фреймворк (Backend):** RSpec.
- **Фреймворк (Frontend):** Vitest (Unit/Component) + Playwright (E2E).
- **Путь к файлам тестов:** 
  - Backend: `spec/services/shop/order_status_push_notifier_spec.rb`, `spec/services/shop/apple_wallet_pass_updater_spec.rb`, `spec/services/shop/guest_order_broadcaster_spec.rb`.
  - Frontend: `tests/unit/services/sw-notification-handler.spec.ts`, `tests/e2e/order-card-actions.spec.ts`.
- **Критические кейсы:**
  - *Асинхронность и Race Conditions:* Быстрое последовательное изменение статусов баристой (accepted -> preparing -> ready). Проверка, что APNs и FCM не теряют порядок и `strip.png` не застревает на промежуточном шаге.
  - *Edge cases FCM:* Поведение Service Worker при холодном старте приложения и клике по action button.
  - *Edge cases Wallet:* Обработка истекшего сертификата Apple Wallet, невалидных APNs tokens, превышения лимита размера `.pkpass` (strip.png слишком тяжелый).
  - *Сетевые сбои:* Эмуляция 500/400 ответов при фоновом вызове API отмены из шторки Android.

## Exit Criteria (Критерии выхода)
1. Все новые тесты (RSpec, Vitest, Playwright) проходят (зеленый статус).
2. Линтер (Rubocop/ESLint) и тайпчекер (`tsc --noEmit`) выполняются без ошибок.
3. `Barista::OrdersController` и `Barista::OrderStatusUpdateService` не содержат изменений (проверка через `git diff`).
4. Визуальный ревью подтверждает 100% использование существующего UI-кита (нет инлайн-стилей, нет новых CSS-переменных).
5. Дедупликация push-уведомлений на Android работает (в шторке всегда только один актуальный пуш на заказ).

---

## Заметки агента

- Интейк PHASE 0 (2026-08-03): текст выше — 1:1 из чата.
- Связь: #35 compact status + Push/Wallet (server), #37 OS detect + Wallet/WebPush CTA (Fly v419), B1.1 progress bar.
- **PHASE 1 SPEC (2026-08-03):** канон в `docs/operations/session/todo.md` — Minitest/JS `.mjs` (не RSpec/Vitest); `Shop::AppleWallet::PassUpdater` (не новый top-level); FCM через notifier+SW `firebase-messaging-sw.js`; матрица из шага 5 ТЗ; Chat/Tips = deep link (продукта нет); barista status files — не трогать.
- **PHASE 3 REVIEW (2026-08-03):** шаги 1–5 GREEN; Rails 33/127 · JS 40/40; barista без diff; MCP/deploy ждут апрув; PKCS7/chat UI — backlog.
