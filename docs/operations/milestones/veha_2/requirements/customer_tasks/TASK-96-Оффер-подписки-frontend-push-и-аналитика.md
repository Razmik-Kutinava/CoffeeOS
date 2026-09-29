# TASK_96: Оффер подписки — frontend, push и аналитика

**CBR:** #96 · **Дата intake:** 2026-09-29  
**Источник:** Google Doc Spec  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/subscription_offer_frontend_push_analytics/  
**Google Doc:** https://docs.google.com/document/d/1kbB0iDYgFoioln0I2xUXeMBXWaKo_cKqDEfproHJN1M/edit?usp=drivesdk  
**Тип:** новая фича (продолжение TASK_95, не патч, не EXT) · полный SBR  
**Статус:** intake `[x]` · ждёт `/spec`

---

## Текст задачи (дословно) — Google Doc Spec

TASK_96: Оффер подписки — frontend, push и аналитика

Бизнес-цель: Довести состояние оффера подписки из задачи «Состояние оффера подписки на гостя» до пользовательских каналов и аналитики: показывать согласованный оффер на статусе заказа и в ЛК, отправлять push при фактическом переходе оффера в `shown`, фиксировать действия гостя и сохранять UTM-атрибуцию до покупки. Реализация не должна изменять существующий UX статуса заказа, push-уведомления о статусах заказов и существующий экран оформления/покупки подписки.

## 1. Связь с картой интеграций

- **Затронутые сервисы из `@INTEGRATIONS.md`:**
  - `docs/integrations/pwa-realtime.md` — `profile/config`, статус заказа и существующая FCM/push-инфраструктура.
  - `docs/integrations/shop-api.md` — существующие `POST /shop/api/subscription_offer/dismiss` и `POST /shop/api/subscription_offer/viewed`.
  - `docs/integrations/notify-loyalty.md` — существующий FCM registration flow и `push_enabled_at`.
