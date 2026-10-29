# TASK_111: Путь iPhone к уведомлениям: плашка установки на главный экран

**ID заказчика:** TASK_111 · **CBR:** #111 · **Дата intake:** 2026-10-29 (шаг 11 [очереди Push + SMS](../PUSH_SMS_QUEUE.md))  
**Источник:** Google Doc Spec (одна вкладка)  
**Артефакты:** нет (заказчик не прислал)  
**Google Doc:** https://docs.google.com/document/d/15pMZBaV5JeHDv_0sgzty7n64Mapc_I2dicZEG1agru8/edit  
**Статус:** intake 2026-10-29 · реверс «Wallet на паузе» 22.09 · миграция — вероятно (Subtask 6, см. «Заметки агента»)

---

## Текст задачи (дословно) — Google Doc Spec

# TASK_111: Путь iPhone к уведомлениям: плашка установки на главный экран
**Тип:** новая задача (сценарий нигде не зафиксирован); реверс решения «Wallet на паузе» от 22.09: Wallet для iPhone не используется
**Расширяет:** docs/operations/milestones/veha_2/requirements/customer_tasks/B1_4_pwa_shop.md (PWA, плашка установки). В B1.4 нет сценариев Given/When/Then, про плашку там зафиксировано только «Install banner / beforeinstallprompt [x]» (:186) и долг «A/B тексты» (:166), поэтому патч к B1.4 не нужен, Android-подзадачи входят в эту задачу.
**Зависит от:** TASK-PUSH-ENV-SNAPSHOT (pushEnvironment.js, event_kind), TASK-PUSH-ENV-GATE (Subtask 2)
Бизнес-цель: гость на iPhone видит ту же плашку установки, что гость на Android, понятно устанавливает витрину на главный экран и после установки получает уведомления; плашка не пропадает навсегда после закрытия, пока приложение не установлено; установка считается и видна в Metabase; пока гость не установил, о готовности заказа сообщает SMS.

## 1. Карта интеграций — затронуто / нет
Затронуто: клиентская плашка и инструкция установки; события воронки (таблица TASK-PUSH-ENV-SNAPSHOT); отметка pwa_installed_at через /pwa_install; ответ GET /shop/api/profile (булево pwa_installed); тексты документов про Wallet.
Не затронуто: backend push, VAPID, FCM, Service Worker, каскад, оплата, авторизация, /session/refresh, код Wallet.

