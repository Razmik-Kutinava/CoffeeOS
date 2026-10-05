# todo — TASK_37 Патч 1: CSP ответа `/firebase-messaging-sw.js` разрешает gstatic

| Поле | Значение |
|------|----------|
| **Основание** | [TASK_37 § Патч 1: 2026-10-02](../milestones/veha_2/requirements/customer_tasks/Адаптивный%20виджет%20статуса%20заказа%20Детекция%20ОС%20и%20подписка%20на%20уведомления.md) · Шаг 5 (patch v1) · остальные шаги #37 — контекст, не scope · [Google Doc](https://docs.google.com/document/d/1gBhAA7-xZd0zkEZueOaKrNo8upuk8DfOJLibCt6bvd0/edit) |
| **Тип** | патч (не доп.задача) |
| **Статус** | RED `46de7f82` · GREEN `9608d9f2` → `/regress` → `/review` |

## SBR

- [x] intake Патча 1 в TASK-37 (секция в конце файла)
- [x] RED `46de7f82` — `firebase_sw_csp_test.rb`: 2 fail (нет `https://www.gstatic.com` в `script-src` ответа SW), охранный тест «глобальная CSP без gstatic» зелёный сразу
- [x] GREEN `9608d9f2` — `content_security_policy` в `Shop::FirebaseSwController`: глобальный `script-src` + `https://www.gstatic.com`
- [x] `/regress` PASS — Rails 10 файлов (firebase_sw_csp, push_register, push_pipeline, order_status CBR, profile offer, wallet_pass, pwa_manifest, pwa LK, offer funnel, marketing events) 57/0 · JS 7 файлов push/notify/sw/wallet/offer 112/0
- [x] `/review` — bugbot: 1 находка (304 без CSP → браузер держит старую политику) → RED `19fff712` → GREEN `e91f2daa` (`Cache-Control: no-store` + уникальный weak ETag) → повторный bugbot 0 · security 0 · crit-audit CLEAN (`last_audited_sha` = `e91f2daa`) · Entire `01M45HNNHAF3YGAFK4X55X00Z4` · push → CI
- [ ] Device: Android Chrome / desktop — SW регистрируется, `getToken()` проходит — после deploy по апруву · Fly MCP Point A

## Файлы

- `app/controllers/shop/firebase_sw_controller.rb` — локальная CSP только для этого ответа (берёт глобальный `script-src` и добавляет один источник)
- `test/integration/shop/firebase_sw_csp_test.rb` — новый (HTTP-регрессия CSP ответа SW + охрана глобальной CSP)

## Не ломать

