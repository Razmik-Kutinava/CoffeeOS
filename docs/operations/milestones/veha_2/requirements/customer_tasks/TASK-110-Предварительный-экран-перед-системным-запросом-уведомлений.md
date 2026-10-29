# TASK_110: Предварительный экран перед системным запросом уведомлений

**ID заказчика:** TASK_110 · **CBR:** #110 · **Дата intake:** 2026-10-29 (шаг 10 [очереди Push + SMS](../PUSH_SMS_QUEUE.md))  
**Источник:** Google Doc Spec (одна вкладка)  
**Артефакты:** нет (заказчик не прислал)  
**Google Doc:** https://docs.google.com/document/d/1egmnNNtibkrI-11u1X4o9AdS_TyeQ2zx42xyXLacaho/edit  
**Статус:** intake 2026-10-29 · реверс решения #37 шаг 5 · миграция — вероятно (Subtask 12, см. «Заметки агента»)

---

## Текст задачи (дословно) — Google Doc Spec

# TASK_110: Предварительный экран перед системным запросом уведомлений
**Тип:** новая задача (сценарий нигде не зафиксирован); реверс решения #37, шаг 5 («клик сразу вызывает Notification.requestPermission(), промежуточного шага нет»; docs/operations/milestones/veha_2/requirements/customer_tasks/Адаптивный виджет статуса заказа….md:52-57)
**Расширяет:** TASK_90 (recovery после denied), TASK_99 (requestPermission первым async-вызовом)
**Зависит от:** TASK-PUSH-ENV-SNAPSHOT (event_kind), Патч 2 TASK_90 (default ≠ denied), TASK-PUSH-DIAG-GATE, TASK-PUSH-STORAGE-SAFE, TASK-PUSH-ENV-GATE (showPushCta, общий вход на двух экранах)
Бизнес-цель: гость сначала видит понятное предложение «Уведомим, когда заказ будет готов» и сам решает, включать ли уведомления; системный запрос показывается только после «Включить»; отказ «Не сейчас» не сжигает единственную попытку системного запроса и запоминается.

## 1. Карта интеграций — затронуто / нет
Затронуто: клиентский показ предложения на панели заказа и экране заказа; состояние «Не сейчас» на устройстве; события воронки согласия (таблица TASK-PUSH-ENV-SNAPSHOT).
Не затронуто: backend push, /shop/api/push/register, VAPID/FCM, Service Worker, Wallet, каскад, статусная модель, оффер подписки.

