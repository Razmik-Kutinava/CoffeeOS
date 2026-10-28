# TASK_92: Production background FCM и синхронизация статусов заказа

**ID заказчика:** TASK_92 · **CBR:** #92 · **Дата intake:** 2026-09-17  
Уточнение 2026-10-18 (метки): в коммитах TASK_92 подписаны «#94» (20c05ba6, f274c11c, 39601e94), не путать с TASK_94.  
Уточнение 2026-10-18 (шаг 5): чаевые как запасной CTA отменены (0fe747a0); в preparing и ready без подписки CTA «Чат» и push или Wallet, при подписке «Чат» (и «Оформить подписку» на ready, если оффер включён).  
Уточнение 2026-10-18 (шаги 3–4, Wallet): в коде вместо AppleWalletPassUpdater.call из Broadcaster ставится PassUpdateJob (на ready пропускается); Wallet не используется как канал уведомлений для iPhone (по схеме Б2, 2026-10-16; см. TASK-IOS-PUSH-PATH).  
**Источник:** текст заказчика (правка по фоновым уведомлениям) + Google Doc  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/production_background_fcm_status_sync/  
**Google Doc:** https://docs.google.com/document/d/1gcML9WkV4n2s6KNsDN0sobY3ITm4Dge9kOjStzf917g/edit?usp=sharing  
**Google Doc TASK_92 (тело + патчи, очередь Push + SMS):** https://docs.google.com/document/d/1GlRrdNGaXuSTTCYEKBN1dem8hB0A0WPnC2w9O_gi-mc/edit  
**Связь:** reopen / gap — [#38 Фоновые уведомления…](Фоновые%20уведомления%20прогресс-бар%20Android%20FCM%20и%20Apple%20Wallet%20iOS.md) · [#81 Косяки…](Косяки%20уведомлений%20Wallet%20WebPush%20фоновые%20и%20кнопка%20чат.md) · [#41 Action Buttons…](Динамический%20блок%20действий%20Action%20Buttons%20в%20статусной%20панели%20заказа.md)  

---

## Текст заказчика (дословно)

Задачи по правкам:

9/ 
не реализовано  фонавая поддержка уведомления
https://docs.google.com/document/d/1gcML9WkV4n2s6KNsDN0sobY3ITm4Dge9kOjStzf917g/edit?usp=sharing
# Фоновые уведомления, прогресс-бар (Android FCM) и интеграция Apple Wallet (iOS)
Это задача не может быть реализована так как сам модуль подключения push-уведомлений через браузер не реализован

кнопка чат с поддержкой не работает, 

но показывается согласно задаче по подтасикванию кнопки \ смене текста кнопки в статусной модели

Задача реализована полностью" (конец цитаты) нажмите L, чтобы поставить ссылку на исходное сообщение" (конец цитаты) нажмите L, чтобы поставить ссылку на исходное сообщениетак, на сегодня все, вот правка по это задаче

п.1 не реализовано фоновая поддержка уведомления

 TASK_92: Production background FCM и синхронизация статусов заказа
 TASK_92: Production background FCM и синхронизация статусов заказа

---

## Google Doc (1:1, MCP 2026-09-17)

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

- ID заказчика **TASK_92** = CBR **#92**.
- Google Doc MCP: `user-google-docs` / `docs_read_document` — документ прочитан 2026-09-17; содержимое совпадает с каноном #38.
- Фокус правки заказчика: **п.1 не реализовано** — фоновая поддержка уведомлений (FCM в шторке Android без открытой PWA).
- Комментарий заказчика: «это задача не может быть реализована так как сам модуль подключения push-уведомлений через браузер не реализован» — продуктовый блокер/зависимость от WebPush subscribe (#37 / TASK_90).
- Второй gap: кнопка «чат с поддержкой» **показывается** по статусной модели (подстановка/смена текста CTA), но **не работает** (клик).
- Оспаривается формулировка «Задача реализована полностью».
- Без правок кода на intake; Next: `go` → `/spec`.
- 2026-10-28 (очередь Push + SMS, шаг 2): документ TASK_92 из очереди (`1GlRrdN…`) прочитан через Google Docs MCP. Его тело (разделы 1–6, Subtask 1–16) в репо раньше не сохранялось — здесь был только текст #38. Патч 1 ссылается на Subtask 4, 5 и 16 тела, поэтому ниже дословно вставлены тело документа и Патч 1. Патч 2 — шаг 3 очереди, будет вставлен после Патча 1. Правки только форматирования: разорванные строки и обрывки `**` из экспорта MCP, команды в блоке кода.
- 2026-10-28: в документе нет «Зависит от» / «Порядок сборки» / «Статус» для Патча 1 — сверять со строкой очереди нечего, расхождения нет. Факты Патча 1 (файл:строка) не сверялись — это `/spec`.
- 2026-10-28 `/spec` Патча 1: все факты совпали с кодом, поведение то же. Сдвиги номеров: очистка мёртвого токена `fcm_client.rb:129-136` (в патче `:129-133`); решение C1 — «Интеграция статусной модели…md:57» (в патче `:55-59`); защитный тест `ready_push_job_test.rb:117-123` (в патче `:117-122`). Дополнительно: при сертификатах Wallet `ApnsClient` всегда бросает ошибку (`apns_client.rb:21`), то есть в этом режиме FCM на ready не уходит никогда. Решения билда — `session/todo.md`.
- 2026-10-28 (очередь Push + SMS, шаг 3): Патч 2 прочитан через Google Docs MCP (тот же документ `1GlRrdN…`, вкладка одна) и вставлен дословно в конец файла, после блока SBR Патча 1. Правки только форматирования: пустые строки между заголовками и абзацами, как у Патча 1. В документе нет «Зависит от» / «Порядок сборки» / «Статус» для Патча 2 — сверять со строкой очереди нечего, расхождения нет. Метка `TASK-PUSH-PREPROMPT` в Scope = TASK_110. Факты Патча 2 (файл:строка, «по факту») не сверялись — это `/spec`.
- 2026-10-28 `/spec` Патча 2: все факты совпали с кодом, поведение то же, сдвигов номеров нет. Уточнения: текст отмены берётся из `OrderCancellationPresenter` (`order_cancellation_presenter.rb:6-7,31-33`), он же отдаёт `cancel_message` в API и Cable — поэтому текст «Вы отменили заказ» делается только в push, presenter не меняется. В `COMPONENT_MAP.md` строки `OrderStatusPushNotifier` нет (патч на неё ссылается) — добавим на review. Команды `npm test -- --run` в проекте нет — тест SW гоняется `node --test`. Решения билда — `session/todo.md`.

---

## Google Doc TASK_92 (1:1, MCP 2026-10-28) — тело документа

# TASK_92: Production background FCM и синхронизация статусов заказа

**Расширяет:** `docs/operations/milestones/veha_2/requirements/customer_tasks/Фоновые уведомления прогресс-бар Android FCM и Apple Wallet iOS.md`  
**Реверсирует:** не применимо  
**Основание:** live-аудит от 2026-09-16; #38 background FCM не подтверждён production device E2E; TASK #81 ранее зафиксировал background support как незакрытый backlog.

Бизнес-цель: обеспечить фактическую доставку и корректное поведение фоновых уведомлений статуса заказа на Android, когда PWA не находится на экране, при этом сохранить единую статусную модель между табло баристы, backend, PWA и push-уведомлением.

## 1. Карта интеграций — затронуто / нет

### Затронуто

Цепочка:
`Barista → PATCH /barista/orders/:id/update_status → OrderStatusUpdateService → GuestOrderBroadcaster → OrderStatusPushNotifier → PushNotification/Job → FcmClient → Firebase → Service Worker → Android notification`

Также затронуты:
1. регистрация FCM;
1. получение/хранение push token;
1. notification permission;
1. Service Worker;
1. background notification actions;
1. deep-link обратно в PWA;
1. синхронизация статуса notification с текущим статусом заказа.

Канонические integration-документы:
1. `docs/integrations/INTEGRATIONS.md`
1. `docs/integrations/pwa-realtime.md`
1. `docs/integrations/notify-loyalty.md`

### Не затронуто

Источник истины статуса не меняется:
`PATCH /barista/orders/:id/update_status`

Запрещено менять бизнес-логику изменения статуса в:
1. `Barista::OrdersController`;
1. `Barista::OrderStatusUpdateService`.

ActionCable остаётся самостоятельным foreground-каналом PWA.

## 2. Карта компонентов

### Существующие компоненты

Затрагиваются:
1. `GuestOrderBroadcaster`;
1. `GuestOrderChannel`;
1. `OrderStatusSheet`;
1. `shopOrderCable.js`;
1. `OrderStatus`;
1. `OrderStatusPushNotifier`;
1. `OrderStatusPushPayload`;
1. `ReadyPushJob`;
1. `SendPushNotificationJob`;
1. `FcmClient`;
1. FCM Service Worker;
1. `firebasePush.js`;
1. `swNotificationActions.js`.

### Общий файл с другой задачей

**Да.**

`GuestOrderBroadcaster` используется одновременно foreground-цепочкой PWA и background push/Wallet/cascade.

Граница:
Эта задача может изменять только push-related поведение `GuestOrderBroadcaster` и вызываемые им push-компоненты в части доставки background FCM.
Нельзя менять существующую Barista status transition logic и нельзя ломать ActionCable broadcast для PWA.

Эта же граница должна быть отражена в `COMPONENT_MAP.md` после Review.

### Новый компонент

**Нет**, пока не доказана необходимость нового компонента.

Сначала использовать существующий FCM pipeline.

## 3. Текущее поведение — факт

Live-аудит 2026-09-16 установил:
1. Production использует реальный FCM path:
`FCM_SIMULATE` не установлен, `FIREBASE_SERVICE_ACCOUNT_JSON` присутствует.
1. Production queue работает:
Solid Queue worker запущен; infrastructure down не обнаружен.
1. Для проверенного guest Aram:
`push_enabled=false`, `push_token` отсутствует.
При таких условиях `OrderStatusPushNotifier` делает silent return до создания `PushNotification`.
Источник:
`app/services/shop/order_status_push_notifier.rb:35–36`.
1. Реальная background FCM доставка на физический Android не доказана.
1. Production device E2E для #38 в найденных артефактах отсутствует.
1. В production DB не обнаружены `PushNotification` с #38-enriched `tag`.
1. После 2026-06-11 свежих production `PushNotification` для проверенного сценария не обнаружено.
1. PWA foreground имеет отдельный канал:
`GuestOrderBroadcaster → ActionCable → shopOrderCable.js → OrderStatusSheet`.
1. `ready` является terminal status для sticky sheet и удаление карточки после `ready` является существующим поведением, а не автоматически дефектом.
1. Не доказано, что проблема background FCM находится внутри `FcmClient`, Firebase или Service Worker, поскольку live transition с валидным production token на физическом Android не был выполнен.

## 4. Scope

### Разрешено

#### 4.1 FCM registration

Обеспечить, чтобы пользовательский сценарий:
`permission granted → FCM token получен → token сохранён → push_enabled=true`
был реально работоспособен в production PWA.

Проверить и при необходимости исправить только существующий registration flow.

#### 4.2 Server-side delivery

Обеспечить фактический production path:
`GuestOrderBroadcaster → OrderStatusPushNotifier → PushNotification → Job → FcmClient → Firebase`.

Для каждого status:
1. `accepted`;
1. `preparing`;
1. `ready`;

должна существовать проверяемая доставка.

#### 4.3 Background notification

При PWA в background Android должен получать notification с актуальным status заказа.

Notification не должна зависеть от того, открыта ли PWA на экране.

#### 4.4 Payload

Сохранить контракт #38:
1. order-specific tag;
1. status;
1. progress;
1. contextual actions;
1. deep link;
1. данные заказа, необходимые Service Worker.

Tag:
`order-#{order.id}`

#### 4.5 Status synchronization

Notification должна соответствовать тому же статусу заказа, который был установлен через Barista flow.

Источник истины:
`PATCH /barista/orders/:id/update_status`.

Не создавать отдельную status state machine внутри FCM.

#### 4.6 Actions

Сохранить существующую матрицу действий #38.

При клике action:
1. Cancel → существующий cancel API flow;
1. Chat → открыть/focus PWA с существующим deep link;
1. Tips → открыть/focus PWA с существующим deep link.

Ошибки cancel API не должны блокировать notification/UI.

#### 4.7 Race

Проверить последовательность:
`accepted → preparing → ready`
в том числе при быстрых последовательных изменениях.

Последнее актуальное состояние не должно быть потеряно из-за:
1. job ordering;
1. duplicate;
1. stale notification;
1. ready claim;
1. retry.

### Запрещено

Не менять:
1. `Barista::OrdersController` в части status update;
1. `Barista::OrderStatusUpdateService` в части DB/status transition;
1. источник истины статуса;
1. ActionCable как foreground transport;
1. существующую PWA status model без отдельного доказанного дефекта;
1. Wallet/APNs в рамках этой задачи, если live-аудит не покажет прямую связь с Android FCM дефектом;
1. CSS/UI kit;
1. новые CSS variables;
1. custom Tailwind classes;
1. произвольные animations/spacing;
1. отдельную status state machine для push.

Не маскировать отсутствие production token через `FCM_SIMULATE`.

## 5. Gherkin

### Subtask 1 — FCM registration

1. **Subtask 1:** Given пользователь открыл PWA и предоставил разрешение на уведомления, When PWA выполняет существующую регистрацию push, Then должен быть получен реальный FCM token и сервер должен сохранить его для этого guest.

### Subtask 2 — accepted background notification

1. **Subtask 2:** Given у guest есть `push_enabled=true` и валидный FCM token, And PWA находится в background, When barista устанавливает статус `accepted`, Then backend должен сформировать и отправить FCM notification с order-specific tag и данными статуса, And Android должен показать notification.

### Subtask 3 — preparing background notification

1. **Subtask 3:** Given notification для заказа уже существует, And PWA находится в background, When barista устанавливает статус `preparing`, Then Android должен получить актуальное notification state для `preparing`, And notification должна содержать предусмотренные для этого статуса actions.

### Subtask 4 — ready background notification

1. **Subtask 4:** Given заказ находится в `preparing`, And PWA находится в background, When barista устанавливает статус `ready`, Then Android должен получить актуальное `ready` notification, And ready notification не должна быть потеряна из-за `ready_notified_at` claim/retry race.

### Subtask 5 — notification deduplication

1. **Subtask 5:** Given один заказ получает несколько последовательных status updates, When FCM notifications доставляются Android, Then notifications одного заказа должны использовать `order-#{order.id}` как tag, And система не должна создавать бесконтрольный набор дублирующих notifications для одного заказа.

### Subtask 6 — status synchronization

1. **Subtask 6:** Given barista изменил статус заказа через существующий status endpoint, When PWA находится одновременно foreground или background, Then PWA через ActionCable и Android notification через FCM должны отражать один и тот же backend status.

### Subtask 7 — foreground independence

1. **Subtask 7:** Given PWA находится foreground, When barista меняет status, Then PWA должна продолжать получать status через существующий ActionCable flow, And FCM не должен становиться источником истины для foreground status model.

### Subtask 8 — Cancel

1. **Subtask 8:** Given заказ находится в статусе, для которого доступен Cancel, When пользователь нажимает Cancel в background notification, Then должен быть вызван существующий cancel API flow, And notification action не должна блокировать основной UI.

### Subtask 9 — Chat

1. **Subtask 9:** Given notification содержит Chat action, When пользователь нажимает Chat, Then должна открыться или получить focus PWA с существующим deep link на заказ.

### Subtask 10 — Tips

1. **Subtask 10:** Given notification содержит Tips action, When пользователь нажимает Tips, Then должна открыться или получить focus PWA с существующим deep link на заказ.

### Subtask 11 — cancel failure

1. **Subtask 11:** Given Cancel API возвращает HTTP 400 или 500, When пользователь нажимает Cancel в notification, Then должна появиться локальная error notification, And ошибка не должна блокировать PWA.

### Subtask 12 — cold start

1. **Subtask 12:** Given PWA не открыта, When пользователь нажимает Chat/Tips/deep-link action в background notification, Then PWA должна запуститься или получить focus и открыть существующий экран заказа.

### Subtask 13 — fast status race

1. **Subtask 13:** Given заказ находится в `accepted`, When barista быстро выполняет `accepted → preparing → ready`, Then все server-side status transitions должны сохраниться, And финальное notification state должно соответствовать `ready`, And старый status не должен оставаться единственным отображаемым состоянием.

### Subtask 14 — FCM failure isolation

1. **Subtask 14:** Given Firebase/FCM delivery возвращает ошибку, When `GuestOrderBroadcaster` обрабатывает status update, Then Barista status transition и ActionCable broadcast не должны быть отменены или сломаны из-за FCM failure.

### Subtask 15 — invalid token

1. **Subtask 15:** Given Firebase возвращает ошибку invalid registration token, When выполняется push delivery, Then ошибка должна быть зафиксирована существующим error handling, And Broadcaster не должен падать из-за этой ошибки.

### Subtask 16 — real production E2E

1. **Subtask 16:** Given production Android device имеет установленную PWA, разрешение notification и реальный FCM token, When barista меняет status заказа, Then background notification должна быть фактически наблюдаема в Android notification tray.

## 6. TDD-проверка: команды

Перед Build проверить реальные существующие пути тестов проекта и не использовать пути из старого #38, если их физически нет.

Минимум:

```text
bundle exec ruby -Itest test/services/shop/order_status_push_notifier_test.rb
bundle exec ruby -Itest test/services/shop/guest_order_broadcaster_test.rb
bundle exec ruby -Itest test/services/shop/order_status_push_payload_test.rb
bundle exec ruby -Itest test/jobs/shop/ready_push_job_test.rb
bundle exec ruby -Itest test/integration/shop/push_pipeline_simulation_test.rb
```

JavaScript:

```text
npm test -- sw_notification_actions
```

или фактическая команда проекта для соответствующего JS test runner.

Перед выполнением команд определить фактический test runner проекта.

После реализации обязательно:

```text
bundle exec rubocop
```

и фактические команды:
1. JS tests;
1. TypeScript check;
1. Playwright/E2E;
1. production/device E2E для background FCM.

### Обязательная проверка

Тесты должны отдельно доказать:
1. notifier создаёт PushNotification при валидном `push_enabled + token`;
1. job реально исполняется;
1. FcmClient вызывается с ожидаемым payload;
1. SW обрабатывает background payload;
1. notification появляется на физическом Android;
1. action click работает;
1. race `accepted → preparing → ready` не теряет финальное состояние;
1. FCM failure не ломает Barista → Broadcaster → Cable.

Unit/simulation test с `FCM_SIMULATE` **не считается доказательством production background FCM**.

### Production DoD

Задача не считается закрытой без:
1. реального Android device E2E;
1. PWA в background;
1. реального FCM token;
1. реального Firebase delivery;
1. наблюдаемого notification tray;
1. проверки минимум `accepted → preparing → ready`;
1. проверки хотя бы одного notification action;
1. проверки FCM failure isolation.

Если physical Android E2E недоступен, документ нельзя считать полностью выполненным — результат должен быть зафиксирован как blocker, а не заменён simulation PASS.

## Патч 1: 2026-10-18

Основание: аудиты B и B2 от 2026-10-13, аудит E от 2026-10-15, факт ready_push_job.rb:20-27,38-39,46,64; ready_push_claim.rb:11-24; send_push_notification_job.rb:29-31; fcm_client.rb:38,106,172-176; application_job.rb:5; job_tenant_context.rb:7-9,29; order_ready_sms_link.rb:61; apns_client.rb:14-21; PRACTICES.md:118 (V2-#35-PUSH-RELIABILITY)

### Расхождение

Subtask 4: было — ready notification не теряется из-за ready_notified_at claim/retry race;
по факту — claim коммитится до update_wallet! и deliver_fcm! (ready_push_job.rb:23, затем :25-26) и не откатывается (job_tenant_context.rb:7-9,29); решение осознанное, из спецификации C1 задачи про нижнюю панель заказа (…Интеграция статусной модели в компактную шторку PWA и Push.md:55-59); риск потери записан как backlog и не закрыт (PRACTICES.md:118);
FcmClient::Error проглатывается: PushNotification = failed, ReadyPushJob завершается успешно, повтора нет (send_push_notification_job.rb:29-31);
сетевая ошибка и сбой OAuth не оборачиваются в FcmClient::Error (fcm_client.rb:38,106,172-176), retry_on закомментирован (application_job.rb:5), ручной повтор останавливается на claim (ready_push_job.rb:23);
сбой Apple Wallet происходит раньше FCM и блокирует его (ready_push_job.rb:25-26); в режиме с сертификатами ApnsClient::Error не перехватывается (ready_push_job.rb:38-39, apns_client.rb:14-21), FCM не отправляется, а повторный запуск останавливается на claim;
при не-FcmClient ошибке PushNotification остаётся pending (ready_push_job.rb:46);
расхождение — при временном сбое доставки ready-пуш теряется безвозвратно.

### Исправленный сценарий

- [ ] Subtask 4 (patch v1): Given claim выполнен, And доставка ready-пуша завершилась временной ошибкой (5xx, 429, timeout, сеть, сбой получения OAuth-токена), When ReadyPushJob обрабатывает ошибку, Then claim освобождается, And доставка повторяется с backoff ограниченное число раз.
- [ ] Subtask 4b (patch v1): Given ошибка постоянная (недействительный токен), Then повторов нет, токен очищается как сейчас (fcm_client.rb:129-133), PushNotification = failed, claim остаётся.
- [ ] Subtask 4c (patch v1): Given любая ошибка обновления Apple Wallet или APNs (GenerationError, UnavailableError, ApnsClient::Error), When выполняется ReadyPushJob, Then FCM отправляется независимо, ошибка Wallet логируется, And claim не приводит к потере пуша из-за ошибки Wallet (ready_push_job.rb:25-26, :38-39).
- [ ] Subtask 4d (patch v1): Given любой исход доставки, Then PushNotification не остаётся в pending.
- [ ] Subtask 4e (patch v1): Given параллельные постановки ready или неоднозначный сбой доставки (ответ FCM не получен), Then в штатной работе уходит не более одного пуша; при неоднозначном сбое допустима повторная отправка, дубль схлопывается по tag order-#{order.id} (Subtask 5 TASK_92). Решение владельца 2026-10-15: редкий повторный показ принят вместо потери пуша.
- [ ] Subtask 4f (patch v1): Given claim освобождён и поставлен заново, Then начало срока жизни SMS-ссылки (order_ready_sms_link.rb:61) не меняется.
- [ ] Subtask 4g (patch v1): Тесты ReadyPushJob: FcmClient::Error (временная и постоянная), сетевая ошибка и сбой OAuth, ошибка Wallet и ошибка APNs, claim вместе с retry, отсутствие pending.

### Не трогать

См. COMPONENT_MAP.md строки FcmClient (data-only, без top-level notification), GuestOrderBroadcaster (на ready PassUpdater вызывает только ReadyPushJob; каскад ставится независимо), OrderStatusPushNotifier (читает ready_notified_at без атомарности, :42).
Решение C1 (ранний claim) сохраняется: перенос claim на момент после отправки в этот патч не входит (это был бы реверс и доп.задача).
Защитные тесты не удалять: ready_push_claim_test.rb:35-47, ready_push_job_test.rb:66-77, :117-122. Актуализировать: ready_push_job_test.rb:90-95 (под 4c), название теста ready_push_claim_test.rb:49-55 (проверяет nil, а называется «claims and enqueues»).
Граница с каскадом: ready_notified_at читает OrderReadySmsLink (:61), семантика этого чтения не меняется.
Исключение из запрета TASK_92 на Wallet/APNs («если live-аудит не покажет прямую связь с дефектом Android FCM»): прямая связь показана аудитом E (ошибка Wallet после claim блокирует FCM, ready_push_job.rb:25-26); изменение ограничено изоляцией ошибки, код Wallet и APNs не меняется. Endpoint скачивания карты (orders_controller.rb:176-183) в этот патч не входит.

### Scope

Разрешено: освобождение claim при неуспешной доставке; retry/backoff для ReadyPushJob с классификацией ошибок; изоляция Wallet от FCM; закрытие pending; тесты; закрытие backlog V2-#35-PUSH-RELIABILITY в PRACTICES.md после Review.
Запрещено: менять момент постановки claim (после отправки); добавлять колонки в orders (ограничение задачи про нижнюю панель заказа); менять payload FcmClient; каскад и решение об SMS; логику статусов Barista; FCM_SIMULATE; доставку accepted/preparing; ActionCable.

## SBR: Патч 1 TASK_92 — потеря ready-пуша
## Файлы (ожидаемо): ready_push_job.rb, ready_push_claim.rb (метод освобождения), send_push_notification_job.rb, application_job.rb, fcm_client.rb (только классификация сетевых ошибок), тесты ready_push_job / ready_push_claim
## Не ломать: ранний claim (C1), payload FcmClient, Broadcaster на ready, чтение ready_notified_at в OrderReadySmsLink :61 и OrderStatusPushNotifier :42, схема orders, код Wallet и APNs (см. COMPONENT_MAP: GuestOrderBroadcaster, FcmClient)
## Проверка: bundle exec ruby -Itest test/jobs/shop/ready_push_job_test.rb; test/services/shop/ready_push_claim_test.rb; test/services/shop/guest_order_broadcaster_test.rb; test/jobs/shop/order_ready_cascade_job_test.rb; bundle exec rubocop
## DoD: Subtask 4–4g, защитные тесты зелёные, E2E TASK_92 Subtask 16 по-прежнему обязателен, дубль схлопывается по tag на реальном Android (проверка в E2E Subtask 5 и 16)

## Патч 2: 2026-10-18

Основание: аудит L от 2026-10-18, факт order_status_push_notifier.rb:30-36,53-63,82-84; order_status_push_payload.rb:8-22; firebase_sw/show.js.erb:44-52,108-123; guest_order_cancellation_service.rb:42; barista/order_cancellation_service.rb:60; barista/order_status_update_service.rb:41; ТЗ #38 (:25, tag «чтобы пуши заменяли друг друга»); решение владельца D1 от 2026-10-18

### Расхождение

Subtask 5: было — notifications одного заказа используют tag order-#{order.id} и не создают бесконтрольный набор дублей;
по факту — матрица enrich-полей (tag, actions, progress) покрывает только accepted, preparing, ready (order_status_push_payload.rb:8-22); для cancelled payload состоит из order_id, tenant_id, status, order_number и уходит без tag, actions и progress (order_status_push_notifier.rb:53-58, :82-84; ветка наследована от B1.1 868e73f7 и 31aa3651, обоснования нет); service worker ставит tag только если он есть (show.js.erb:50);
cancelled на Android показывается отдельным уведомлением и не заменяет предыдущее: в шторке остаётся старое уведомление с «Отменить» или «Чат/Чаевые»;
push на cancelled уходит при отмене гостем (из pending_payment и accepted), отмене баристой и переводе баристой в cancelled (guest_order_cancellation_service.rb:42, barista/order_cancellation_service.rb:60, barista/order_status_update_service.rb:41); при отмене гостем заголовок и текст совпадают «Заказ отменён» (order_status_push_notifier.rb:17,111-114; payment_failure_journal.rb:105-111,134-136);
тестов на push при cancelled нет.

### Исправленный сценарий

- [ ] Subtask 5b (patch v2): Given гость подписан на push, And заказ переходит в cancelled из accepted, preparing или ready (отмена гостем, баристой или переводом статуса баристой), When уведомитель формирует push, Then уходит push с tag order-#{order.id} и status без actions и progress, And он заменяет предыдущее уведомление заказа в шторке Android.
- [ ] Subtask 5c (patch v2): Given заказ переходит в cancelled из pending_payment, Then push не отправляется (предыдущего уведомления нет, заменять нечего).
- [ ] Subtask 5d (patch v2): Given отмена гостем, Then текст push отличается от заголовка: «Вы отменили заказ». Given отмена исполнителем, Then текст как сейчас: «Заказ отменён исполнителем. Средства будут возвращены в течение 3 рабочих дней».
- [ ] Subtask 5e (patch v2): Given pending_payment, Then поведение не меняется: в рабочих сценариях push на этот статус не уходит; rake-смоук shop:push:smoke остаётся (lib/tasks/shop_push.rake:14,28-29).
- [ ] Subtask 5f (patch v2): Тесты OrderStatusPushNotifier и OrderStatusPushPayload: cancelled из accepted, preparing, ready (tag, нет actions и progress, текст по инициатору); cancelled из pending_payment (push нет); тест service worker: уведомление cancelled с tag заменяет предыдущее (sw_notification_actions_test.mjs).

### Не трогать

См. COMPONENT_MAP.md строки FcmClient (data-only, без top-level notification), GuestOrderBroadcaster (каскад ставится независимо), OrderStatusPushNotifier.
Путь ready (ReadyPushJob, ready_notified_at) в этот патч не входит: Патч 1 TASK_92. Каскад и SMS, логика отмены, Barista::OrdersController и OrderStatusUpdateService (запрет TASK_92) не затрагиваются: меняется только формирование push.
Известные ограничения (не входят в патч): системная отмена ready-заказов при закрытии смены push не отправляет (manager/shift_close_service.rb:84-112); при открытой вкладке push, вероятно, не показывается, статус показывает WebSocket (по поведению Firebase SDK, не проверено).
Тесты, закрепляющие push на cancelled без tag, не удалять, а актуализировать (по аудиту таких тестов нет).

### Scope

Разрешено: формирование push для cancelled (tag, без actions и progress, текст по инициатору); пропуск push при переходе из pending_payment; тесты.
Запрещено: payload FcmClient, ready-путь, каскад, логика отмены, логика статусов Barista, ActionCable, доставка accepted и preparing, тексты окна предварительного экрана (TASK-PUSH-PREPROMPT).

## SBR: Патч 2 TASK_92 (Д5) — push при отмене
## Файлы (ожидаемо): order_status_push_notifier.rb, order_status_push_payload.rb, тесты order_status_push_notifier_test.rb, order_status_push_payload_test.rb, sw_notification_actions_test.mjs
## Не ломать: payload FcmClient, ready-путь (ReadyPushJob, ready_notified_at), каскад и SMS, логика отмены, Barista::OrdersController и OrderStatusUpdateService, доставка accepted и preparing (см. COMPONENT_MAP: FcmClient, GuestOrderBroadcaster, OrderStatusPushNotifier)
## Проверка: bundle exec ruby -Itest test/services/shop/order_status_push_notifier_test.rb; test/services/shop/order_status_push_payload_test.rb; test/services/shop/guest_order_broadcaster_test.rb; test/jobs/shop/order_ready_cascade_job_test.rb; npm test -- --run (sw_notification_actions); bundle exec rubocop
## DoD: Subtask 5b–5f; на Android уведомление отмены заменяет предыдущее (проверка в E2E TASK_92); тесты зелёные