- `config/initializers/content_security_policy.rb` — без изменений; `connect-src` не расширяем (ошибка не подтверждена)
- `app/views/shop/firebase_sw/show.js.erb` (COMPONENT_MAP `firebase_sw (FCM)`, TASK_92/#38), `firebasePush.js`, Firebase/VAPID конфиг, `POST /shop/api/push/register`
- Apple Wallet, PWA SW, TASK_90 (denied → настройки), TASK_81/#90, TASK_92/#38

## Проверка

- `ruby bin/rails test test/integration/shop/firebase_sw_csp_test.rb test/integration/shop/push_pipeline_simulation_test.rb test/integration/shop/api/push_register_test.rb test/integration/shop/order_status_acceptance_cbr_test.rb test/integration/shop/api/profile_subscription_offer_test.rb` — 24/0
- `node --test test/javascript/order_status_push_subscribe_test.mjs test/javascript/subscription_offer_card_test.mjs` — 45/0

## DoD

- [x] Ответ `/firebase-messaging-sw.js`: `script-src` = глобальный + `https://www.gstatic.com`; `connect-src` = глобальный
- [x] Глобальная CSP без `gstatic` / `google` / `*`
- [ ] SW регистрируется и `getToken()` проходит на устройстве — после deploy по апруву

---

# todo — TASK_90 Патч 1: авто-подписка после возврата из настроек уведомлений

| Поле | Значение |
|------|----------|
| **Основание** | [TASK_90 § Патч 1: 2026-10-02](../milestones/veha_2/requirements/customer_tasks/TASK-90-Восстановление-WebPush-после-запрета-уведомлений.md) · Subtask 7 (patch v1) · остальные Subtask #90 — контекст, не scope · [Google Doc](https://docs.google.com/document/d/1YtZzj-Lf2HHrM4azejIuZISTKsWdu8q6y-kPHvm_d44/edit?usp=sharing) |
| **Статус** | REVIEW `[x]` · CI green [37283046314](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37283046314) на `3f14dda9` · deploy по апруву |

## SBR

- [x] intake Патча 1 в `TASK-90-…md` · `cba87679`
- [x] SPEC — факт ниже; `COMPONENT_MAP.md` сверен (строки `ActiveOrdersAccordion` / `orderStatusNotifyActions.js` / `firebasePush.js`: TASK_90 — владелец recovery, #83/#84 не трогаем)
- [x] RED `736d79a9` — нет экспорта `resumePushAfterSettings` (импорт падает)
- [x] GREEN `2f3d39de` — `resumePushAfterSettings` (lib) + `visibilitychange`/`pageshow` в аккордеоне, пока показан recovery UI · тест 34/0 · JS зона 183/1 (1 = legacy `order_action_buttons_cancel_test`, падает и без патча) · `vite build` OK
- [x] `/regress` PASS (на `3bdc6b78`): JS весь `test/javascript` 671 — 60 fail = legacy (те же 3 набора: #71 email, sticky cancel #41, personal cabinet [RED]) · Rails push_register + order_status (sheet mount, acceptance CBR, meta canon) + profile offer 28/0 · `vite build` OK
- [x] `/review`: bugbot 0 · security 0 · crit-audit CLEAN (TASK_90-only, журнал) · Entire `01M45J5ZBRMVT395VJPVB9BZNC` на `3f14dda9` · push · CI + Semgrep + CodeQL green [37283046314](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37283046314)
- [ ] `COMPONENT_MAP.md` строка `ActiveOrdersAccordion` / `orderStatusNotifyActions.js` (re-entry TASK_90 Патч 1) — только после зелёного Review
- [ ] Device: Android + Chrome «denied → настройки → разрешил → вернулся → подписка без повторного CTA» — после deploy по апруву

## Факт (до правок)

- `registerShopPush()` вызывается только из CTA `onAction("push")` → `subscribeOrderPush`; при `denied` аккордеон ставит `pushRecovery = true` (recovery UI «Открыть настройки» / «Смотреть готовность»).
- В `ActiveOrdersAccordion` нет `visibilitychange` / `pageshow` / `focus` → после возврата из настроек permission не перепроверяется, нужен повторный клик.
- Паттерн проекта для re-entry — `visibilitychange` + `pageshow` (`App.svelte` 106–147, `OrderStatusSheet.svelte` 192–205).
- `registerShopPush()` при уже `granted` диалога не показывает (`requestPermission` сразу `granted`) → повторного permission-flow нет.

## Файлы

1. `app/frontend/lib/orderStatusNotifyActions.js` — `resumePushAfterSettings({ armed, permission?, … })`: если `armed` и `Notification.permission === "granted"` → существующий `subscribeOrderPush` → `registerShopPush`; иначе `{ resumed: false }`.
2. `app/frontend/components/ActiveOrdersAccordion.svelte` — `$effect` пока `pushRecovery`: `visibilitychange` (visible) + `pageshow` → `resumeAfterSettings()`; при `ok` → `pushSubscribed = true`, recovery скрыт. Guard `actionLoading` от двойного срабатывания. Отдельного recovery-state нет — флаг готовности = существующий `pushRecovery`.
3. `test/javascript/order_status_push_subscribe_test.mjs` — +7 тестов: denied/default/не armed → без register; цепочка `denied → settings → granted → return → registerShopPush`; ошибка register без throw; чтение `Notification.permission`; source-оракул слушателей.

**Только чтение:** `firebasePush.js` (`registerShopPush` без изменений), `App.svelte`, `OrderStatusSheet.svelte`, `COMPONENT_MAP.md`.

## Не ломать

- `registerShopPush()` / `/shop/api/push/register` / VAPID / FCM / Service Worker — ни строчки.
- Обычный CTA push: `default → requestPermission → granted`, `denied` → recovery UI, fallback-инструкция без deep-link.
- «Смотреть готовность» скрывает recovery и снимает слушатели (re-entry только пока recovery на экране).
- Чек / CTA «Состав заказа» (#84), отсутствие `×` (#83), iOS Wallet, tips/chat/cancel, `orderStatusCtaMachine.js`, `OrderStatus.svelte`.

## Проверка

- `node --test test/javascript/order_status_push_subscribe_test.mjs` — 34/0
- JS зона (`order_status*` `active_orders*` `order_action*` `cart_sheet*` `sticky*` `order_cancel*`) — 183/1 (legacy)
- `npm run vite:build`
- Ручная: Android + Chrome и desktop — после deploy по апруву

## DoD

- [x] Subtask 7 (patch v1): возврат в PWA при `granted` → `registerShopPush()` без повторного клика по CTA
- [x] `denied`/`default` после возврата → recovery UI остаётся, регистрации нет
- [x] Без нового статуса заказа / recovery-state, backend и `registerShopPush` не менялись
- [x] Review + CI green
- [ ] ручная проверка Android + Chrome после deploy

---

# todo — TASK_86 Патч 1: смонтированный WAITING-экран переходит в результат

| Поле | Значение |
|------|----------|
| **Основание** | [TASK_86 § Патч 1: 02.10.2026](../milestones/veha_2/requirements/customer_tasks/TASK-86-Восстановление%20PWA%20после%20оплаты%20СБП-EXT.md) · Subtask 4 и 5 (patch v2) · остальные Subtask #86 — контекст, не scope |
| **Статус** | `/regress` PASS → `/review` |

## SBR

- [x] intake Патча 1 в `customer_tasks/TASK-86-…-EXT.md` · `26615bfb`
- [x] SPEC — факт ниже, файлы, Не ломать, Проверка
- [x] RED `0e85e41d` — нет экспорта `resolveWaitingScreenTransition` (импорт падает)
- [x] GREEN — `resolveWaitingScreenTransition` + `hashchange` в `PaymentResult` (`applyWaitingTransition`, повторный `syncWaitingWithHash` после reconnect) · JS зона 71 → 70/1 (1 = legacy #71 `email_collection_test` по `Checkout.svelte`, не наш файл) · Rails 24/0 · `vite build` OK
- [x] `/regress` PASS (на `bdfef83c`): JS весь `test/javascript` 664 — 60 fail = legacy (те же 3 набора: `email_collection` #71, `order_action_buttons_cancel`, `personal_cabinet` [RED]) · Rails `test/integration/shop` + `test/services/payments` 814/0 (1-й прогон — 1 разовый error, не воспроизвёлся на 2 прогонах) · `vite build` OK
- [ ] `/review` (bugbot + security + crit-audit, Entire, push, CI)
- [ ] `COMPONENT_MAP.md` строка `PaymentResult` — только после зелёного Review
- [ ] Device: Android/iOS «вернулся в открытый PWA → экран сам ушёл в результат» — после deploy по апруву

## Факт (до правок)

- `App.svelte` `recoverCodeblackPendingOrder` → `recoverPendingPayment` → `push("/payment-result?status=ok|fail&order_id=…")`.
- `svelte-spa-router`: тот же маршрут `/payment-result`, меняется только query → компонент **не** пересоздаётся.
- `PaymentResult.svelte` читает `status` / `order_id` один раз в `onMount` → при `waiting` ставит `waitingForBank = true` и больше URL не слушает → экран висит в `WAITING_FOR_BANK`.
- `checkOrderStatus` уже чистит pending при `CONFIRMED/REJECTED/CANCELED`; повторный terminal на тот же `orderId` режется `terminalShownForOrderId` (#86, не меняем).
- Паттерн проекта для реакции на URL — `window.addEventListener("hashchange", …)` (`CartSheet`, `OrderStatusSheet`, `Cart`).

## Файлы (ожидаемо)

1. `app/frontend/lib/shopSbpPay.js` — чистая `resolveWaitingScreenTransition({ currentStatus, nextStatus, currentOrderId, nextOrderId })` → `"success" | "incomplete" | "none"`. Переход только из `waiting` и только для того же `orderId`.
2. `app/frontend/routes/PaymentResult.svelte` — `hashchange` в `onMount` (+ снятие), при `success` → существующий `prepareSuccessScreen` + `maybeAutoReturnToCatalog` (как `onIPaid`); при `incomplete` → `clearPendingOrder`, `waitingForBank = false`, `SBP_INCOMPLETE_MESSAGE` (как `onIPaid` для REJECTED/CANCELED). Без таймеров/polling/кнопок.
3. `test/javascript/sbp_waiting_screen_transition_test.mjs` (новый) — unit + оракул исходника.

**Только чтение (blast-radius):** `App.svelte` (источник push), `codeblackPendingOrder.js`, `shopGuestSession.js`.

## Не ломать

- Холодный старт `PaymentResult` с `status=ok|fail|cancel|waiting` — ветки `onMount` без изменений.
- «Я оплатил» (`onIPaid`) и email-блок #71 / авто-возврат в каталог TASK_91.
- `recoverCodeblackPendingOrder` / `pendingStatusGuard` / `terminalShownForOrderId` в App и `shopSbpPay` — без изменений.
- Card/Rebill, webhook, TTL, PENDING-UX — не трогаем.

## Проверка

- `node --test test/javascript/sbp_waiting_screen_transition_test.mjs test/javascript/shop_sbp_pay_test.mjs test/javascript/codeblack_pending_order_test.mjs test/javascript/email_collection_test.mjs`
- `ruby bin/rails test test/integration/shop/sbp_payment_return_ui_test.rb test/integration/shop/checkout_acceptance_cbr_test.rb test/integration/shop/order_status_acceptance_cbr_test.rb`
- `npm run vite:build`

## DoD

- Subtask 4 (patch v2): WAITING смонтирован → `status=ok` того же заказа → экран успеха, pending очищен, без remount.
- Subtask 5 (patch v2): WAITING смонтирован → `status=fail|cancel` → экран «Оплата не завершена», pending очищен.
- Чужой `order_id` / повторный `waiting` — экран не меняется.
- Тесты из «Проверки» зелёные, `vite build` OK, Review пройден, deploy — по апруву.

---

# todo — TASK_101: сумма заказа в блоке способов оплаты

| Поле | Значение |
|------|----------|
| **Основание** | [TASK_101](../milestones/veha_2/requirements/customer_tasks/TASK-101-Сумма-заказа-в-блоке-способов-оплаты.md) · новая задача, полный SBR · [GATES](../milestones/veha_2/artifacts/order_total_payment_methods/GATES.md) G1–G8 |
| **Статус** | SPEC `[x]` · `[ОТКРЫТЫЙ ВОПРОС]` = 0 → готово к Build |

## SBR

- [x] intake `a8992dc9` · ledger `96fa9c9a`
- [x] SPEC — факты + решение владельца по акции 11 ₽ (ниже)
- [x] RED `3b752e0a` — JS 8 fail (нет `labelOrderTotal` / `formatRubAmount` / строки) · Rails 3/0 сразу (контракт `total` = `Amount/100` уже есть — фиксирует, ожидаемо)
- [x] GREEN `5fdefa93` (Entire `01M45FTHXKPJ8GNP4F47DNQX7Q`) — строка `Итого` под header шторки (`{#if orderTotalLabel}`), `labelOrderTotal` / `formatRubAmount` (NBSP) в i18n · GATES G1–G7 met (JS 10/0 · Rails 3/0 · scope OK · JS зона · Rails зона · vite build) · G8 manual
- [x] `/regress` PASS (на `c7f0cff0`): JS весь `test/javascript` 650 — 60 fail = legacy (те же 3 набора: #71 email, sticky cancel, personal cabinet [RED]) · Rails `test/integration/shop` + `test/services/payments` 811/0 · `vite build` OK
- [x] `/review`: bugbot 0 · security 0 · crit-audit CLEAN (TASK_101-only, журнал) · Entire `01M45FTHXKPJ8GNP4F47DNQX7Q` на `5fdefa93` · push `fd87c3a4` · CI green [37280048623](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37280048623)
- [ ] `COMPONENT_MAP.md` — новый компонент не создавался (строка внутри `PaymentMethodsSheet`) → БЛОК 4 не требуется; правка карты — только после принятия владельцем, если попросит
- [ ] G8: 360 px локально / Telegram+Instagram In-App / Fly MCP Point A — после deploy по апруву

## Факт (до правок)

- `/shop/api/cart` (`Shop::Api::CartController` show/add/update/destroy) **уже** отдаёт `total` = Σ `line_total`, цена строки с модификаторами (`CartService#json_lines`) → backend и `shop-api.md` не меняем (Subtask 1).
- Фронт: `cartSheetStore.cartTotal` ← `data.total`; при +/− / удалении сначала оптимистичный Σ `line_total`, затем `applyCartData` ответа сервера. `Checkout.svelte` уже подписан на `cartTotal` и передаёт `cartTotalRub` в `PaymentMethodsSheet` (сейчас только для промо-подсказки) → Checkout, скорее всего, не меняем (Subtask 7).
- `Amount` = `(order.final_amount * 100).to_i` (`TbankAdapter#init_payment`); `final_amount` = `cart.total − promo_discount` (всегда `0`, BUG-004), затем `Payments::GrowthPromo.price!`: при акции привязки + галочке сохранения → `final_amount` = 11 ₽.
- Форматтера денег с разделителем тысяч нет (`orderCancelFlow` / `promoNudgeInsteadOf` — `String(Math.round)`).
- `COMPONENT_MAP.md`: `PaymentMethodsSheet` — владельцы TASK_89-POSTCALL-EXT, #89 (internals привязки/СБП не менять); TASK_100 правит inline-ошибку и CTA в том же файле. TASK_101 трогает **только** новую строку под `<header>`.

## Решение владельца (G7, 2026-10-05)

- «Итого» = **всегда** серверный `total` корзины (`cartTotalRub`), в том числе при акции 11 ₽. Про 11 ₽ уже говорит существующая промо-строка — её не трогаем.
- `total` = `Amount / 100` проверяем тестом **без** акции (Subtask 3, 9). При акции расхождение ожидаемо и задокументировано.

## Файлы (ожидаемо)

1. `app/frontend/components/PaymentMethodsSheet.svelte` — строка `Итого` сразу под `<header class="pm-sheet__header">`, **до** веток `loading` / `loadError` / списка → над первой картой / СБП / «Картой +» (с картами и без), не зависит от `fsmState` / `inlineError` (видна в error state). Показ только при `cartTotalRub > 0` (нет `0 ₽`). Стили — существующие токены шторки; сумма справа (`justify-content: space-between`), `white-space: nowrap`.
2. `app/frontend/lib/paymentMethodI18n.js` — `labelOrderTotal()` → `"Итого"` и `formatRubAmount(n)` → `"3 245 ₽"` (неразрывный пробел между тысячами и перед `₽`, округление до рубля как в промо-подсказке). Общий helper рядом с прочими денежными строками шторки; отдельный файл не заводим.
3. `test/javascript/payment_methods_order_total_test.mjs` (новый) — `formatRubAmount` (3245 → `3 245 ₽`, 1000000, 0/NaN/пусто → пусто) + source-оракул шторки: строка с `data-testid="payment-methods-order-total"` до `pm-sheet__list` и вне `{#if loading}` / `inlineError`, guard `cartTotalRub > 0`, нет `price * quantity`.
4. `test/integration/shop/api/cart_total_amount_test.rb` (новый) — корзина: 2 товара, qty 2, модификатор с доплатой → `GET /shop/api/cart` `total` = ожидаемое; заказ из той же корзины (`Shop::OrderCreator`, без привязки) → `TbankAdapter#init_payment` с перехватом `post_json` → `Amount == (total * 100).to_i`.
5. `docs/operations/session/COMPONENT_MAP.md` — на REVIEW (БЛОК 4): TASK_101 в строке `PaymentMethodsSheet`.

**Соседи (blast-radius, не менять — только регрессия):** `Checkout.svelte` (источник `cartTotalRub`), `cartSheetStore.js` (оптимистичный пересчёт → серверный `total`), `CheckoutPayButton.svelte` / `shopPayFsm.js` (TASK_100, error state).

## Не ломать

- Оплата: `TbankAdapter`, `OrderCreator`, `GrowthPromo`, callback — ни строчки (G3).
- Сохранённые карты / СБП / «Картой +» / промо-строка 11 ₽ — разметка и выбор без изменений.
- Ошибка оплаты TASK_100: текст `pm-sheet__inline-error` + CTA кнопки — без изменений, «Итого» не сдвигается.
- Кнопка оплаты и её состояния.

## Проверка

- `node --test test/javascript/payment_methods_order_total_test.mjs` + G4 JS зона (4 файла)
- `ruby bin/rails test test/integration/shop/api/cart_total_amount_test.rb` + G5 Rails зона (6 файлов)
- `npm run vite:build` (вместо typecheck/lint — их нет в `package.json`)
- Ручная: 360×780 без горизонтального overflow · Telegram/Instagram In-App и Fly MCP Point A — после deploy по апруву

---

# todo — TASK_100: точные сообщения при ошибке оплаты и отдельный CTA

| Поле | Значение |
|------|----------|
| **Основание** | [TASK_100](../milestones/veha_2/requirements/customer_tasks/TASK-100-Точные-сообщения-при-ошибке-оплаты-и-отдельный-CTA.md) · новая задача, полный SBR · [GATES](../milestones/veha_2/artifacts/payment_error_messages_cta/GATES.md) G1–G7 |
| **Статус** | SPEC `[x]` · `[ОТКРЫТЫЙ ВОПРОС]` = 0 → готово к Build |

## SBR

- [x] intake `f0fa419a` · ledger `a3059bd7`
- [x] SPEC — классификация кодов + решения владельца (ниже)
- [x] RED `8bb1b27a` — `payment_error_matrix_test.mjs` (нет экспортов) + 2 теста старого текста
- [x] GREEN `efb05433` · Entire `01M45D9SXG53EDFVFDZ758KEP7` — `classifyPaymentError` / `resolvePaymentErrorUi` / `PAY_ERROR_CATEGORY`, тексты в i18n, `errorCta` в кнопку (close/retry/change_card), `showPayError` в Checkout (вкл. 3DS abort) · + обновлён `repeat_invalid_token_payment_test.mjs` (ждал inline = label кнопки — то самое «смешано») · GATES G1–G6 met (matrix 21/0 · JS зона 68/0 · Rails 4 файла 0F/0E · vite build OK)
- [x] `/regress` PASS — найдена регрессия #79 (СБП NETWORK + `NET_ERROR` → общий fallback вместо «Нет связи») → RED `9aeb5ac8` → GREEN `060ef61f` · JS 640 (60 fail = legacy, 3 набора) · Rails shop 673/0 · G3 + `shop_sbp_autopay_checkout_ui_test.mjs`
- [x] `/review` — bugbot: 2 находки (error-кнопка застревает после закрытия шторки: через «Попробовать позже» и через крестик/фон) → RED `164d9b95` → GREEN `82a300b8`; RED `37854804` → GREEN `ebef66bf` · повторный bugbot 0 · security 0 · crit-audit CLEAN · push → CI

## Факт (до правок)

- `shopPayFsm.js`: 12 кодов `CLIENT_ERROR_CODES` + regex по message → одно `PAY_FSM.CLIENT_ERROR` с длинным текстом «…или карта заблокирована банком…».
- «Смешано» буквально: `CheckoutPayButton` в `CLIENT_ERROR` показывает **тот же** `PAY_FSM_LABELS[5]` как подпись кнопки, а `PaymentMethodsSheet` — его же в `role="alert"` (`resolveCheckoutSheetInlineError`).
- CTA сейчас: `CLIENT_ERROR` → `onChangeCard` (форма новой карты по клику; auto-open = false — §7 п.5 уже соблюдён); `NET/BANK` → retry.
- Backend `Shop::TbankPaymentError::FRIENDLY_MESSAGES` ≠ Матрице («Карта просрочена») — **не трогаем** (HTTP-контракт), маппинг на фронте по `error_code`.

## Классификация `error_code` (G6)

| Код | Категория | Источник |
|-----|-----------|----------|
| 1051 | Недостаточно средств | ТЗ Матрица |
| 1014 | Истёк срок карты | ТЗ Матрица |
| 119, 2200 | Слишком много попыток | ТЗ Матрица |
| 1005 | карточный fallback | `shopWidgetPayFsm.js` «отказ эмитента» |
| 1041 | карточный fallback | там же «утеряна» |
| 1054 | карточный fallback | там же «истёк срок» — ТЗ закрепляет «истёк» только за 1014 → не расширяем |
| 1057 | карточный fallback | там же «не разрешена» |
| 1062 | карточный fallback | там же «ограничение карты» |
| 1013, 1053, 1061, 1078 | карточный fallback | `INVALID_REBILL_CODES` (токен карты невалиден) · **решение владельца 2026-10-05** |
| нет кода, message по regex «карт/средств/истёк/блокир…» | карточный fallback | backend message подтверждает карту |
| неизвестный код без карточного message | общий fallback | ТЗ §5 п.5–6 |
| 3DS прерван (нет кода) | общий fallback | **решение владельца** |
| сеть (`NET_ERROR`), 5xx (`BANK_ERROR`) | без изменений | **решение владельца** — вне Матрицы |

## Решения владельца (2026-10-05)

- CTA «Попробовать позже» (119/2200) → закрывает шторку оплаты, карту не трогает.
- «Изменить карту» → текущее `onChangeCard` (форма новой карты по клику).
- «Повторить оплату» → текущий retry.

## Дизайн

- `shopPayFsm.js`: `classifyPaymentError(error)` → категория `insufficient_funds | card_expired | too_many_attempts | card_declined | payment_failed` (null для NET/BANK); FSM-переход как был (карточные + попытки → `CLIENT_ERROR`; `payment_failed` → новое отображение без смены `NET/BANK`). `resolvePaymentErrorUi(category)` → `{ message, ctaLabel, ctaAction: change_card | close | retry }`. Старый текст `PAY_FSM_LABELS[CLIENT_ERROR]` удалить.
- `paymentMethodI18n.js`: 5 сообщений + 3 CTA, ключи по категориям (§9).
- `Checkout.svelte`: хранить `payErrorCategory` рядом с `payFsmState` в catch / `onThreeDsClose` / 3DS catch; сброс там же, где `sheetInlineError = null`; передать в шторку.
- `PaymentMethodsSheet.svelte`: alert = `message`, кнопка = `ctaLabel` — два отдельных элемента.
- `CheckoutPayButton.svelte` (+1 сосед): проп `errorCta` (label + action) вместо `payFsmLabel` в ошибке; `close` → новый колбэк `onClose`.

## Файлы (ожидаемо)

- `app/frontend/lib/shopPayFsm.js` — классификация + UI-резолвер (общий файл: только payment error)
- `app/frontend/lib/paymentMethodI18n.js` — тексты Матрицы
- `app/frontend/routes/Checkout.svelte` — категория ошибки → шторка
- `app/frontend/components/PaymentMethodsSheet.svelte` — message и CTA раздельно
- `app/frontend/components/CheckoutPayButton.svelte` — подпись/действие CTA (blast-radius: рендерит label ошибки)
- `test/javascript/payment_error_matrix_test.mjs` — новый (G1)
- `test/javascript/payment_error_user_messages_test.mjs`, `test/integration/shop/shop_pay_fsm_3ds_test.rb` — обновить ожидания старого текста

## Не ломать

- repeat-order invalid-token: `isInvalidRebillPaymentError` → `setTokenInvalid` (не трогаем `repeatInvalidTokenStore.js`)
- HTTP 422 / payment token / SBP autopay (`resolveSbpAutopaySheetError`) / выбор способа оплаты
- открытие/закрытие `PaymentMethodsSheet`, 3DS overlay, `shouldAutoOpenNewCardOnClientError = false`
- inline pay виджета (`shopInlinePayFsm.js` / `shopWidgetPayFsm.js`) — другой поток

## Проверка

- `node --test test/javascript/payment_error_matrix_test.mjs` (G1) + G2 оракул из GATES
- `node --test test/javascript/payment_error_user_messages_test.mjs test/javascript/repeat_invalid_token_payment_test.mjs test/javascript/widget_repeat_pay_flow_patch1_test.mjs test/javascript/shop_inline_pay_button_fsm_test.mjs test/javascript/open_repeat_payment_sheet_test.mjs test/javascript/shop_widget_pay_fsm_test.mjs test/javascript/payment_method_promo_11rub_i18n_test.mjs` — baseline 68/0
- `bin/rails test test/integration/shop/shop_pay_fsm_3ds_test.rb test/integration/shop/inline_pay_button_patch1_test.rb test/services/shop/tbank_payment_error_test.rb test/integration/shop/api/payment_status_error_code_test.rb`
- `npm run vite:build` · Fly MCP Point A после deploy по апруву

---

# todo — TASK_SAFE-BOTTOM-MIN (доп.задачи 3+4): минимальный нижний отступ 8px

| Поле | Значение |
|------|----------|
| **Основание** | [TASK_SAFE-BOTTOM-MIN](../milestones/veha_2/requirements/customer_tasks/TASK-SAFE-BOTTOM-MIN-Минимальный-нижний-отступ-Home-Indicator.md) — N = 8px · задачи 3 и 4 слиты (решение владельца: шторка статуса встроена в CartSheet, её низ = `--shop-safe-bottom`) |
| **Статус** | REVIEW `[x]` · CI green [36837366924](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36837366924) на `f74e2e5d` · deploy запрещён |

## SBR

- [x] intake `5e516968`
- [x] RED `e6a57efb` — `shop_safe_bottom_min_test.mjs` 9 fail (константа, WebView 0→8, `app.css` max(), 5 экранов без `env()`, добавки 24/16px)
- [x] GREEN `1c21dbda` — `app.css` max(8px, env), `shopWebViewLayout.js` `SHOP_SAFE_BOTTOM_MIN_PX`, 5 экранов на `var(--shop-safe-bottom)` · Entire `01M3SBAXJXWA8X0DWT56SNEE36`
- [x] `/regress` PASS — JS 616 (60 fail = legacy baseline) · `vite build` OK · Rails весь `test/integration/shop` 70 файлов 420/0
- [x] `/review` — bugbot: 1 находка (резерв Catalog/CategoryProducts/Product под CartSheet без safe-bottom) → RED `835566b2` → GREEN `6309066c` → повторный bugbot 0 · security 0 · `/crit-audit` CLEAN (`6309066c`) · push · CI + Semgrep + CodeQL green [36837366924](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36837366924)

## Файлы

- `routes/Catalog.svelte`, `routes/CategoryProducts.svelte`, `routes/Product.svelte` — резерв под CartSheet `+ var(--shop-safe-bottom, 0px)` (bugbot)
- `app/frontend/styles/app.css` — `--shop-safe-bottom: max(8px, env(safe-area-inset-bottom, 0px))`
- `app/frontend/lib/shopWebViewLayout.js` — `SHOP_SAFE_BOTTOM_MIN_PX = 8`, `max()` для значения от WebView
- `CatalogFiltersSheet.svelte`, `CatalogSortSheet.svelte`, `ContactSupportSheet.svelte`, `routes/OrderReceipt.svelte`, `OrderStatusSheet.svelte` — `env()` → `var(--shop-safe-bottom, 0px)`
- `test/javascript/shop_safe_bottom_min_test.mjs` — новый

## Не ломать

- `--shop-safe-top`, `--shop-keyboard-inset`, высоты CartSheet / `stackBottomPx` (pay stack) / `cartSheetThresholds`
- #67 тест «34px» (`shop_telegram_webview_ui_test.mjs`) — значение > 8 не меняется
- чек / peek-only / стрелка / `×`

## Проверка

- `node --test test/javascript/shop_safe_bottom_min_test.mjs` — 11/0
- зона JS (`shop_*` `order_status*` `active_orders*` `cart_sheet*` `catalog*` `contact*` `order_receipt*` `sticky*` `order_cancel*` `order_action*`, 33 файла) — 344/1 (legacy «422/500»)
- Rails (telegram/webview/safe, b113_s2*, cart_sheet, catalog filter/sort, contact support, order receipt, order_status_sheet — 11 файлов) — 67/0
- визуально: Android (inset 0) — CartSheet в peek поднят на 8px; iPhone — без изменений (34px). Устройство / Fly — после deploy

## DoD

- [x] inset 0 → отступ 8px; inset 34 → 34px
- [x] все bottom-sheet берут отступ из `--shop-safe-bottom`
- [x] добавки 24px/16px сохранены
- [x] Review + CI green

---

# todo — TASK_84-RECEIPT-ARROW-EXT (доп.задача 2): стрелка `>` / `v` на кнопке «Состав заказа»

| Поле | Значение |
|------|----------|
| **Основание** | [TASK_84-RECEIPT-ARROW-EXT](../milestones/veha_2/requirements/customer_tasks/TASK-84-RECEIPT-ARROW-EXT-Стрелка-состояния-на-кнопке-Состав-заказа.md) — сценарий владельца 2026-10-01 · стрелка только на кнопке чека |
| **Реверсирует** | запрет «новые стрелки» в Scope TASK_84-RECEIPT-DISPLAY-EXT (только кнопка чека); chevron #36 на шапке и тест #35 остаются |
| **Статус** | REVIEW `[x]` · CI green [36832232323](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36832232323) на `f4658bb7` · deploy запрещён |

## SBR

- [x] intake `86a123ce`
- [x] RED `c0aef683` — `active_orders_receipt_arrow_test.mjs` 3 fail (SSR: текст кнопки, `aria-expanded`, `aria-hidden` стрелка)
- [x] GREEN `d3f929a8` — `ActiveOrdersAccordion.svelte`: `<span class="aoa__receipt-arrow" aria-hidden="true">{row.chevron}</span>` в кнопке · Entire `01M3SBAXJXWA8X0DWT56SNEE36`
- [x] `/regress` PASS — JS 605 (60 fail = legacy baseline) · `vite build` OK · Rails 18 файлов 100/0
- [x] `/review` — bugbot 0 · security 0 · `/crit-audit` CLEAN (`406b10e7`) · push · CI + Semgrep + CodeQL green [36832232323](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36832232323)

## Файлы

- `app/frontend/components/ActiveOrdersAccordion.svelte` — стрелка в `aoa__receipt-cta` + CSS `.aoa__receipt-arrow`
- `test/javascript/active_orders_receipt_arrow_test.mjs` — новый

## Не ломать

- шапка строки без стрелки (chevron #36 не возвращаем, тест #35 «нет `aoa__chevron`»)
- `LABELS.receipt` = «Состав заказа» (`orderStatusNotifyActions.js`) и тесты на него; `aria-label` кнопки без стрелки
- чек / `fitReceiptInView` / peek-only (`OrderStatusSheet.svelte`) / `×` / polling / Cable

## Проверка

- `node --test test/javascript/active_orders_receipt_arrow_test.mjs` — 3/0
- зона JS (`order_status*` `active_orders*` `cart_sheet*` `sticky*` `order_cancel*` `order_action*` `subscription_offer_banner*`) — 197/1 (legacy «422/500»)
- браузер — browser MCP завис 2026-10-01, не пройдено (SSR покрывает текст и `aria-expanded`)

## DoD

- [x] свёрнут — «Состав заказа >», `aria-expanded="false"`
- [x] открыт — «Состав заказа v», `aria-expanded="true"`
- [x] Review + CI green

---

# todo — TASK_84-PEEK-ONLY-EXT (доп.задача 1): статусная шторка только peek

| Поле | Значение |
|------|----------|
| **Основание** | [TASK_84-PEEK-ONLY-EXT](../milestones/veha_2/requirements/customer_tasks/TASK-84-PEEK-ONLY-EXT-Статусная-шторка-остаётся-в-peek-при-открытом-чеке.md) — сценарий владельца 2026-10-01 · вариант (а): CartSheet не поднимаем |
| **Реверсирует** | `expanded` статусной шторки при открытом чеке + Rails-тест «…EXPANDED» |
| **Статус** | REVIEW `[x]` · CI green [36825940981](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36825940981) на `f6f95987` · deploy запрещён |

## SBR

- [x] intake `c4f4bd0e`
- [x] RED `8f795504` — 3 fail: нет `ORDER_STATUS_SHEET_MODES.EXPANDED`, нет `.expanded` CSS/класса, есть `.receipt-open { overflow-y: auto }` без `max-height`; Rails `mount_acceptance` перевёрнут на `refute EXPANDED`
- [x] GREEN `8b75d868` — `OrderStatusSheet.svelte`: режим только hidden/peek, `class:receipt-open`, CSS `.expanded` удалён · Entire `01M3SBAXJXWA8X0DWT56SNEE36`
- [x] `/regress` PASS — JS 602 (60 fail = legacy baseline) · `vite build` OK · Rails 18 файлов (шторка, CartSheet b113_s2*, quick_repeat_section, catalog_hidden, active orders) 100/0
- [x] `/review` — bugbot 0 · security 0 · `/crit-audit` CLEAN (`44ec7814`) · push · CI + Semgrep + CodeQL green [36825940981](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36825940981)

## Файлы

- `app/frontend/components/OrderStatusSheet.svelte` — `receiptOpen` вместо `panelExpanded`; `statusSheetMode` без `EXPANDED`; `.oss__panel.receipt-open { overflow-y: auto }`
- `test/javascript/order_status_sheet_peek_only_test.mjs` — новый
- `test/integration/shop/order_status_sheet_mount_acceptance_test.rb` — `EXPANDED` → `refute`

## Не ломать

- чек (`ActiveOrdersAccordion`, `fitReceiptInView`, `receiptView`), `×` (уже удалён), polling/Cable, `lib/orderStatusSheet.js` (`ORDER_STATUS_SHEET_MODES` с `EXPANDED` остаётся)
- `CartSheet.svelte` и его `MODE_EXPANDED` (другой режим — шторка корзины)
- #42 высота peek `min(22vh, 8.5rem)`

## Проверка

- `node --test test/javascript/order_status_sheet_peek_only_test.mjs` — 5/0
- зона JS (`order_status*` `active_orders*` `cart_sheet*` `sticky*` `order_cancel*` `order_action*`) — 173/1 (legacy «422/500»)
- Rails `order_status_sheet_mount_acceptance`, `order_status_expanded_stack_canon`, `active_order_cart_peek_stack`, `api/active_orders_receipt` — 20/0
- браузер 390×844: peek 136px до/после клика, чек 101px внутри панели, `Total Amount` через scroll чека, панель не скроллится — [MEASURE](../milestones/veha_2/artifacts/active_orders_receipt_display_restore/peek_only_2026-10-01/MEASURE.md)

## DoD

- [x] открытие чека — `data-status-sheet-mode="peek"`, высота не растёт
- [x] чек внутри peek со своей прокруткой, `Total Amount` достижим
- [x] закрытие чека — peek
- [x] Review + CI green

---

# todo — TASK_83 Патч 1 (2026-09-30): убрать × из статусной шторки (patch v1)

| Поле | Значение |
|------|----------|
| **Основание** | [TASK_83 § Патч 1: 2026-09-30](../milestones/veha_2/requirements/customer_tasks/TASK-83-status-sheet-dismiss.md) — «Исправленный сценарий», Subtask 1, 4, 5, 6 (patch v1) |
| **Тип** | патч (не доп.задача) · остальные Subtask TASK_83 — контекст, не трогались |
| **Статус** | REVIEW `[x]` · CI green [36821953421](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36821953421) на `f2253be4` · deploy запрещён до закрытия задачи |

## SBR

- [x] SPEC — `dismissOrder` (lib) используется в `test/javascript/order_status_sheet_test.mjs` → **оставлен**; UI-цепочка `onDismissOrder` → `onDismiss` → `aoa__dismiss` после удаления кнопки мертва → убрана (Scope патча разрешает)
- [x] RED `f7a6dc49` — 4 fail: SSR «× нет в DOM», source «нет `status-widget-dismiss`/«Скрыть статус заказа»», «нет `aoa__dismiss`/`onDismiss`», «шторка не пробрасывает `onDismiss={onDismissOrder}`»
- [x] GREEN `93f500ee` — удалены кнопка `×`, проп `onDismiss`, CSS `.aoa__dismiss` (`ActiveOrdersAccordion.svelte`); проброс `onDismiss`, `onDismissOrder`, импорт `dismissOrder` (`OrderStatusSheet.svelte`) · Entire `01M3SBAXJXWA8X0DWT56SNEE36`
- [x] `/regress` PASS — JS 597 (60 fail = legacy baseline) · `vite build` OK · Rails active_orders(_receipt) + cart_peek_stack 13/0
- [x] `/review` — bugbot 0 · security 0 · `/crit-audit` CLEAN (`0b54ac21`) · push · CI сначала red: `scan_ruby` brakeman `--ensure-latest` (вышел 8.1.0, к патчу не относится) → bump `f2253be4` → CI + Semgrep + CodeQL green [36821953421](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36821953421)
- [ ] после Review: номера строк в TASK_83 и COMPONENT_MAP (`COMPONENT_MAP.md` в этой итерации только читался)
- [ ] deploy — **запрещён** до закрытия задачи; затем Fly MCP Point A

## Файлы

- `app/frontend/components/ActiveOrdersAccordion.svelte` — −кнопка `×`, −проп `onDismiss`, −CSS `.aoa__dismiss`
- `app/frontend/components/OrderStatusSheet.svelte` — −`onDismiss={onDismissOrder}`, −`onDismissOrder`, −импорт `dismissOrder`
- `test/javascript/active_orders_accordion_test.mjs` — тест «aria-label Скрыть» → SSR «× отсутствует, CTA чека и action buttons на месте»
- `test/javascript/order_status_notify_actions_test.mjs` — тесты наличия `×` → контракт отсутствия + тест проброса из шторки

## Не ломать

- блок чека и CTA (#84 / TASK_84-EXT): `receiptView`, `receiptPanelView`, fit/scroll чека, форма `accordionState`
- `dismissOrder` / `refreshMode` в `lib/orderStatusSheet.js` и их тесты (`order_status_sheet_test.mjs`)
- `OrderCancelModal` `onDismiss` (`OrderStatusSheet.svelte`), `OrderStatus.svelte` `onDismiss` — другой смысл, не трогались
- status / polling / ActionCable / reconnect / `OrderActionButtons` / cancel flow

## Проверка

- `node --test test/javascript/active_orders_accordion_test.mjs test/javascript/order_status_notify_actions_test.mjs` — 51/0
- зона (13 файлов `order_status*` `active_orders*` `cart_sheet*` `sticky*` `order_cancel*` `order_action*`) — 168/1; 1 fail `order_action_buttons_cancel_test` «422/500» — legacy, уже в ISSUES, падал и до патча
- Fly MCP Point A — после deploy по апруву

## DoD

- [x] Subtask 1: `×` нет в DOM статусной шторки
- [x] Subtask 4–5: status / polling / Cable / чек без изменений; мёртвый проброс `onDismiss` удалён, `dismissOrder` (lib) сохранён
- [x] Subtask 6: тесты на наличие `×` заменены контрактом отсутствия
- [x] Review + CI green

---

# todo — Патчи 2026-09-30: TASK_83 (убрать ×) + TASK_84-RECEIPT-DISPLAY-EXT (receipt runtime)

| Поле | Значение |
|------|----------|
| **Основание** | read-only аудит 2026-09-30 · классификация `/patch` |
| **Патч A** | [TASK_83 § Патч 1](../milestones/veha_2/requirements/customer_tasks/TASK-83-status-sheet-dismiss.md) — убрать `×` |
| **Патч B** | [TASK_84-RECEIPT-DISPLAY-EXT § Патч 1](../milestones/veha_2/requirements/customer_tasks/TASK-84-RECEIPT-DISPLAY-EXT-Восстановление-фактического-отображения-состава-чека-в-ActiveOrdersAccordion.md) — DOM-контракт receipt + внутренний scroll |
| **Доп.задачи (backlog)** | «только peek» · новые `>`/`v` · min Home Indicator (шторка / все экраны) — [DEMO_FEEDBACK](../milestones/veha_2/requirements/DEMO_FEEDBACK.md) |
| **Статус** | SPEC `[x]` · RED pending |

## SBR: SPEC → RED

- [x] SPEC — патчи оформлены
- [x] Патч B RED-попытка: SSR DOM-тесты (`svelte_ssr_helper.mjs` + 3 теста в `active_orders_accordion_test.mjs`) **сразу зелёные** — после `openOrderReceipt` HTML содержит `.aoa__receipt`, позицию, модификатор, `Total Amount`, inline `max-height: 350px; overflow-y: auto`, без `<button>`; только раскрытый заказ рендерит чек. Мутация `{#if false}` → 2 fail (тест не пустой). Стейт: `$state` proxy (`OrderStatusSheet.svelte:47`), `sync()` сохраняет раскрытый id (`:73–78`) — дефекта нет. **Вывод: рендер компонента исправен; RED не воспроизведён.**
- [x] Патч B — причина **доказана** в браузере ([MEASURE](../milestones/veha_2/artifacts/active_orders_receipt_display_restore/patch1_browser_2026-09-30/MEASURE.md)): 390×844, клик CTA → `.aoa__receipt` 196px в DOM, видно **61px**; режут `.oss__panel.embedded.expanded` 224px (`OrderStatusSheet.svelte:348–350`, чек на 145px ниже верха) и `CartSheet` `overflow:hidden` 287px. Внешняя панель скроллится (498 > 224) — Subtask 11 нарушен. Одной CSS-правки панели мало — режет `CartSheet` (вне scope)
- [x] Патч B — scope: вариант 1 (в аккордеоне, без `CartSheet`); подъём `CartSheet` при открытом чеке — кандидат в доп.задачу
- [x] Патч B RED `d237ed6d` — `fitReceiptInView` (замер 390×844) + source-контракт `overscroll-behavior: contain`
- [x] Патч B GREEN — `fitReceiptInView` + fit/scroll в `ActiveOrdersAccordion.svelte`; тесты 46/0, зона 134/0; браузер: чек виден целиком, Total Amount через свой scroll, внешняя панель не скроллится ([MEASURE](../milestones/veha_2/artifacts/active_orders_receipt_display_restore/patch1_browser_2026-09-30/MEASURE.md))
- [x] Патч B `/regress` PASS — JS 592 (60 fail = legacy baseline) · zone 134/0 · vite build · Rails active_orders_receipt 4/0
- [x] Патч B `/review`: bugbot → 2 раунда фиксов (transitionend refit + stale async guard `74b0dd48`; реальный отступ CTA→чек + ResizeObserver на CartSheet `0f06a868`) · security чисто · `/crit-audit` CLEAN · браузер: refit после анимации 101→171px, шторка −40px → 131px, низ по клипу
- [x] Патч B push `93d1dac` → CI green [36745691728](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36745691728) + Semgrep/CodeQL
- [ ] Патч B deploy по апруву → Fly MCP Point A
- [x] Патч A RED `f7a6dc49` / GREEN `93f500ee` — см. блок «TASK_83 Патч 1» выше

## Файлы (ожидаемо)

- `app/frontend/components/ActiveOrdersAccordion.svelte` — A: `aoa__dismiss` (190–202) · B: путь раскрытия (38–41, 78–80, 263–288) только по RED
- `app/frontend/components/OrderStatusSheet.svelte` — A: проп `onDismiss` (274), если мёртвый · B: `.oss__panel.embedded.expanded` (344–350) только если RED докажет обрезание
- `app/frontend/lib/activeOrdersAccordion.js` — B, только по RED
- `test/javascript/active_orders_accordion_test.mjs`, `test/javascript/order_status_notify_actions_test.mjs`
- `test/javascript/svelte_ssr_helper.mjs` (+1 путь: loader-хук компиляции `.svelte` для SSR)

## Не ломать

- A не трогает receipt; B не трогает `×`/dismiss; общий объект — `accordionState` (форму не менять)
- backend active-orders API, `OrdersController#active`, `ActiveOrdersPresenter`, polling, ActionCable, reconnect, push, wallet, cancel API, `OrderActionButtons`, cancel-modal
- `receiptView` — пока не доказано, что проблема в нём · chevron #36 · негативный тест #35 · Home Indicator / safe-area
- `COMPONENT_MAP.md` и номера строк в TASK_83 — только после Review

## Решение владельца 2026-09-30

- DOM-тест Патча B: **SSR** — `svelte/compiler` + `svelte/server` `render()` с `accordionState` после `openOrderReceipt` (путь через стейт, без клика); новых зависимостей нет.
- Ограничение: SSR не покрывает клик и не может проверить scroll-контракт (layout) → Subtask 11 проверяется визуально/Fly MCP после deploy; в отчёте GREEN указать явно.
- Порядок: **B → A**.

## Проверка

- `node --test test/javascript/active_orders_accordion_test.mjs test/javascript/order_status_notify_actions_test.mjs`
- зона: order status sheet / notify actions / accordion
- Fly MCP Point A — после deploy по апруву

## DoD

- [ ] B: DOM содержит `.aoa__receipt`, позицию, `Total Amount` после фактического раскрытия
- [ ] B: scroll только внутри receipt, внешняя панель без scroll
- [ ] A: `×` нет в DOM; status/polling/Cable без изменений; тесты на наличие `×` заменены позитивным контрактом отсутствия

---

# todo — TASK_99: iOS — системный диалог разрешения WebPush

| Поле | Значение |
|------|----------|
| **ID** | TASK_99 |
| **Google** | https://docs.google.com/document/d/1RFadqCs70QvUX2dFZmL98SEtPd1N5sGSEy-hNNrlVwU/edit (патчей/доп.задач нет) |
| **Ledger** | [GATES.md](../milestones/veha_2/artifacts/ios_webpush_permission/GATES.md) |
| **Статус** | REVIEW `[x]` · CI green · ждёт deploy (апрув) |

## SBR

- [x] /unlazy ledger (`def97615`)
- [x] RED `b016f7dc` — 9 новых тестов fail (порядок, sync requestPermission, denied/default/unsupported, аккордеон, статический импорт)
- [x] GREEN `48fa264` — 27/0 · G1–G3 PASS · Entire `01M3PPE93CDW728HQ2PP4ZNDM8`
- [x] /regress — JS 584: 60 fail legacy (= `def97615`, ISSUES) · Rails 19/0 · G1–G3 reverify
- [x] REVIEW — bugbot 0 · security 0 · CI green [36578386943](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578386943) на `180d88fc`
- [ ] deploy по апруву · G4 iPhone · G5 Fly

## Файлы (ожидаемо)

- `app/frontend/lib/firebasePush.js` — `requestPermission()` первым async; Firebase-проверки после `granted`; `opts.deps` для тестов (дефолт = реальные функции)
- `app/frontend/lib/orderStatusNotifyActions.js` — статический импорт `registerShopPush`
- `test/javascript/order_status_push_subscribe_test.mjs`

## Не ломать

- backend `OrderStatusPushNotifier` / `ReadyPushJob` / `FcmClient` · контракт `/push/register` · PassKit / `WALLET_SIMULATE` · SMS · `push_enabled`/`push_token`
- `getToken()` + регистрация после `granted` · остальная логика аккордеона

## Проверка

- `node --test test/javascript/order_status_push_subscribe_test.mjs` (ТЗ `npm test`/`typecheck` в репо нет)
- G3 зона: notify actions / init / accordion / SW / order status sheet
- физический iPhone + Fly MCP — после deploy по апруву

---

# todo — TASK_97: Push-оффер подписки

| Поле | Значение |
|------|----------|
| **ID** | TASK_97 · CBR #97 |
| **Док** | [TASK-97-Push-оффер-подписки.md](../milestones/veha_2/requirements/customer_tasks/TASK-97-Push-оффер-подписки.md) |
| **Google** | https://docs.google.com/document/d/1VN1VSBHuGtIjluoNFATbmAw0OsfL_UBqKnPho_fTtU4/edit?usp=drivesdk |
| **Ledger** | [GATES.md](../milestones/veha_2/artifacts/subscription_offer_push/GATES.md) |
| **Тип** | ⊂ TASK_96 Subtask 14–21 · реализация уже в `63a317a1` (GREEN #96) · остаток — concurrent idempotency + закрытие |
| **Статус** | REVIEW — bugbot 0 · security 0 · push/CI · G4 Fly после deploy |

## SBR

- [x] PHASE 0 intake (`a98bf595`)
- [x] /unlazy ledger — G1–G3 PASS, G4 Fly pending (`a79978d3`)
- [x] PHASE 1 SPEC
- [x] PHASE 2 RED — G5: `OfferPushNotifier.call` ×2 одним ключом → 2 push (`d798968b`); параллельный `mark_shown` уже был верен
- [x] PHASE 2 GREEN — advisory xact lock в `OfferPushNotifier#create_once` · 14/0 · `--reverify` G1–G3, G5 PASS
- [x] /regress — `--reverify` G1–G3, G5 · зона 28 файлов 176/0 · concurrent ×5 PASS
- [ ] PHASE 3 REVIEW — push/CI · deploy по апруву · G4 Fly

## Покрытие TASK_97 реализацией #96 (сверка SPEC)

| TASK_97 | Где сделано | Тест |
|---|---|---|
| Subtask 1 notifier через существующий FCM | `OfferPushNotifier` → `PushNotification` + `Shop::SendPushNotificationJob` | `offer_push_notifier_test` |
| Subtask 2 side-effect `not_shown → shown` | `OfferPresentationService#mark_shown` → `after_shown_transition` (после `with_lock`, т.е. после коммита) | то же |
| Subtask 3 `push_enabled_at = null` | guard в `OfferPushNotifier#call` | «push_enabled_at nil → no push» |
| Subtask 4 idempotency на переход | `transition_key = state.id:updated_at` + `already_sent?` по `payload->>'offer_transition_key'`; переход под row-lock | последовательные повторы · **concurrent — нет** |
| Subtask 5 повтор после 3 заказов | новый `updated_at` → новый ключ | «re-show after dismiss + 3 orders» |
| Subtask 6 `purchased` | `mark_shown` + `purchased?` в notifier | «purchased → no offer push» |
| Subtask 7 промо 11₽ | `should_show_banner` false → нет перехода | «GrowthPromo available» |
| Subtask 8 ошибка FCM | `rescue` в notifier + job `failed` без raise | 2 теста |
| Subtask 9 регрессия FCM | — | G3 (8 файлов) |
| Не ломать №10 COMPONENT_MAP | строка `OfferPushNotifier` уже есть (TASK_96) | — |

## Файлы (ожидаемо)

1. `test/services/subscriptions/offer_push_concurrency_test.rb` — **новый**: `use_transactional_tests = false` (транзакционные тесты шарят одно соединение → потоки сериализуются, как в `saved_card_store_test`), 4 потока `OfferPresentationService#mark_shown` одновременно → ровно 1 `push_notifications` `subscription_offer`, 1 `banner_shown`; второй кейс — 2 потока `OfferPushNotifier.call` с одним `transition_key` → 1 push. Teardown чистит свои записи (образец — `test/integration/pg_inventory_test.rb`).
2. `app/services/subscriptions/offer_push_notifier.rb` — **только если** второй кейс красный: `already_sent?` + `create!` не атомарны. Фикс без миграции — `transaction` + `pg_advisory_xact_lock(hashtext(transition_key))` вокруг проверки и создания.
3. `docs/operations/milestones/veha_2/artifacts/subscription_offer_push/GATES.md` — +G5 (concurrent-тест).
4. `docs/operations/session/COMPONENT_MAP.md` — строка `OfferPushNotifier`: владелец `TASK_96 · TASK_97` (без смены смысла).
5. `customer_tasks/TASK-97-Push-оффер-подписки.md` + CBR — статус закрытия со ссылкой на `63a317a1`.

Blast-radius (только читать, не менять): `app/services/subscriptions/offer_presentation_service.rb` (переход под `with_lock`), `app/jobs/shop/send_push_notification_job.rb` (доставка + `push_sent`).

## Решения SPEC (по умолчанию)

1. Реализацию #96 не переписываем — TASK_97 закрывается ей; новый код только если concurrent-тест упал.
2. Idempotency без миграции (partial unique index на `payload->>'offer_transition_key'` — только если advisory lock не хватит; тогда Migration Gate).
3. Текст push — как в #96 («Кофе по подписке» / «Оформите подписку и экономьте на каждом заказе»), подтверждение у заказчика — общий хвост #96.

## Не ломать

- push о статусе заказа + Cascade ready (`OrderStatusPushNotifier`, `ReadyPushJob`, `OrderReadyCascadeJob`)
- FCM registration flow / `push_enabled_at` (`push_register`)
- `OfferPresentationService` правила TASK_95 (dismiss / повтор после 3 заказов / purchased / промо 11₽) и `profile` флаги
- `SendPushNotificationJob` для не-offer push (без `marketing_events`)

## Проверка

```text
ruby bin/rails test test/services/subscriptions/offer_push_concurrency_test.rb test/services/subscriptions/offer_push_notifier_test.rb
node .agents/skills/unlazy/scripts/gate-check.mjs --reverify docs/operations/milestones/veha_2/artifacts/subscription_offer_push/GATES.md
```

---

# todo — TASK_96: Оффер подписки — frontend, push и аналитика

| Поле | Значение |
|------|----------|
| **ID** | TASK_96 · CBR #96 |
| **Док** | [TASK-96-Оффер-подписки-frontend-push-и-аналитика.md](../milestones/veha_2/requirements/customer_tasks/TASK-96-Оффер-подписки-frontend-push-и-аналитика.md) |
| **Google** | https://docs.google.com/document/d/1kbB0iDYgFoioln0I2xUXeMBXWaKo_cKqDEfproHJN1M/edit?usp=drivesdk |
| **Ledger** | [GATES.md](../milestones/veha_2/artifacts/subscription_offer_frontend_push_analytics/GATES.md) |
| **Тип** | новая фича поверх TASK_95 · полный SBR · **весь scope TASK_96 (Subtask 1–36)** |
| **Статус** | RED · владелец (2026-09-29 `/sbr`): делаем всё, кроме цели перехода — `OFFER_TARGET_PATH = "/profile"` до billing UI; G7/Subtask 35 открыты |

## SBR

- [x] PHASE 0 intake
- [x] /unlazy ledger (G5–G6 baseline PASS)
- [x] PHASE 1 SPEC
- [x] PHASE 2 RED — G1–G4 (Ruby 38 runs · 13 F · 25 E; JS — модуль отсутствует)
- [x] PHASE 2 GREEN — G1–G6 reverify PASS · соседи 80/0 · vite build OK
- [ ] /regress
- [ ] PHASE 3 REVIEW — push/CI · deploy по апруву · G7 Fly

## Блокер

- **Экран оформления подписки отсутствует во frontend.** В `App.svelte` нет `#/subscription…` / «Моя подписка»; есть только backend `POST /shop/api/subscriptions` (принимает `utm_campaign`, `utm_content`, `offer_channel`). Billing UI — зона Задачи-3 (Point A offer OFF «до billing UI»), своей задачи/CBR в репо нет.
- Зависят от него: Subtask 5, 26–27 (цель перехода), 30 (цель push deep link), 11 («Моя подписка»), 35 (E2E «переход в оформление»).
- Решение владельца (SPEC 2026-09-29): **TASK_96 ждёт billing UI**. Снятие блокера = появился роут экрана оформления → вписать путь в `subscriptionOffer.js` и стартовать `/sbr`.

## Пересечения (держим в уме, не делаем)

- TASK_97 (push-оффер) ⊂ Subtask 14–21; TASK_98 (воронка + UTM) ⊂ Subtask 22–33. TASK_96 делаем целиком; решения совместимы с их текстом (idempotency на переход в `shown`, а не на заказ/дату; атрибуция в `subscriptions.utm_*` из последнего `offer_opened`; ошибки аналитики/FCM не влияют на основной flow). Судьба TASK_97/98 — решает владелец.

## Решения SPEC (по умолчанию — подтвердить до RED)

1. **Точка показа баннера** — `OrderStatus.svelte` после блока прогресса (после L340, перед «Состав заказа»), только при `order.status === "ready"` + `should_show_banner` + профиль 200. Layout виджета статуса не меняется.
2. **`mark_shown` с фронта** — существующий `POST /shop/api/subscription_offer/shown` (TASK_95), один раз за монтирование экрана (флаг в модуле, по `order.id`).
3. **Флаги** — из `GET /shop/api/profile` (`should_show_banner`, `has_unread_offer_in_lk`); карточка ЛК показывается при `eligible_for_subscription_offer && !purchased`; purchased = есть активная подписка (`GET /shop/api/subscriptions/current` 200) → карточки нет.
4. **UTM** — `utm_campaign=subscription_offer`, `utm_content=<channel>_v1` (`banner_v1` / `lk_v1` / `push_v1`), `offer_channel ∈ Subscription::OFFER_CHANNELS` (`banner lk push`). Константа версии креатива — одна, в `subscriptionOffer.js`.
5. **`offer_opened` / `push_opened`** — новый `POST /shop/api/subscription_offer/opened` (`channel`, `utm_*`); frontend шлёт через `navigator.sendBeacon`, fallback `fetch(..., { keepalive: true })` без `await` перед навигацией.
6. **Idempotency push** — `OfferPresentationService#mark_shown` возвращает `true` только при фактическом переходе (под row-lock `with_state`); на переход создаётся ровно одно `banner_shown`, его `id` = idempotency-ключ push (`push_notifications.payload.offer_event_id`, проверка перед созданием). Повторный `shown` после 3 заказов → новое событие → новый push. Колонки в `subscription_offer_states` не добавляем.
7. **`OfferPushNotifier`** — как `Shop::OrderStatusPushNotifier`: `PushNotification` (`notification_type: "subscription_offer"`) + `Shop::SendPushNotificationJob` → `FcmClient`; только при `push_enabled_at` и `push_token`; `rescue StandardError` → log. `push_sent` пишет job после успешной доставки. Вызов — `after_commit`-безопасно (enqueue после транзакции состояния).
8. **Deep link push** — `data.offer_url` в payload; в `firebase_sw/show.js.erb` ветка `notificationclick`: `offer_url` → `openClient(offer_url)` **до** `if (!orderId) return` (order-ветки не трогаем).
9. **Атрибуция покупки** — в `Subscriptions::PaymentFulfillment` (единая точка активации, как `mark_purchased` в TASK_95): если UTM не пришли в покупке — берём из последнего `offer_opened` гостя; `subscription_purchased` пишется `rescue`-безопасно, покупка не откатывается. `PurchaseService` не трогаем.
10. **`marketing_events`** — без RLS (как `subscriptions` / `subscription_offer_states`, customer-scoped), `point_id` = tenant точки; запись только через `Subscriptions::MarketingEventLogger` (never raises). Индексы: `(point_id, occurred_at)`, `(customer_id, event_type, occurred_at)`.
11. **Отчёт воронки** — `Subscriptions::OfferFunnelReport` (group by `event_type, channel` за `from..to`, фильтр `point_id = Current.tenant_id`) + JSON `GET /manager/subscription_offer_funnel` (manager namespace, без UI).
12. **Шаблон push** — title «Кофе по подписке», body «Оформите подписку и экономьте на каждом заказе» (заглушка — текст подтвердить у заказчика).
13. **§5 ТЗ** — `npx tsc --noEmit` не применим (Svelte/JS) → `node --test`; E2E-раннера в репо нет → Subtask 35 = Fly MCP browser на Point A (G7).

## Файлы (ожидаемо)

Полный scope (36 Subtask) — больше 7 путей; сгруппировано по блокам.

**Frontend (G1)**
1. `app/frontend/lib/subscriptionOffer.js` — новый чистый модуль: `bannerVisible({ order, profile })`, `lkCardView(profile, subscription)`, `buildOfferLink(channel)`, `markShownOnce/dismiss/markViewed`, `trackOfferOpened` (sendBeacon). Весь тестируемый код здесь.
2. `app/frontend/components/SubscriptionOfferBanner.svelte` — новый: баннер, свайп/крестик → локальное скрытие + dismiss, клик → `trackOfferOpened` + переход.
3. `app/frontend/components/SubscriptionOfferCard.svelte` — новый: карточка ЛК + unread-индикатор, раскрытие → viewed (оптимистично), клик → переход.
4. `app/frontend/routes/OrderStatus.svelte` — только точка монтирования баннера после L340.
5. `app/frontend/routes/Profile.svelte` — только подключение карточки после `<PlgBlockSection />`.

**Push (G2)**
6. `app/services/subscriptions/offer_push_notifier.rb` — новый.
7. `app/services/subscriptions/offer_presentation_service.rb` — `mark_shown` → bool + side-effect `banner_shown` + notifier (без смены правил).
8. `app/views/shop/firebase_sw/show.js.erb` — ветка `offer_url` в `notificationclick`.
9. `app/jobs/shop/send_push_notification_job.rb` — после успешной доставки `subscription_offer` → `push_sent`.

**Аналитика (G3–G4)**
10. `db/migrate/2026XXXX_create_marketing_events.rb` + `app/models/marketing_event.rb` — `enum :event_type` (7 значений, string).
11. `app/services/subscriptions/marketing_event_logger.rb` — единая безопасная запись.
12. `app/controllers/shop/api/subscription_offers_controller.rb` + `config/routes.rb` — события в dismiss/viewed + `POST subscription_offer/opened`.
13. `app/services/subscriptions/payment_fulfillment.rb` — `subscription_purchased` + атрибуция из последнего `offer_opened`.
14. `app/services/subscriptions/offer_funnel_report.rb` + `app/controllers/manager/subscription_offer_funnel_controller.rb` — отчёт.

**Тесты (G1–G4)**
- `test/javascript/subscription_offer_banner_test.mjs` · `test/javascript/subscription_offer_card_test.mjs`
- `test/services/subscriptions/offer_push_notifier_test.rb`
- `test/models/marketing_event_test.rb` · `test/integration/shop/api/subscription_offer_marketing_events_test.rb`
- `test/integration/shop/subscription_offer_funnel_test.rb`

**Docs:** `docs/integrations/shop-api.md` (`opened`) · `docs/integrations/pwa-realtime.md` (offer push) · `docs/operations/session/COMPONENT_MAP.md` (4 новых компонента).

Blast-radius (только чтение/регрессия):
- `app/services/shop/order_status_push_notifier.rb` + `app/services/shop/fcm_client.rb` — образец и общий транспорт; не менять.
- `app/frontend/lib/orderStatusCtaMachine.js` / `subscriptionOfferCta.js` — существующий CTA подписки на статусе; не менять (баннер — отдельный канал).
- `app/services/subscriptions/purchase_service.rb` — вызывает `PaymentFulfillment`; регрессия G5.

## Не ломать

- Статус заказа: layout `OrderStatus.svelte`, `orderStatusCtaMachine.js`, CTA на `ready`, шторка `ActiveOrdersAccordion` / `OrderStatusSheet`, Cable-статусы.
- Push о статусе заказа: `OrderStatusPushNotifier`, Cascade ready, FCM registration + `push_enabled_at`, `notificationclick` для `order_id` (chat/tips/cancel).
- Оплата подписки: `PurchaseService` / `PaymentFulfillment` идемпотентность (повторный webhook → тот же `Subscription`, без второго `subscription_purchased`), `Payments::TbankAdapter`.
- ЛК: история + «Повторить» (TASK_94), PLG-слоты; состояние оффера TASK_95 (`shown/dismiss/viewed` API, флаги профиля).

## Проверка

```bash
node --test test/javascript/subscription_offer_banner_test.mjs test/javascript/subscription_offer_card_test.mjs test/javascript/order_status_cta_machine_test.mjs test/javascript/order_status_sheet_test.mjs test/javascript/lk_history_repeat_one_click_test.mjs
bin/rails test test/services/subscriptions/offer_push_notifier_test.rb test/models/marketing_event_test.rb test/integration/shop/api/subscription_offer_marketing_events_test.rb test/integration/shop/subscription_offer_funnel_test.rb test/services/subscriptions/ test/integration/shop/api/subscription_offer_state_api_test.rb test/services/shop/order_status_push_notifier_test.rb test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb
```

Fly MCP Point A (G7, после deploy): статус `ready` → баннер · dismiss · карточка ЛК + unread гаснет · переход в оформление с UTM · витрина/корзина/статус PASS.

## DoD

- [x] Subtask 1–13: баннер + карточка ЛК + error-path (G1) — цель перехода `#/profile` до billing UI
- [x] Subtask 14–21: `OfferPushNotifier` + idempotency (G2)
- [x] Subtask 22–30: `marketing_events` + события (G3)
- [x] Subtask 31–33: атрибуция покупки + отчёт (G4)
- [x] Subtask 34, 36: unit + регрессия (G1, G5–G6)
- [ ] Subtask 35: E2E на Fly (G7) — после deploy; «переход в оформление» — после billing UI
- [x] Docs integrations + COMPONENT_MAP

---

# todo — TASK_95: Состояние оффера подписки на гостя

| Поле | Значение |
|------|----------|
| **ID** | TASK_95 · CBR #95 |
| **Док** | [TASK-95-Состояние-оффера-подписки-на-гостя.md](../milestones/veha_2/requirements/customer_tasks/TASK-95-Состояние-оффера-подписки-на-гостя.md) |
| **Google** | https://docs.google.com/document/d/18f25SUyeTWwixkcDX9XvTedfkd8GzSO6lfjoCTNWzPA/edit?usp=drivesdk |
| **Ledger** | [GATES.md](../milestones/veha_2/artifacts/subscription_offer_guest_state/GATES.md) |
| **Тип** | новая фича · полный SBR |
| **Статус** | SPEC `[x]` · ждёт `/sbr` (RED) |

## SBR

- [x] PHASE 0 intake
- [x] /unlazy ledger (G5–G6 baseline PASS)
- [x] PHASE 1 SPEC
- [x] PHASE 2 RED — тесты G1–G4 (`a88558cb`: 32 runs · 4 F · 28 E)
- [x] PHASE 2 GREEN — код (32/0 · G1–G6 reverify PASS · subscriptions 37/0)
- [x] /regress — 190/0 (TASK_95 32 · подписки/промо/профиль 92 · T-Bank callback 50 · RLS 16)
- [x] PHASE 3 REVIEW — bugbot (2 бага → fix `bb64f742`) + security чисто · Local 194/0 · Entire · push/CI
- [ ] deploy по апруву · G7 Fly MCP Point A

## Решения SPEC (по умолчанию — подтвердить до RED)

Ответ на вопросы не получен → взяты рекомендованные варианты:

1. **`profile/config` из ТЗ = `GET /shop/api/profile`.** `/shop/api/config` — tenant-level без гостя; флаги гостя кладём рядом с `eligible_for_subscription_offer`.
2. **Добавить `POST /shop/api/subscription_offer/shown`.** В ТЗ нет точки для `mark_shown` (Subtask 8 «баннер отрендерен frontend»), без неё `dismiss` недостижим. Пробел ТЗ → сообщить заказчику.
3. **`mark_purchased` — в `Subscriptions::PaymentFulfillment`**, а не в `PurchaseService`: fulfillment — единая точка активации (sync-charge и webhook redirect/СБП). `PurchaseService` не трогаем вовсе.
4. **Завершённые заказы — на текущей точке** (`SubscriptionOfferEligibility#completed_orders_count`, под RLS). Без обхода RLS.

Прочее:
- `subscription_offer_states` — **без RLS**, как `subscriptions` / `mobile_customers` (глобальные, customer-scoped): «purchased на любой точке сети» работает без обхода. Доступ — только по `customer_id` из серверной сессии.
- Промо 11₽: `SubscriptionOfferEligibility.check` уже возвращает false при `GrowthPromo.available?`; сервис всё равно явно проверяет `GrowthPromo.available?` первым (Subtask 5, явный приоритет в тестах).
- `should_show_push` = `should_show_banner` (сервис возвращает, в API не отдаём — push frontend чужая задача).
- «Гость достиг `ready`» — backend-хука в статус не добавляем: frontend на `ready` запрашивает профиль, флаг уже вычислен (`orderStatusCtaMachine.js` не трогаем).
- §5 ТЗ `npx tsc --noEmit` — не применим (Rails backend, frontend не меняется) → `bin/rails test`.

## Файлы (ожидаемо)

1. `db/migrate/20260929120000_create_subscription_offer_states.rb` — таблица: `customer_id` (uuid, unique index, FK `mobile_customers`), `status` (string, default `not_shown`), `first_shown_at`, `last_dismissed_at`, `completed_orders_count_at_dismissal` (int), `unread_since`, timestamps. Subtask 1.
2. `app/models/subscription_offer_state.rb` — `enum :status, { not_shown:, shown:, dismissed:, viewed_in_lk:, purchased: }` (string), `for_customer!` = find-or-create с rescue `RecordNotUnique`. Subtask 2–3.
3. `app/services/subscriptions/offer_presentation_service.rb` — `call` → `{ should_show_banner:, should_show_push:, has_unread_offer_in_lk: }`; `mark_shown` / `mark_dismissed` / `mark_viewed_in_lk` / `mark_purchased` (идемпотентные, с блокировкой строки). Subtask 4–17.
4. `app/controllers/shop/api/subscription_offers_controller.rb` — `shown` / `dismiss` / `viewed`; `require_customer!` как в `SubscriptionsController` (401 «Требуется авторизация»); только вызов сервиса. Subtask 19–22.
5. `config/routes.rb` — 3 POST в `shop/api` рядом с `subscriptions/*`.
6. `app/controllers/shop/api/profile_controller.rb` — +`should_show_banner`, `has_unread_offer_in_lk` в `profile_json` через сервис. Subtask 18.
7. `app/services/subscriptions/payment_fulfillment.rb` — после `subscription.save!` → `mark_purchased` (в той же транзакции вызывающего). Subtask 16.

Тесты (G1–G4) и docs:
- `test/models/subscription_offer_state_test.rb` · `test/services/subscriptions/offer_presentation_service_test.rb` · `test/integration/shop/api/subscription_offer_state_api_test.rb` · `test/integration/shop/subscription_offer_lifecycle_test.rb`
- `docs/integrations/shop-api.md` · `docs/integrations/pwa-realtime.md` · `docs/operations/session/COMPONENT_MAP.md` (Subtask 26–28)

Blast-radius (соседи, только чтение/регрессия):
- `app/services/shop/subscription_offer_eligibility.rb` — вход сервиса; запрещено менять.
- `app/services/payments/growth_promo.rb` — `available?` только читаем.
- `app/services/subscriptions/purchase_service.rb` — вызывает `PaymentFulfillment` в sync-charge; регрессия G6.

## Не ломать

- Оплата подписки: `PurchaseService` / `PaymentFulfillment` идемпотентность (повторный webhook → тот же `Subscription`, без второго `mark_purchased`-эффекта), `Payments::TbankAdapter`.
- Промо 11₽ / `GrowthPromo` / `SubscriptionOfferEligibility` / `subscription_offer_settings` — без изменений логики.
- Статус/табло: `orderStatusCtaMachine.js` и CTA на `ready` — не трогаем; `GET /shop/api/config` — контракт без изменений.
- `GET /shop/api/profile` — существующие поля и `orders_count` / `eligible_for_subscription_offer` не меняются; добавляются только 2 поля.

## Проверка

```bash
bin/rails test test/models/subscription_offer_state_test.rb test/services/subscriptions/offer_presentation_service_test.rb test/integration/shop/api/subscription_offer_state_api_test.rb test/integration/shop/subscription_offer_lifecycle_test.rb
bin/rails test test/services/shop/subscription_offer_eligibility_test.rb test/services/payments/growth_promo_test.rb test/integration/shop/api/profile_subscription_offer_test.rb test/services/subscriptions/ test/integration/shop/api/subscriptions_api_test.rb
```

Fly MCP Point A (G7, после deploy): `GET /shop/api/profile` отдаёт 2 флага · `POST subscription_offer/*` без сессии → 401 · витрина/корзина PASS.

## DoD

- [x] Subtask 1–3: таблица + модель + одна запись на гостя (G1)
- [x] Subtask 4–17: сервис + переходы + промо-приоритет + 3 заказа + unread + purchased (G2)
- [x] Subtask 18–22: профиль + shown/dismiss/viewed + 401 (G3)
- [x] Subtask 23–24: lifecycle + промо-приоритет e2e (G4)
- [x] Subtask 25: регрессия G5–G6
- [x] Subtask 26–28: docs integrations + COMPONENT_MAP
- [ ] G7 Fly MCP Point A (после deploy по апруву)