## 2. Карта компонентов
- Новый компонент: PushPrePrompt.svelte (встроенный блок: заголовок, пояснение, «Включить», «Не сейчас»). Не модальное окно, без overlay и z-index над шторкой.
- Новый модуль lib/pushPrePrompt.js: тексты константами (конвенция проекта: export-константы в lib/*.js), чистые функции решения «показывать ли автоматически» и работы с состоянием (счётчик, id последнего закрытого заказа), доступ к storage с try/catch.
- ActiveOrdersAccordion.svelte (:236-241 onAction; :268-286 путь push; :339-371 блок recovery; :57-62 локальный стейт): нажатие push-CTA открывает блок вместо прямого вызова subscribeOrderPush; блок занимает место между recovery и тостом.
- OrderStatus.svelte (:100-110 enablePushNotifications; :291-305 баннер «Разрешить уведомления»; :413 onCtaClick): баннер заменяется тем же блоком; CTA ведёт к нему.
- orderStatusCtaMachine.js (:43-44, :65-75): на статусе ready CTA вида push не добавляется; wallet-CTA не меняется.
- orderStatusNotifyActions.js (subscribeOrderPush :215-228) и firebasePush.js (:64-98 registerShopPush): не меняются; «Включить» вызывает общий вход синхронно.
Общий файл с: TASK_90 (Патч 1 и 2), TASK_92 (OrderStatus), TASK-PUSH-ENV-GATE (владеет push-входом и параметром showPushCta), TASK-PUSH-DIAG-GATE, TASK-PUSH-STORAGE-SAFE, TASK_99, #83/#84 (блоки чека). Граница: только показ предложения, его состояние и правило «на ready push-CTA нет»; recovery, регистрация токена, чек, прогресс, статусная модель, Wallet не меняются.
Высоты: STATUS_IN_SHEET_EXTRA_VH и cartSheetThresholds не меняются (shopWebViewLayout, CartSheet); блок компактный и при нехватке высоты прокручивается внутри списка панели (.oss__list, OrderStatusSheet.svelte:337-342).
Состояние: localStorage, ключ вида coffeeos_shop_push_preprompt_v1 (JSON: число закрытий и id последнего закрытого заказа).

## 3. Текущее поведение (факт, не требование)
Путь от нажатия push-CTA до requestPermission синхронный в обеих точках: панель OrderActionButtons.svelte:74 → ActiveOrdersAccordion.svelte:236-276 → orderStatusNotifyActions.js:214-228 → firebasePush.js:64-98; экран заказа OrderStatus.svelte:298 или :413 → :100-110 → firebasePush.js:64-98. Любой await, setTimeout или динамический импорт до requestPermission теряет жест пользователя, это закреплено в TASK_99 (firebasePush.js:57-59) и тестами (order_status_push_subscribe_test.mjs:399-409, :483-495). Промежуточного экрана в истории репо не было и не удалялся. На экране заказа уже есть встроенный баннер «Получайте статус заказа в шторке уведомлений» с кнопкой «Разрешить уведомления», он вызывает ту же функцию, что CTA, и показывается при firebaseClientConfigured() (OrderStatus.svelte:291-305). Закрытый системный диалог (permission === "default") обрабатывается как denied и показывает recovery «Уведомления запрещены» (firebasePush.js:104-106, ActiveOrdersAccordion.svelte:278-282); это исправляет Патч 2 TASK_90. Отказ и счётчики показа push нигде не хранятся (оффер подписки хранится на сервере, subscription_offer_states, db/schema.rb:1236-1246). Стейт панели локален для каждой строки заказа (ActiveOrdersAccordion.svelte:57-62, OrderStatusSheet.svelte:258-266). Панель: max-height min(22vh, 8.5rem), на 390×844 около 136px (OrderStatusSheet.svelte:335, peek_only_2026-10-01/MEASURE.md:7). В статусах preparing и ready гость без подписки видит второй CTA push (orderStatusCtaMachine.js:65-75); на ready панель статус не показывает (/orders/active отдаёт только accepted и preparing).

## 4. Scope
Разрешено: PushPrePrompt.svelte; pushPrePrompt.js; подключение блока на панели и экране заказа; правило «на ready push-CTA нет» в машине; состояние на устройстве; события; тесты; актуализация защитных тестов по Subtask 14.
Запрещено: модальное окно и любой overlay; recovery после denied и resumePushAfterSettings (TASK_90), кроме подключения; регистрация токена, endpoint, VAPID, Service Worker; firebasePush.js и subscribeOrderPush (сигнатуры и порядок вызовов); диагностика (TASK-PUSH-DIAG-GATE); высоты и пороги шторки; чек и прогресс (#83/#84); Wallet; ветка подписки и оффер (#77, TASK_96); статусная модель; backend; задержки и динамические импорты перед requestPermission; сервер-хранение состояния.
Решения владельца 2026-10-18: предложение появляется само, когда гость впервые видит панель заказа, и по нажатию на 🔔; «Не сейчас» запоминается, на следующем заказе предложение появляется снова, не больше трёх раз; на статусе «Готов» кнопки уведомлений нет; текст: заголовок «Уведомим, когда заказ будет готов», пояснение «Пришлём уведомление, как только бариста его соберёт», кнопки «Включить» и «Не сейчас».
Решения владельца 2026-10-19: форма предложения — встроенная карточка (не всплывающее окно); текст подтверждён без изменений, хотя push по решению D1 идёт на accepted, preparing, ready.

## 5. Gherkin
- [ ] Subtask 0 (TDD, до правки): Given защитные тесты синхронного пути (order_status_push_subscribe_test.mjs:399-409, :483-495), When пишутся новые тесты, Then они пишутся первыми, защитные остаются зелёными до и после.
- [ ] Subtask 1 (автоматический показ): Given гость видит панель заказа с активным заказом в accepted, paid или preparing, And pushPossible = true, And permission === "default", And гость не подписан, And для этого заказа предложение ещё не закрывалось, And число закрытий меньше 3, When панель отображается, Then автоматически показывается блок предложения, не более одного блока на экран даже при нескольких заказах.
- [ ] Subtask 2 (по нажатию): Given push-CTA в панели или на экране заказа, When гость нажимает на CTA, Then показывается тот же блок; системный запрос напрямую не вызывается; блок открывается независимо от лимита и от закрытия на этом заказе.
- [ ] Subtask 3 («Включить»): Given блок показан, When гость нажимает «Включить», Then в том же обработчике клика синхронно вызывается общий вход subscribeOrderPush (до requestPermission нет await, setTimeout, динамического импорта), And блок показывает состояние ожидания; granted: подписка как сейчас; denied: существующий блок recovery; default (гость закрыл системное окно): как «Не сейчас» (Subtask 4) с нейтральным сообщением «Уведомления не включены» (Патч 2 TASK_90).
- [ ] Subtask 4 («Не сейчас»): Given блок показан, When гость нажимает «Не сейчас», Then блок скрывается, системный запрос не вызывается, счётчик закрытий увеличивается, запоминается id заказа; на этом заказе блок автоматически больше не появляется (в том числе после перезагрузки страницы), на следующем заказе появится снова, пока счётчик меньше 3; CTA остаётся доступной.
- [ ] Subtask 5 (лимит): Given счётчик закрытий не меньше 3, Then автоматического показа нет, по нажатию на CTA блок открывается (Subtask 2). Значение 3 вынесено в константу.
- [ ] Subtask 6 (хранение): Given состояние хранится на устройстве, Then доступ к storage защищён (try/catch), недоступное хранилище не ломает рендер и не блокирует «Включить», состояние живёт в памяти страницы; допустимо, что без хранилища блок появится снова после перезагрузки.
- [ ] Subtask 7 (когда не показывать): Given permission === "granted" или "denied", или гость подписан, или pushPossible = false, или статус pending_payment, Then автоматического блока нет. Given статус ready, Then CTA вида push не добавляется (wallet-CTA не меняется).
- [ ] Subtask 8 (экран заказа): Given экран заказа в accepted, paid или preparing, Then существующий баннер «Получайте статус заказа… / Разрешить уведомления» заменяется тем же блоком, CTA ведёт к нему, автопоказ по правилам Subtask 1, автовызов при granted без изменений и без видимых сообщений.
- [ ] Subtask 9 (возврат из настроек): Given гость вернулся из настроек с granted (armed), Then блок не показывается, регистрация продолжается как в Патче 1 TASK_90 без повторного CTA.
- [ ] Subtask 10 (приоритет): Given одновременно recovery, блок и тост, Then приоритет: recovery, затем блок, затем тост; блок не показывается, пока виден recovery.
- [ ] Subtask 11 (интерфейс): Given блок встроен в панель или экран заказа, Then он не перекрывает клики по каталогу, не использует overlay, высоты панели и пороги шторки не меняются, при нехватке места прокручивается внутри списка панели, safe-area не нарушается. [приёмка на 390×844 и на узких экранах]
- [ ] Subtask 12 (события): Given события воронки согласия, Then в таблицу TASK-PUSH-ENV-SNAPSHOT пишутся event_kind: push_preprompt_shown, push_preprompt_accept, push_preprompt_later, push_permission_granted, push_permission_denied, push_permission_default; идентификатор гостя не пишется; белый список расширяется; ошибка отправки работу не ломает.
- [ ] Subtask 13 (тексты): Given тексты, Then они лежат константами в lib/pushPrePrompt.js, точные строки: «Уведомим, когда заказ будет готов», «Пришлём уведомление, как только бариста его соберёт», «Включить», «Не сейчас»; тесты сверяют строки.
- [ ] Subtask 14 (защитные тесты, реверс #37 шаг 5): Given тесты, закрепляющие прежний путь, Then не удаляются: order_status_push_subscribe_test.mjs:399-409 и :483-495 (синхронный вызов requestPermission) остаются зелёными; актуализируются: source-оракулы аккордеона (:146-157), проверка строки баннера (order_status_acceptance_cbr_test.rb:132-135), ready-случаи CTA-машины (order_status_cta_machine_test.mjs:134-160, :211-246); в GATES TASK_99 (G4) формулировка уточняется: системное окно появляется сразу после нажатия «Включить».
- [ ] Subtask 15: Given регрессия, Then recovery и resumePushAfterSettings, регистрация токена, чек, прогресс, остальные CTA и существующие тесты не изменены.

## 6. TDD-проверка: команды
npm test -- --run (order_status_push_subscribe, active_orders_accordion, orderStatusCtaMachine, order_action_buttons, новые тесты pushPrePrompt и компонента); npm run lint; npm run typecheck; bundle exec ruby -Itest test/integration/shop/order_status_acceptance_cbr_test.rb.
Ручная приёмка: Android Chrome PWA: блок сам на первом заказе, «Не сейчас», на втором заказе снова, на четвёртом сам не появляется, по 🔔 появляется; «Включить» → системное окно сразу; denied → recovery; iPhone с установленным приложением (GATES TASK_99, G4): «Включить» → системное окно сразу; панель 390×844: блок не перекрывает каталог.
Документ готов к билду. Порядок сборки: после TASK-PUSH-ENV-SNAPSHOT, Патча 2 TASK_90, TASK-PUSH-DIAG-GATE, TASK-PUSH-STORAGE-SAFE и TASK-PUSH-ENV-GATE.
## SBR: TASK-PUSH-PREPROMPT (после Д9, Д2, Д3, Д10, Д7a)
## Файлы (ожидаемо): PushPrePrompt.svelte (новый), lib/pushPrePrompt.js (новый), ActiveOrdersAccordion.svelte, OrderStatus.svelte, orderStatusCtaMachine.js (правило ready), расширение белого списка event_kind, тесты (новые + актуализация по Subtask 14), GATES TASK_99 (строка)
## Не ломать: синхронный путь «Включить» → subscribeOrderPush → requestPermission (TASK_99), recovery и resumePushAfterSettings (TASK_90), высоты панели и пороги шторки, чек (#83/#84), Wallet-CTA, ветка подписки (#77, TASK_96), TASK-PUSH-ENV-GATE (showPushCta)
## Проверка: npm test -- --run; npm run lint; npm run typecheck; order_status_acceptance_cbr_test.rb; ручная приёмка Android и iPhone
## DoD: Subtask 0–15, защитные тесты синхронного пути зелёные, на iPhone системное окно появляется сразу после «Включить»

---

## Заметки агента

- Метки в тексте → ID заказчика (по таблице меток [очереди](../PUSH_SMS_QUEUE.md)): TASK-PUSH-PREPROMPT = эта задача (TASK_110, Д7b); TASK-PUSH-ENV-SNAPSHOT = TASK_112 (Д9, шаг 1); Д2 = Патч 2 TASK_90 (шаг 6); TASK-PUSH-DIAG-GATE = TASK_108 (Д3, шаг 7); TASK-PUSH-STORAGE-SAFE = TASK_113 (Д10, шаг 8); TASK-PUSH-ENV-GATE = TASK_109 (Д7a, шаг 9).
- Сверка шапки с очередью (п. 4 «Как работать»): «Зависит от» / «Порядок сборки» (TASK_112, Патч 2 TASK_90, TASK_108, TASK_113, TASK_109) = строка 10 очереди «Зависит от: 1, 6, 7, 8, 9» — все `done` (шаги 6–9 выкачены на Fly v520/v522); «Документ готов к билду» = статус `todo`; «реверс решения #37 шаг 5» = пометка «реверс» в строке очереди. Расхождений нет.
- Реверс (п. 6 «Как работать»): исходное решение — [Адаптивный виджет статуса заказа…](Адаптивный%20виджет%20статуса%20заказа%20Детекция%20ОС%20и%20подписка%20на%20уведомления.md) `:52-57` (файл на месте). Защитные тесты прежнего пути перечислены в Subtask 14 — на RED переписываются явно по `docs/operations/dev/TASK_PATCH.md`; тесты синхронного вызова `requestPermission` (TASK_99) не трогаем.
- **Subtask 12 → вероятно миграция.** Белый список `event_kind` сейчас в трёх местах: `ShopEnvironmentEvent::EVENT_KINDS` (`app/models/shop_environment_event.rb:6`), `Shop::EnvironmentEventRecorder` (`app/services/shop/environment_event_recorder.rb:12`) и CHECK `chk_shop_environment_events_event_kind` в базе (`db/schema.rb:1197`, миграция `20261028120000`). Расширить список без миграции нельзя, а в разделах 1 и 4 backend помечен как «не затронуто / запрещено» (хотя в «Разрешено» и «Файлы» есть «события» и «расширение белого списка event_kind»). На `/spec` — решение владельца: миграция CHECK + модель + сервис (Migration Gate, `coffeeos-dev-gates.mdc`) или иной способ. Длина самого длинного вида `push_permission_default` — 23 символа при `limit: 32`, колонку менять не нужно.
- Номера строк в разделах 2–3 написаны до шагов 6–9: шаг 6 закрыл `default` ≠ `denied` (абзац «Закрытый системный диалог… обрабатывается как denied» устарел — теперь «Уведомления не включены», без recovery); шаг 9 перевёл экран заказа на общий вход `subscribeOrderPush`, добавил блок восстановления на экран и скрытие push-CTA/баннера по `pushPossible` и подписке (путь «экран заказа OrderStatus.svelte:298 или :413 → :100-110 → firebasePush.js» устарел). Сверка файл:строка — на `/spec`, новые номера сюда.
- Зона карты (`ActiveOrdersAccordion`, `OrderStatus`, `orderStatusCtaMachine`, `OrderActionButtons`, `OrderStatusSheet`) → на `/spec` читать `COMPONENT_MAP.md`.
- Прецедент шагов 6–9: команд `npm test -- --run` / `npm run lint` / `npm run typecheck` в проекте нет — JS-тесты `node --test test/javascript/*.mjs`, сборка `npx vite build`.