## 2. Карта компонентов
- ShopPwaBanner.svelte (:69-74 показ по installable и сети; :77-89 position fixed, top 3.25rem, z-index 40; смонтирован в корне App.svelte:154; профиль не читает, импорты :1-6): расширяется вариантом для iPhone в том же положении, крестиком закрытия, памятью закрытия и проверкой признака установки.
- shopPwa.js (:9-15 install, :18-26 reportPwaInstalled, :31-35 beforeinstallprompt, :37-40 appinstalled): определение первого запуска в режиме standalone, отправка отметки установки.
- subscriptionOffer.js (:49-55 loadOfferProfile): общий загрузчик профиля, плашка использует его, отдельный запрос профиля не добавляется; не более одного запроса профиля плашкой за сессию и только там, где плашка иначе была бы показана.
- profile_controller.rb (:70-90 profile_json): добавляется булево pwa_installed (pwa_installed_at.present?), дата не отдаётся.
- pushEnvironment.js (TASK-PUSH-ENV-SNAPSHOT): семейство ОС, standalone, метка встроенного браузера.
- Новый компонент: да — шторка с инструкцией (рабочее имя IosInstallSheet.svelte).
- Сервер: /pwa_install без изменений (pwa_installs_controller.rb:8-12, mobile_customer.rb:41-45, идемпотентно); в таблице TASK-PUSH-ENV-SNAPSHOT расширяется белый список event_kind.
- Документы: APPLE_WALLET_ORDER_PASS.md, обещание «Wallet для iOS» в каскаде.
Общие файлы: App.svelte (TASK-PUSH-ENV-SNAPSHOT), shopPwa.js (#77, B1.4; строки в COMPONENT_MAP нет), profile_controller.rb и subscriptionOffer.js (воронка подписки), orderStatusNotifyActions.js (тексты recovery, Subtask 13). Граница: application.js не трогаем; логика beforeinstallprompt и appinstalled не меняется, кроме Subtask 7 и 10; поля и условия оффера в профиле не меняются.
Wallet скрывается настройкой на Fly (WALLET_FORCE_UNAVAILABLE), код Wallet не меняется.

## 3. Текущее поведение (факт, не требование)
Плашка показывается только по beforeinstallprompt (shopPwa.js:31-35); Safari на iPhone его не присылает (поведение браузера), плашки на iPhone нет, явного исключения iOS в коде нет. Закрыть плашку нельзя, закрытие нигде не запоминается (ShopPwaBanner.svelte:8,69-74). После отказа в системном диалоге плашка остаётся, кнопка не работает (shopPwa.js:10,13, ShopPwaBanner.svelte:43-46). Отметка установки уходит только из appinstalled и только для вошедшего гостя, без повтора (shopPwa.js:18-26,37-40; pwa_installs_controller.rb:8-9). appinstalled на iPhone, по моим знаниям, не приходит, поэтому pwa_installed_at для iPhone не пишется. Профиль и session/refresh признак установки не отдают: profile_json содержит id, email, email_verified, receipt_email, phone, phone_verified, first_name, last_name, name, balance, points, discount_percent, orders_count, favorites_count, eligible_for_subscription_offer, should_show_banner, has_unread_offer_in_lk (profile_controller.rb:70-90); session/refresh возвращает refresh_token и profile из id, name, email, phone (session_refresh.rb:37-40,57-63). Клиент читает профиль для баннеров через loadOfferProfile (subscriptionOffer.js:49-55); subscriptionOfferCta.js делает собственный запрос профиля с кэшем (:24-46). Манифест: start_url /shop?tenant_id=<id>, scope /shop, display standalone, поля id нет (manifest.json.erb:5-7); есть apple-touch-icon и meta-теги iOS (shop.html.erb:6-8,12). Клиентских тестов плашки нет. Гостевая сессия: серверная cookie _coffeeos_session на 90 дней (session_store.rb:4-7); вход по телефону привязывает гостя, /orders/active показывает его заказы при ближайшем опросе, около 8 секунд (phone_verified_customer_linker.rb:21,43; orders_controller.rb:155-161; orderStatusSheet.js:23); исключение: заказ оформлен по email на другую запись (checkout_identity.rb:38-44). Recovery после отказа написан для Android и desktop: инструкция «откройте настройки сайта в браузере» (orderStatusNotifyActions.js:135-136, 181-187), для установленного iPhone-приложения она может быть неверной. Поведение приложения с иконки на iPhone (хранилище, запоминаемый адрес, переключатель «Открыть как веб-приложение») аудитом не проверено, приёмка на устройстве.

## 4. Scope
Разрешено: вариант плашки для iPhone; шторка с инструкцией; крестик и память закрытия (все платформы); определение «установлен»; поле pwa_installed в ответе профиля; события воронки; отметка установки при запуске с иконки; тесты; строки-уточнения в документах про Wallet; тексты recovery для iPhone после проверки на устройстве (Subtask 13).
Запрещено: код Wallet и APNs; backend push, VAPID, FCM, Service Worker; каскад; оплата; авторизация и /session/refresh; поля и условия оффера подписки в профиле; принудительный переход в другой браузер; блокирующие действия на boot; application.js; логика beforeinstallprompt и appinstalled сверх Subtask 7 и 10; хранение идентификатора гостя в событиях; отдача даты установки на клиент; новый отдельный запрос профиля помимо loadOfferProfile; нарушение инварианта TASK_99 (requestPermission первым async-вызовом).

## 5. Gherkin
- [ ] Subtask 0 (TDD, до правки): Given текущее поведение shopPwa.js и ShopPwaBanner на Android (показ по beforeinstallprompt, установка, appinstalled), When пишутся тесты, Then они фиксируют текущее поведение и проходят на неизменённом коде.
- [ ] Subtask 1: Given iPhone, не standalone, не встроенный браузер и приложение не установлено (Subtask 3b), When открыта витрина, Then сверху показывается плашка «Установить CoffeeOS на главный экран» в том же положении, что у Android, с кнопкой «Как установить» и крестиком.
- [ ] Subtask 2: Given нажата «Как установить», Then открывается инструкция: кнопка «Поделиться» → «На экран «Домой»» → открыть приложение с иконки; формулировки без привязки к версии iOS; закрывается жестом или кнопкой, оформлению заказа не мешает. [приёмка на Safari и других браузерах iPhone; проверить переключатель «Открыть как веб-приложение»]
- [ ] Subtask 3 (все платформы): Given плашка показана, When гость нажимает крестик, Then плашка скрыта до конца текущей сессии (вкладки) и показывается снова в следующей сессии, пока приложение не установлено. Память закрытия в sessionStorage, при недоступном хранилище на время жизни страницы. Интервал повторного показа вынесен в одну константу (по умолчанию следующая сессия).
- [ ] Subtask 3b (все платформы): Given определяется «приложение не установлено», Then плашка не показывается в режиме standalone; не показывается вошедшему гостю, у которого в профиле pwa_installed = true; показывается невошедшему гостю, гостю без отметки и при ошибке или отсутствии профиля. Профиль запрашивается через loadOfferProfile не более одного раза за сессию и только там, где плашка иначе была бы показана. Установка из Safari без входа не определяется, это допустимо.
- [ ] Subtask 3c (бэкенд): Given гость вошёл, When GET /shop/api/profile, Then ответ содержит pwa_installed (true, если pwa_installed_at задан, иначе false), дата не отдаётся; остальные поля, оффер и ответ для невошедшего гостя без изменений; /session/refresh не меняется. Тесты в test/integration/shop/api.
- [ ] Subtask 4: Given запуск с иконки (standalone), Then плашка не показывается.
- [ ] Subtask 5 [ОТЛОЖЕНО до данных TASK-PUSH-ENV-SNAPSHOT по доле встроенных браузеров на iPhone]: Given встроенный браузер на iPhone, Then плашка «Откройте в Safari, чтобы установить» без принудительного перехода. До этого плашка во встроенных браузерах не показывается.
- [ ] Subtask 6: Given события воронки, Then в таблицу TASK-PUSH-ENV-SNAPSHOT пишутся event_kind: install_banner_shown (раз за сессию), install_banner_tap, install_banner_dismiss, pwa_first_launch (первый запуск в standalone на этом устройстве; метка в localStorage, без хранилища раз за сессию); идентификатор гостя не пишется; белый список расширяется.
- [ ] Subtask 7 (все платформы): Given standalone, гость вошёл и отметка ещё не отправлялась, When приложение открыто, Then отправляется /pwa_install (идемпотентно, ошибка работу не ломает); на Android это дополняет appinstalled.
- [ ] Subtask 8: Given первый запуск с иконки без сессии, Then витрина работает как для нового гостя, вход по телефону возвращает данные, активный заказ появляется в панели при ближайшем опросе (около 8 секунд). [приёмка на iPhone]
- [ ] Subtask 9: Given установленное приложение, Then открывается та же точка. [приёмка на iPhone: какой адрес запоминает iOS]
- [ ] Subtask 10 (Android): Given отказ в системном диалоге установки, Then плашка закрывается как по крестику (Subtask 3), кнопка не остаётся мёртвой. [приёмка: после отказа Chrome может сам не присылать beforeinstallprompt какое-то время, поведение зависит от браузера]
- [ ] Subtask 11: Given документы про Wallet, Then в APPLE_WALLET_ORDER_PASS.md и в тексте каскада добавлена датированная строка-уточнение «Wallet не используется как канал уведомлений для iPhone»; Wallet скрывается настройкой на Fly только после выкладки TASK-PUSH-ENV-GATE (Subtask 2).
- [ ] Subtask 12: Given регрессия, Then каталог, корзина, boot, оплата, оффер подписки и существующие тесты не изменены.
- [ ] Subtask 13 [ОТЛОЖЕНО до ручной проверки на iPhone]: Given установленное приложение на iPhone (standalone) и permission === "denied", When показывается блок восстановления, Then вместо инструкции для Android и desktop (orderStatusNotifyActions.js:135-136, 181-187) показывается инструкция для iPhone, проверенная на устройстве; кнопка «Открыть настройки» на iPhone не показывается, если не открывает нужный экран. [ОТКРЫТЫЙ ВОПРОС для приёмки: где включить после отказа: «Настройки → Уведомления → CoffeeOS» или только удалить и поставить заново; проверить на устройстве]

## 6. TDD-проверка: команды
npm test -- --run (новые тесты shopPwa и ShopPwaBanner, pushEnvironment); npm run lint; npm run typecheck; бэкенд-тесты профиля (pwa_installed) и /pwa_install; bundle exec rubocop.
Ручная приёмка: iPhone Safari — плашка видна, крестик, возврат плашки в новой сессии, инструкция, установка, запуск с иконки: событие в Metabase, та же точка, вход по телефону, активный заказ; вошедший гость с установкой плашку не видит; Android — крестик, отказ в системном окне, без регрессий. Ручная приёмка на iPhone закрывает G4 TASK_99 (системное окно по нажатию в установленном приложении).
Документ готов к билду, кроме Subtask 5 и 13 (отложены).
## SBR: TASK-IOS-PUSH-PATH (после TASK-PUSH-ENV-SNAPSHOT и TASK-PUSH-ENV-GATE)
## Файлы (ожидаемо): ShopPwaBanner.svelte, shopPwa.js, IosInstallSheet.svelte (новый), pushEnvironment.js (использование), subscriptionOffer.js (использование loadOfferProfile), profile_controller.rb (pwa_installed), расширение белого списка event_kind, тесты, APPLE_WALLET_ORDER_PASS.md и текст каскада (по строке); Subtask 13 после проверки на iPhone: orderStatusNotifyActions.js (тексты recovery)
## Не ломать: логика beforeinstallprompt и appinstalled на Android (кроме Subtask 7 и 10), application.js, boot, каталог и корзина, /pwa_install (идемпотентность), /session/refresh, поля и условия оффера в профиле, код Wallet, инвариант TASK_99
## Проверка: npm test -- --run; npm run lint; npm run typecheck; бэкенд-тесты; bundle exec rubocop; ручная приёмка iPhone и Android
## DoD: Subtask 0–12 (кроме отложенных 5 и 13), плашка возвращается в следующей сессии, пока приложение не установлено, воронка установки видна в Metabase

---

## Заметки агента

- Метки в тексте → ID заказчика (по таблице меток [очереди](../PUSH_SMS_QUEUE.md)): TASK-IOS-PUSH-PATH = эта задача (TASK_111, Д8); TASK-PUSH-ENV-SNAPSHOT = TASK_112 (Д9, шаг 1); TASK-PUSH-ENV-GATE = TASK_109 (Д7a, шаг 9).
- Сверка шапки с очередью (п. 4 «Как работать»): «Зависит от» TASK_112 и TASK_109 (Subtask 2) = строка 11 очереди «Зависит от: 1, 9» — оба `done` (TASK_109 выкачен на Fly v520); «Документ готов к билду, кроме Subtask 5 и 13» = статус `todo` (5 и 13 отложены самим документом); «реверс решения «Wallet на паузе» от 22.09» = пометка «реверс» в строке очереди. Расхождений нет.
- Subtask 11: условие «Wallet скрывается настройкой на Fly только после выкладки TASK_109» уже выполнено (Fly v520); сама настройка `WALLET_FORCE_UNAVAILABLE` — секрет prod, отдельный апрув владельца (очередь, 🚀 3).
- **Subtask 6 → вероятно миграция.** Белый список `event_kind` — `ShopEnvironmentEvent::EVENT_KINDS` (`app/models/shop_environment_event.rb:7`), сервис читает его из модели (`app/services/shop/environment_event_recorder.rb:35`), в базе — CHECK `chk_shop_environment_events_event_kind` (`db/schema.rb:1197`, после миграции TASK_110 `20261029090000` — 7 видов). Четыре новых вида (`install_banner_shown`, `install_banner_tap`, `install_banner_dismiss`, `pwa_first_launch`) без расширения CHECK не запишутся. Документ сам разрешает «расширение белого списка event_kind» (разделы 2 и «Файлы»); прецедент — решение владельца на TASK_110. На `/spec` — Migration Gate (`coffeeos-dev-gates.mdc`); миграция TASK_110 ещё не выкачена — обе уйдут в 🚀 4.
- Файлы из ТЗ на месте: `ShopPwaBanner.svelte`, `shopPwa.js`, `subscriptionOffer.js`, `pwa_installs_controller.rb`, `mobile_customer.rb#mark_pwa_installed!` (`:41-44`), `B1_4_pwa_shop.md`, `runbooks/APPLE_WALLET_ORDER_PASS.md`; `IosInstallSheet.svelte` — нет (новый). Поля `pwa_installed` в ответе профиля сейчас нет (есть только `pwa_installed_at` в ответе `/pwa_install`).
- Связанное в ISSUES (🟡, не в scope задачи): «Плашка «Установить CoffeeOS» перекрывает заголовок товара» на `#/product/:id` (приёмка v516) — тот же компонент и то же положение, которое Subtask 1 сохраняет для iPhone; на `/spec` — решение владельца, трогать ли.
- Прецедент шагов 6–10: команд `npm test -- --run` / `npm run lint` / `npm run typecheck` в проекте нет — JS-тесты `node --test test/javascript/*.mjs`, сборка `npx vite build`.
- Факты файл:строка из разделов 2–3 не сверялись (это `/spec`); `App.svelte:154`, `orderStatusNotifyActions.js:135-136, 181-187` и др. могли сдвинуться после шагов 6–10. Зона карты: `orderStatusNotifyActions.js` (только Subtask 13, отложен) → `COMPONENT_MAP.md` на `/spec` — по необходимости; `ShopPwaBanner`/`shopPwa.js` в карте нет (так и сказано в документе).
