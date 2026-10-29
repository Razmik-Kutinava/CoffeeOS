# TASK_109: Определение окружения для push и единый вход на двух экранах заказа

**ID заказчика:** TASK_109 · **CBR:** #109 · **Дата intake:** 2026-10-29 (шаг 9 [очереди Push + SMS](../PUSH_SMS_QUEUE.md))  
**Источник:** Google Doc Spec (одна вкладка)  
**Артефакты:** нет (заказчик не прислал)  
**Google Doc:** https://docs.google.com/document/d/13KxN_U7XjGfdsFojHFoBnZUBrIWH843XdB4OQ14kDr0/edit  
**Статус:** intake 2026-10-29 · без миграции (по тексту документа: backend не затронут)

---

## Текст задачи (дословно) — Google Doc Spec

# TASK_109: Определение окружения для push и единый вход на двух экранах заказа
**Тип:** новая задача (сценарий нигде не зафиксирован)
**Зависит от:** TASK-PUSH-ENV-SNAPSHOT (pushEnvironment.js), Патч 2 TASK_90, TASK-PUSH-DIAG-GATE, TASK-PUSH-STORAGE-SAFE
Бизнес-цель: гость видит кнопку уведомлений только там, где она может сработать; на панели заказа и на экране заказа push включается одинаково; подписанному гостю кнопка не показывается.

## 1. Карта интеграций — затронуто / нет
Затронуто: клиентская логика показа и запуска push на панели заказа и экране заказа.
Не затронуто: backend, /shop/api/push/register, VAPID/FCM, Service Worker, Wallet (выбор Wallet или push на iOS остаётся как есть, установка и подсказки для iPhone — TASK-IOS-PUSH-PATH), каскад, статусная модель, оффер подписки.

## 2. Карта компонентов
- pushEnvironment.js (создаётся в TASK-PUSH-ENV-SNAPSHOT): поверх собранных флагов добавляется классификация (в том же модуле или соседнем): класс A–E, pushPossible.
- orderStatusCtaMachine.js (:43-44 выбор типа уведомления, :52-78 правила, лимит 2): новый необязательный параметр showPushCta (по умолчанию true). При false CTA вида push не добавляется, освободившееся место другим CTA не заполняется, ветку подписки параметр не включает. Wallet-CTA параметром не затрагивается.
- OrderStatus.svelte (:57-69 набор CTA; :100-127 enablePushNotifications → registerShopPush напрямую; :179-182 и :290-305 кнопка и баннер; :240-243 автовызов при granted): переходит на общий вход subscribeOrderPush; передаёт showPushCta; баннер «Разрешить уведомления» скрывается при pushPossible = false и после подписки.
- orderStatusNotifyActions.js (subscribeOrderPush, resolveNotifyPrimaryInit): общий вход, сигнатуры не меняются.
- ActiveOrdersAccordion.svelte / OrderActionButtons.svelte: передают showPushCta (по pushPossible), логика hasPushSubscription и ветка подписки не меняются.
Общий файл с: TASK_90 (Патч 2), TASK_92 (OrderStatus), TASK_96 (баннер оффера на OrderStatus), #77 (ветка подписки в машине), TASK-PUSH-DIAG-GATE, TASK-PUSH-STORAGE-SAFE, TASK-IOS-PUSH-PATH. Граница: только показ push-CTA и вход в push; остальные CTA, статусная модель, прогресс, Wallet, ветка подписки не меняются.
Владение: эта задача является «отдельной задачей» из запретов TASK_90 на orderStatusCtaMachine.js и OrderStatus.svelte, только в части push-входа и показа push-CTA. Запрет в TASK_90 указывает неверный путь (app/frontend/components/OrderStatus.svelte): файл лежит в app/frontend/routes/. После Review фиксируется в COMPONENT_MAP.
Новый компонент: нет.