- **Смежные модули, которые НЕЛЬЗЯ ломать:**
  - `OrderStatus.svelte`;
  - `ActiveOrdersAccordion.svelte`;
  - `orderStatusCtaMachine.js`;
  - существующие CTA статуса заказа;
  - `ShopPwaBanner.svelte`;
  - существующий FCM registration flow;
  - push `Cascade ready` и другие push статуса заказа;
  - `subscription_offer_states`;
  - `OfferPresentationService`;
  - `SubscriptionOfferEligibility`;
  - `GrowthPromo`;
  - существующий экран ЛК и его карточки;
  - экран оформления подписки и «Моя подписка`;
  - `Subscriptions::PurchaseService`;
  - существующая семантика `admin_audit_logs`, если она будет использоваться как источник/приёмник аналитических событий.

## 2. Связь с картой компонентов

- **Затронутые компоненты из `@COMPONENT_MAP.md`:**
  - `OrderStatus.svelte`;
  - `ActiveOrdersAccordion.svelte`;
  - `orderStatusCtaMachine.js`;
  - `OfferPresentationService`;
  - `Subscriptions::PurchaseService`;
  - существующий экран/роут ЛК.
  - Фактические пути и владельцы сверить с `docs/operations/session/COMPONENT_MAP.md` перед реализацией.
- **Общий файл с другой задачей:** **да**.
  - `OfferPresentationService` принадлежит задаче «Состояние оффера подписки на гостя»; текущая задача может только добавить side-effect вызова `OfferPushNotifier` и аналитического события при уже существующем переходе в `shown`, не менять правила eligibility/state machine.
  - `Subscriptions::PurchaseService` принадлежит задаче «Архитектура подписки»; текущая задача может только добавить side-effect фиксации `subscription_purchased` и UTM-атрибуции, не менять алгоритм покупки.
  - `OrderStatus.svelte` и существующий экран ЛК принадлежат существующему frontend-коду; разрешается только интеграционная точка монтирования новых компонентов.
- **Новый компонент (не в карте):** **да**.
  - `SubscriptionOfferBanner.svelte`;
  - `SubscriptionOfferCard.svelte`;
  - `OfferPushNotifier`;
  - модель/компонент аналитических событий `marketing_events`, если такой компонент отсутствует в карте.

## 3. Разрешенный и Запрещенный Scope

- **Разрешено менять/создавать:**
  - frontend-компонент `SubscriptionOfferBanner.svelte`;
  - frontend-компонент `SubscriptionOfferCard.svelte`;
  - существующий frontend-экран статуса заказа только в части точки монтирования баннера;
  - существующий frontend-экран/роут ЛК только в части подключения карточки оффера;
  - чтение `should_show_banner` и `has_unread_offer_in_lk` из `profile/config`;
  - вызовы существующих `dismiss` и `viewed`;
  - переход из баннера/карточки на экран оформления подписки;
  - передачу UTM-параметров и канала оффера через deep link;
  - frontend unit/E2E-тесты новых сценариев;
  - `Subscriptions::OfferPushNotifier`;
  - вызов `OfferPushNotifier` из `OfferPresentationService` исключительно как side-effect перехода в `shown`;
  - idempotency отправки push, привязанной к конкретному переходу в `shown`;
  - шаблон push-оффера;
  - backend unit/integration/regression-тесты push;
  - модель и миграцию `marketing_events`;
  - логирование событий `banner_shown`, `banner_dismissed`, `lk_viewed`, `offer_opened`, `push_sent`, `push_opened`, `subscription_purchased`;
  - сохранение `utm_campaign`, `utm_content`, `offer_channel` при покупке согласно существующему контракту задачи «Архитектура подписки»;
  - минимальный read API/отчёт агрегации воронки, если в проекте отсутствует готовый механизм аналитики.
- **Строго запрещено менять:**
  - структуру layout `OrderStatus.svelte`, кроме минимальной точки монтирования баннера;
  - `orderStatusCtaMachine.js`;
  - существующие CTA статуса заказа;
  - `ShopPwaBanner.svelte`;
  - алгоритмы `subscription_offer_states`;
  - eligibility-правила `OfferPresentationService`;
  - `SubscriptionOfferEligibility`;
  - `GrowthPromo`;
  - FCM registration flow и запись `push_enabled_at`;
  - push статуса заказа, включая `Cascade ready`;
  - Apple Wallet push;
  - содержимое экрана оформления подписки;
  - алгоритм `Subscriptions::PurchaseService`;
  - схему/семантику существующего `admin_audit_logs`;
  - создание отдельных `todo-[feature].md` файлов.

## 4. Сценарии и Чек-лист (Gherkin)

- **Subtask 1: Показать баннер оффера на статусе заказа**
  - Given: `profile/config` вернул `should_show_banner = true`, гость авторизован и находится на статусе `ready`.
  - When: рендерится экран статуса заказа.
  - Then: под виджетом статуса отображается `SubscriptionOfferBanner`; существующий виджет статуса не сдвигается, не сжимается и не меняет свою структуру.
- **Subtask 2: Скрыть баннер для неавторизованного гостя**
  - Given: `should_show_banner = true`, но активная сессия отсутствует.
  - When: рендерится экран статуса заказа.
  - Then: баннер оффера полностью отсутствует.
- **Subtask 3: Зафиксировать фактический показ баннера**
  - Given: баннер разрешён backend-состоянием и фактически отрендерен.
  - When: происходит первый рендер баннера за текущую сессию просмотра статуса.
  - Then: вызывается механизм `mark_shown` из задачи A; повторный frontend-рендер в рамках той же сессии не создаёт повторный переход.
- **Subtask 4: Обработать dismiss баннера**
  - Given: баннер отображается.
  - When: гость свайпает баннер или нажимает крестик.
  - Then: баннер скрывается локально без задержки; отправляется `POST /shop/api/subscription_offer/dismiss`; ошибка запроса не вызывает повторное отображение или retry-петлю в текущей сессии.
- **Subtask 5: Обработать клик по баннеру**
  - Given: баннер отображается.
  - When: гость нажимает на область баннера, не являющуюся dismiss-контролом.
  - Then: выполняется переход на экран оформления подписки с сохранением канала и UTM-атрибуции; событие `offer_opened` создаётся неблокирующим способом.
- **Subtask 6: Не отображать баннер при `should_show_banner = false`**
  - Given: `profile/config` вернул `should_show_banner = false`.
  - When: рендерится экран статуса.
  - Then: баннер не создаётся; frontend не пытается самостоятельно определять причину отказа.
- **Subtask 7: Отобразить карточку оффера в ЛК**
  - Given: гость eligible для оффера и состояние не равно `purchased`.
  - When: гость открывает ЛК.
  - Then: среди существующих карточек отображается `SubscriptionOfferCard`.
- **Subtask 8: Отобразить индикатор непрочитанного**
  - Given: `has_unread_offer_in_lk = true`.
  - When: рендерится ЛК.
  - Then: рядом с карточкой оффера и/или точкой входа в ЛК отображается индикатор непрочитанного согласно существующей дизайн-системе.
- **Subtask 9: Погасить индикатор через `viewed`**
  - Given: карточка оффера открыта и `has_unread_offer_in_lk = true`.
  - When: гость раскрывает/открывает карточку.
  - Then: отправляется `POST /shop/api/subscription_offer/viewed`; индикатор оптимистично гаснет без перезагрузки ЛК.
- **Subtask 10: Скрыть карточку для неeligible-гостя**
  - Given: backend не разрешает оффер.
  - When: открывается ЛК.
  - Then: карточка оффера отсутствует; остальные карточки ЛК работают штатно.
- **Subtask 11: Скрыть приглашение после покупки**
  - Given: состояние оффера равно `purchased`.
  - When: гость открывает ЛК.
  - Then: `SubscriptionOfferCard` не отображается; используется существующий экран «Моя подписка».
- **Subtask 12: Не ломать статус заказа при ошибке `profile/config`**
  - Given: `profile/config` завершился ошибкой или поля оффера отсутствуют.
  - When: рендерится экран статуса.
  - Then: баннер не отображается, существующий экран статуса продолжает работать штатно.
- **Subtask 13: Не ломать ЛК при ошибке состояния оффера**
  - Given: состояние оффера недоступно.
  - When: рендерится ЛК.
  - Then: карточка оффера и её индикатор не отображаются; остальные карточки ЛК работают штатно.
- **Subtask 14: Создать `OfferPushNotifier`**
  - Given: в проекте существует рабочая FCM-инфраструктура.
  - When: вызывается сервис отправки push-оффера.
  - Then: push отправляется через существующую инфраструктуру без изменения registration flow и push статуса заказа.
- **Subtask 15: Отправлять push при переходе в `shown`**
  - Given: `subscription_offer_states.status` переходит в `shown`, а `push_enabled_at` заполнен.
  - When: `OfferPresentationService` фиксирует переход.
  - Then: вызывается `OfferPushNotifier`.
- **Subtask 16: Не отправлять push без разрешённых уведомлений**
  - Given: `push_enabled_at = null`.
  - When: состояние оффера переходит в `shown`.
  - Then: push не отправляется; состояние оффера и frontend-каналы продолжают работать.
- **Subtask 17: Обеспечить повторный push после нового `shown`**
  - Given: после правила повторного показа из задачи A состояние снова переходит в `shown`.
  - When: происходит новый переход.
  - Then: создаётся новый idempotency-контекст и разрешается новая отправка push.
- **Subtask 18: Исключить дублирование push**
  - Given: `OfferPresentationService` несколько раз вызывается для одного перехода в `shown`.
  - When: выполняется side-effect отправки.
  - Then: push отправляется не более одного раза для этого перехода.
- **Subtask 19: Не отправлять push после покупки**
  - Given: состояние оффера `purchased`.
  - When: гость проходит последующие статусы заказов.
  - Then: push оффера не отправляется.
- **Subtask 20: Не отправлять push при активном промо 11₽**
  - Given: `GrowthPromo.available?(customer, point) = true`.
  - When: вычисляется presentation-состояние.
  - Then: переход в `shown` не происходит и push оффера не отправляется.
- **Subtask 21: Изолировать ошибку FCM**
  - Given: FCM возвращает ошибку при отправке push оффера.
  - When: `OfferPushNotifier` обрабатывает ошибку.
  - Then: ошибка логируется и не пробрасывается в существующий flow push статуса заказа.
- **Subtask 22: Создать модель событий `marketing_events`**
  - Given: в проекте отсутствует отдельный журнал маркетинговых событий оффера.
  - When: применяется миграция.
  - Then: доступна сущность `marketing_events` с `event_type`, `customer_id`, `point_id`, `utm_campaign`, `utm_content`, `channel`, `occurred_at`, `metadata JSONB`.
- **Subtask 23: Зафиксировать `banner_shown`**
  - Given: фактически зафиксирован переход оффера в `shown`.
  - When: выполняется `mark_shown`.
  - Then: создаётся `banner_shown` с актуальным `point_id`.
- **Subtask 24: Зафиксировать `banner_dismissed`**
  - Given: backend получает `POST /shop/api/subscription_offer/dismiss`.
  - When: запрос успешно обрабатывается.
  - Then: создаётся событие `banner_dismissed`.
- **Subtask 25: Зафиксировать `lk_viewed`**
  - Given: backend получает `POST /shop/api/subscription_offer/viewed`.
  - When: запрос успешно обрабатывается.
  - Then: создаётся событие `lk_viewed`.
- **Subtask 26: Зафиксировать `offer_opened`**
  - Given: гость кликает по баннеру или карточке ЛК.
  - When: выполняется переход на оформление.
  - Then: создаётся `offer_opened` с `channel = banner` или `channel = lk`.
- **Subtask 27: Передавать UTM через deep link**
  - Given: гость открывает оффер из баннера или ЛК.
  - When: формируется URL экрана оформления.
  - Then: deep link содержит `utm_campaign`, `utm_content` и канал, соответствующие источнику и версии оффера.
- **Subtask 28: Сделать логирование клика неблокирующим**
  - Given: событие `offer_opened` фиксируется перед навигацией.
  - When: запрос аналитики не успевает завершиться.
  - Then: навигация не блокируется; используется доступный в проекте механизм `sendBeacon`/fire-and-forget/очередь с backend retry.
- **Subtask 29: Зафиксировать `push_sent`**
  - Given: `OfferPushNotifier` успешно завершил отправку push через FCM.
  - When: отправка подтверждена.
  - Then: создаётся `push_sent`.
- **Subtask 30: Зафиксировать `push_opened`**
  - Given: push содержит deep link с идентификатором источника.
  - When: гость открывает push и переходит в приложение.
  - Then: создаётся `push_opened`.
- **Subtask 31: Зафиксировать покупку с атрибуцией**
  - Given: `Subscriptions::PurchaseService` успешно активировал подписку.
  - When: покупка завершена.
  - Then: создаётся `subscription_purchased`; при наличии последнего `offer_opened` сохраняются соответствующие `utm_campaign`, `utm_content` и `offer_channel`.
- **Subtask 32: Не изменять алгоритм покупки при аналитическом side-effect**
  - Given: `Subscriptions::PurchaseService` выполняет покупку.
  - When: логирование `subscription_purchased` завершается ошибкой.
  - Then: успешная покупка не откатывается и существующий purchase flow не меняется.
- **Subtask 33: Реализовать минимальный отчёт воронки**
  - Given: в `marketing_events` накоплены события.
  - When: запрашивается отчёт за диапазон дат.
  - Then: возвращается агрегация по `event_type` и `channel` без обязательного создания отдельного dashboard UI.
- **Subtask 34: Покрыть frontend unit-тестами**
  - Given: реализованы `SubscriptionOfferBanner` и `SubscriptionOfferCard`.
  - When: запускается frontend unit test runner.
  - Then: покрыты позитивные, negative и error-path сценарии показа, dismiss, viewed и purchased.
- **Subtask 35: Выполнить E2E-проверку frontend**
  - Given: frontend собран против Fly.
  - When: запускаются E2E-сценарии.
  - Then: проверены показ баннера, dismiss, переход в оформление, отображение карточки ЛК и гашение unread-индикатора.
- **Subtask 36: Выполнить backend regression**
  - Given: реализованы push и аналитические side-effects.
  - When: запускается существующий backend test suite.
  - Then: подтверждено отсутствие регрессий в `OfferPresentationService`, FCM/push статуса заказа и `PurchaseService`.

## 5. Команды TDD-проверки

- **Frontend unit:** существующий test runner Shop-фронтенда.
- **Backend unit/integration:** существующий test runner backend для `OfferPushNotifier`, `OfferPresentationService` и `marketing_events`.
- **Проверка типов:** `npx tsc --noEmit`.
- **E2E:** существующий E2E runner проекта против Fly.
- **Regression:** существующий test suite push/FCM и зона покупки подписки.

| Компонент | Файлы | Владеющая задача | Общий файл с | Не трогать без пометки |
| --- | --- | --- | --- | --- |
| SubscriptionOfferBanner | путь frontend-компонентов Shop / SubscriptionOfferBanner.svelte | Оффер подписки — frontend, push и аналитика | OrderStatus.svelte — существующий владелец | Не менять layout OrderStatus.svelte, только точку монтирования |
| SubscriptionOfferCard | путь frontend-компонентов Shop / SubscriptionOfferCard.svelte | Оффер подписки — frontend, push и аналитика | существующий экран/роут ЛК | Не менять существующие карточки ЛК и экран «Моя подписка» |
| OfferPushNotifier | backend-модуль Subscriptions / OfferPushNotifier | Оффер подписки — frontend, push и аналитика | OfferPresentationService — задача «Состояние оффера подписки на гостя» | Не менять state machine, eligibility и FCM registration flow |
| marketing_events | backend-модель/миграция аналитики | Оффер подписки — frontend, push и аналитика | — | Не изменять семантику существующего admin_audit_logs |
| OfferPresentationService | существующий путь из COMPONENT_MAP.md | Состояние оффера подписки на гостя | Оффер подписки — frontend, push и аналитика | Текущая задача добавляет только side-effect push/analytics; правила состояния принадлежат задаче-владельцу |
| Subscriptions::PurchaseService | существующий путь из COMPONENT_MAP.md | Архитектура подписки | Оффер подписки — frontend, push и аналитика | Текущая задача добавляет только side-effect покупки/атрибуции; purchase algorithm не менять |

---

## Заметки агента

- Тип: **новая фича** — продолжение TASK_95 (backend состояния уже есть: `subscription_offer_states`, `OfferPresentationService`, `dismiss`/`viewed`, флаги в `profile/config`); в репо нет `OfferPushNotifier`, `marketing_events`, `SubscriptionOfferBanner`/`Card` → полный SBR.
- «Задача A» в тексте = TASK_95 (владелец `mark_shown` / state machine).
- Пересечение: в Drive есть [TASK_97: Push-оффер подписки](https://docs.google.com/document/d/1VN1VSBHuGtIjluoNFATbmAw0OsfL_UBqKnPho_fTtU4/edit) и [TASK_98: События воронки и UTM-атрибуция](https://docs.google.com/document/d/1XSqPUfCJYxBsEU8oxr8R6Exj9VibgQIPMsBqtYJUNzM/edit) — по названиям дублируют push (Subtask 14–21) и аналитику (22–33). SPEC 2026-09-29 (владелец): TASK_96 делаем **целиком**, TASK_97/98 держим в уме, их судьбу решает владелец.
- **Блокер (SPEC 2026-09-29):** во frontend нет экрана оформления подписки / «Моя подписка» (billing UI, Задача-3) → цель перехода Subtask 5/26–27/30/35 не существует. Решение владельца: TASK_96 ждёт billing UI.
- Зависимость: TASK_95 на стадии `/review` (не задеплоен) — RED/GREEN TASK_96 строить поверх `develop` после мержа #95.
- §5 `npx tsc --noEmit` — Shop-фронт на Svelte/JS; применимость уточнить на `/spec`.