## 3. Текущее поведение (факт, не требование)
Два входа: панель идёт через subscribeOrderPush (denied → настройки, блок восстановления), экран заказа вызывает registerShopPush напрямую без восстановления (OrderStatus.svelte:8,110; вход появился 2026-06-10 в 6ae7d0dc, общий вход для панели 2026-08-03 в 310836b9, экран заказа на него не переводился; обоснования нет). OrderStatus не передаёт hasPushSubscription (:57-69), поэтому в preparing и ready push-кнопка там показывается всегда, а после подписки скрывается только баннер (:291,306,402-428). Кнопка «Оформить подписку» на экране заказа из-за этого сейчас не появляется (orderStatusCtaMachine.js:67-70); панель заказа статус ready не показывает. Автовызов при granted на открытии экрана (:240-243). Push-сценарий экрана заказа тестами не покрыт (поиск по test/ пуст, есть только проверка импорта машины и openSupportChat: order_status_cta_machine_test.mjs:270-276, order_status_push_subscribe_test.mjs:191-200). Выбор «wallet или push» по getDeviceOS и мета-тегу (orderStatusCtaMachine.js:43-44, deviceDetect.js:28-32, shopWalletConfig.js:2-5). Правила CTA: pending_payment — только «Отменить»; accepted — отмена, затем уведомление; preparing и ready — чат, затем уведомление; при подписке второй CTA «Оформить подписку» (только ready, оффер включён); лимит 2. Проверок standalone и встроенных браузеров нет; без Notification гость видит только диагностику.
Закрывает расхождение Subtask 1 TASK_90 на полноэкранном экране заказа: recovery там отсутствует (OrderStatus.svelte:113-115, 291-303). Запрет TASK_90 на OrderStatus.svelte и orderStatusCtaMachine.js снимается этой задачей в части push-входа. Авто-подписка после возврата из настроек (Патч 1 TASK_90, Subtask 7) в эту задачу не входит.

## 4. Scope
Разрешено: классификация окружения; параметр showPushCta; показ push-CTA и баннера по pushPossible и подписке; единый вход на экране заказа; тесты.
Запрещено: выбор Wallet или push на iOS; ветка подписки в машине и оффер (#77, TASK_96); логика и тексты recovery (Патч 2 TASK_90), кроме подключения существующего блока; диагностика (TASK-PUSH-DIAG-GATE); защита storage (TASK-PUSH-STORAGE-SAFE), кроме использования; предварительный экран и переспрос (TASK-PUSH-PREPROMPT); плашка установки и подсказки для iPhone (TASK-IOS-PUSH-PATH); другие CTA (отмена, чат, чаевые); статусная модель, прогресс; backend; Service Worker; регистрация токена; решение о статусах для push.
Решения владельца: Subtask 2 — вариант А для классов C, D, E (в окружениях без push кнопки нет и подсказки не показываются; установку и подсказки даёт TASK-IOS-PUSH-PATH). Subtask 7 — вариант А (оффер на экране заказа только баннером); решение по кнопке «Оформить подписку» принимается в потоке воронки подписки (Патч к #77) и в этой задаче не рассматривается.

## 5. Gherkin
- [ ] Subtask 0 (TDD, до правки): Given текущее поведение push-сценария экрана заказа (кнопка, баннер, автоподписка при granted, ошибка, denied), When пишутся тесты, Then они фиксируют текущее поведение и проходят на неизменённом коде.
- [ ] Subtask 1: Given флаги окружения (TASK-PUSH-ENV-SNAPSHOT), When вычисляется класс, Then pushPossible = есть Notification, PushManager и serviceWorker. Классы: A — установленное PWA с поддержкой push; B — вкладка браузера с поддержкой push; C — iPhone вне главного экрана без поддержки; D — встроенный браузер на iPhone без поддержки; E — встроенный браузер на Android без поддержки. Метка встроенного браузера уточняет класс при отсутствии возможностей и сама кнопку не скрывает.
- [ ] Subtask 2 (решено, вариант А): Given pushPossible = false (классы C, D, E) и тип уведомления push (не Wallet), When показывается панель заказа или экран заказа, Then push-CTA и баннер «Разрешить уведомления» не показываются, And другой CTA на их место не добавляется, And подсказки не показываются. Установку на главный экран и подсказки даёт TASK-IOS-PUSH-PATH. Выкладывается до отключения Wallet на prod (WALLET_FORCE_UNAVAILABLE).
- [ ] Subtask 3: Given pushPossible = true (классы A, B), Then push-CTA и поведение как сейчас.
- [ ] Subtask 4: Given iPhone с доступным Wallet, Then выбор «wallet или push» в коде не меняется; Wallet скрывается настройкой на Fly только после выкладки Subtask 2.
- [ ] Subtask 5: Given гость нажимает push-CTA на экране заказа, Then используется тот же вход, что в панели; при permission denied показывается существующий блок восстановления с «Открыть настройки» и инструкцией, без кнопки «Смотреть готовность» (гость уже на экране заказа). Блок переиспользуется без изменения его поведения в панели; способ (общий компонент или разметка на экране) выбирается при сборке, тесты панели не меняются. Общий вход вызывается синхронно из обработчика клика: до requestPermission нет await, setTimeout и динамического импорта (инвариант TASK_99).
- [ ] Subtask 6: Given гость подписан на push (флаг и permission granted), When открывает экран заказа в preparing или ready, Then push-кнопка и баннер не показываются (showPushCta = false), And кнопка «Оформить подписку» не появляется.
- [ ] Subtask 7 (решено, вариант А): Given экран заказа в ready, Then оффер подписки показывает только баннер (TASK_96); кнопка «Оформить подписку» не появляется, ветка подписки в машине и условия баннера не изменены. Решение по кнопке принимается в потоке воронки (Патч к #77) и в этой задаче не рассматривается.
- [ ] Subtask 8: Given автовызов при granted на открытии экрана, Then без изменений и без видимых сообщений.
- [ ] Subtask 9: Given регрессия, Then остальные CTA, статусная модель, прогресс и тесты orderStatusCtaMachine, order_status_push_subscribe, active_orders_accordion, order_action_buttons не изменены.

## 6. TDD-проверка: команды
npm test -- --run (orderStatusCtaMachine, order_action_buttons, order_status_push_subscribe, active_orders_accordion, новые тесты классификации и OrderStatus); npm run lint; npm run typecheck.
Ручная проверка: Android Chrome PWA (A) и вкладка (B); iPhone Safari-вкладка (C); Telegram и Instagram на Android и iPhone (D, E): кнопки нет; подписанный гость на экране заказа кнопки не видит.
Документ готов к билду. Порядок сборки: после TASK-PUSH-ENV-SNAPSHOT, Патча 2 TASK_90, TASK-PUSH-DIAG-GATE и TASK-PUSH-STORAGE-SAFE.
## SBR: TASK-PUSH-ENV-GATE (после Д9, Д2, Д3, Д10)
## Файлы (ожидаемо): pushEnvironment.js (классификация), orderStatusCtaMachine.js (параметр showPushCta), OrderStatus.svelte, ActiveOrdersAccordion.svelte, OrderActionButtons.svelte, тесты (новый тест push-сценария экрана заказа)
## Не ломать: ветка подписки и оффер (#77, TASK_96), выбор wallet или push на iOS, recovery TASK_90, статусная модель и прогресс, другие CTA, лимит 2, инвариант TASK_99; Wallet скрывается настройкой на Fly только после выкладки этой задачи (см. COMPONENT_MAP: OrderStatus, orderStatusCtaMachine, OrderActionButtons)
## Проверка: npm test -- --run (orderStatusCtaMachine, order_action_buttons, order_status_push_subscribe, active_orders_accordion, новые); npm run lint; npm run typecheck; ручной прогон классов A–E
## DoD: Subtask 0–9, тесты экрана заказа написаны до правки, подписанный гость не видит push-кнопку на экране заказа

---

## Заметки агента

- Метки в тексте → ID заказчика (по таблице меток [очереди](../PUSH_SMS_QUEUE.md)): TASK-PUSH-ENV-GATE = эта задача (TASK_109, Д7a); TASK-PUSH-ENV-SNAPSHOT = TASK_112 (Д9, шаг 1); TASK-PUSH-DIAG-GATE = TASK_108 (Д3, шаг 7); TASK-PUSH-STORAGE-SAFE = TASK_113 (Д10, шаг 8); TASK-PUSH-PREPROMPT = TASK_110 (Д7b, шаг 10); TASK-IOS-PUSH-PATH = TASK_111 (Д8, шаг 11); Д2 = Патч 2 TASK_90 (шаг 6).
- Сверка шапки с очередью (п. 4 «Как работать»): «Зависит от» / «Порядок сборки» (TASK_112, Патч 2 TASK_90, TASK_108, TASK_113) = строка 9 очереди «Зависит от: 1, 6, 7, 8» — все `done`; «Документ готов к билду» = статус `todo`; условие выкладки Subtask 2 «до отключения Wallet на prod (`WALLET_FORCE_UNAVAILABLE`)» = строка 🚀 3 «После: можно выставить `WALLET_FORCE_UNAVAILABLE`». Расхождений нет.
- `pushEnvironment.js` из шага 1 есть: `app/frontend/lib/pushEnvironment.js` — классификация A–E и `pushPossible` строятся поверх него.
- Номера строк в разделах 2–3 (`OrderStatus.svelte` `:8`, `:57-69`, `:100-127`, `:110`, `:113-115`, `:179-182`, `:240-243`, `:290-305`, `:291`, `:306`, `:402-428`; `orderStatusCtaMachine.js` `:43-44`, `:52-78`, `:67-70`; `deviceDetect.js:28-32`; `shopWalletConfig.js:2-5`; тесты `order_status_cta_machine_test.mjs:270-276`, `order_status_push_subscribe_test.mjs:191-200`) написаны до шагов 6–8: шаг 7 менял `OrderStatus.svelte` (жест диагностики, тихий автовызов), шаги 6–8 — `orderStatusNotifyActions.js` и тесты push — сдвиг ожидаем, сверяем на `/spec`.
- Утверждение «без Notification гость видит только диагностику» написано до шага 7: после него диагностика видна только при флаге — на `/spec` проверить фактическое поведение без `Notification` и без флага.
- Зона карты (`OrderStatus`, `ActiveOrdersAccordion`, `OrderActionButtons`, `orderStatusCtaMachine`, `orderStatusNotifyActions.js`) → на `/spec` читать `COMPONENT_MAP.md`; после Review — фиксация владения (раздел 2 «Владение»).
- Прецедент шагов 6–8: команд `npm test -- --run` / `npm run lint` / `npm run typecheck` в проекте нет — JS-тесты `node --test test/javascript/*.mjs`, сборка `npx vite build`.
- `/spec` 2026-10-29 (подробно — [todo](../../../../session/todo.md)): поведение кода = «Текущее поведение». Новые номера строк в `OrderStatus.svelte`: `:8` (без сдвига), набор CTA `:67-79`, `enablePushNotifications` `:110-143` (вызов `registerShopPush` `:124`, ветка `denied` `:127-128`), клик push `:204-207`, автовызов `:265-268`, баннер `:321-341` (условие `:321`, «Уведомления включены» `:336`), ряд CTA `:432-458`. `orderStatusCtaMachine.js`, `deviceDetect.js`, `shopWalletConfig.js`, `order_status_cta_machine_test.mjs:270-276` — без сдвига; `order_status_push_subscribe_test.mjs:191-200` → `:194-203`.
- Уточнения к «Текущему поведению»: после шагов 6–7 у экрана есть проверки по исходнику (`push_diag_flag_test.mjs:320-352`, `order_status_push_subscribe_test.mjs:585-590`), поведенческих тестов нет; без `Notification` и без флага гость после нажатия видит «Не удалось включить уведомления. Попробуйте ещё раз» (шаг 7), а не диагностику.
- Решения владельца на `/spec` 2026-10-29: закрытый без выбора диалог на экране заказа — как в панели («Уведомления не включены», кнопка остаётся); окружения вне классов A–E без push — класс не присваивается, кнопка и баннер скрываются по `pushPossible = false`.
- Охранный тест экрана `order_status_push_subscribe_test.mjs:585-590` добавлен шагом 6 после написания документа; Subtask 9 («тесты order_status_push_subscribe не изменены») относим к тестам панели и общего входа — этот тест переписывается явно на RED с сохранением смысла.
