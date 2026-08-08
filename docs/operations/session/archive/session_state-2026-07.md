# Архив session_state — 2026-07

> Перенесено из `docs/operations/session/SESSION_STATE.md`.
> Агент: читать только по явному запросу про этот месяц.

### Сессия 2026-07-31 (push/deploy/MCP · Status inside cart sheet)

- Push `876b5432` · `fly deploy` → **v418** · build `prog36`
- MCP: status parent=`shop-cart-sheet`, `embedded=true`, `position=relative` z=auto (не fixed overlay)
- Evidence: `artifacts/status_inside_cart_sheet/mcp/fly_v418/`

### Сессия 2026-07-31 (Status inside cart sheet GREEN)

- Фидбек: «вписать в шторку, не слой сверху»
- Mount: `OrderStatusSheet` → внутри `CartSheet` после gesture; убран из `App.svelte`
- CSS `embedded`: `position:relative`, без z-60 overlay / отдельной «второй шторки»
- Тесты: mount 5/5; JS 18+4 PASS; build marker `CART_SHEET_BUILD=prog36`
- MCP/deploy — ждут явный апрув

### Сессия 2026-07-31 (push + fly deploy + MCP · Quick Repeat v417)

- Push `develop` → `6fa90731`; `fly deploy --remote-only` → **v417**
- MCP Point A (Aram, 14 active): sheet `390/390` left/right 0 z60; `shop-repeat-section` absent
- Modes: peek → expanded; one-open PASS (2nd open closes 1st)
- Evidence: `artifacts/quick_repeat_bottom_sheet/mcp/fly_v417/`
- Prior v416 evidence retained under `mcp/fly_v416_2026-07-31/`

### Сессия 2026-07-31 (push + fly deploy + MCP · Quick Repeat v416)

- Push `develop` → `0b71d5f9`; `fly deploy --remote-only --depot=false` → **v416**
- MCP Point A (Aram, active orders): API `has_active_order:true` + `frequent_items:[]`; UI без «повторить»
- Status sheet: `css left/right 0`, `width=390=vw`, `z=60` (vs feedback 07)
- Evidence: `artifacts/quick_repeat_bottom_sheet/mcp/fly_v416_2026-07-31/`
- SKIP: канон 01–06 со видимым повтором — залипшие active (#36 demo)

### Сессия 2026-07-31 (MCP local · feedback 07)

- Deterministic CDP stub: 2 active orders + stale frequent item при `has_active_order=true`.
- Peek: sheet `390/390`, `left=0`, repeat отсутствует; expanded: один receipt.
- После открытия №2: №1 closed, №2 open, receipts=1; после `orders=[]` status sheet hidden.
- Скрины/evidence: `artifacts/quick_repeat_bottom_sheet/mcp/local_feedback_07/`.
- Fly не менялся: push/deploy — только после явной команды владельца.

### Сессия 2026-07-31 (PHASE 3 REVIEW · Quick Repeat)

- Suite: Rails **89/89** + JS **18/18**; rubocop 3 Ruby files clean
- Sanity: N+1 PASS (exists? + flat plucks + index_by); RLS PASS (tenant scoped); no DDL
- File-size: service 173 (warn); store 118 OK; OrderStatusSheet 183 (warn); CartSheet 626 / RepeatSection 253 — legacy, не раздували
- Full-width: `OrderStatusSheet` left/right 0, width 100%, z60
- MCP Fly / `[x]` заказчика — после deploy-апрува

### Сессия 2026-07-31 (PHASE 2 GREEN · Quick Repeat F1–F3)

- FE: `hasActiveOrder` store; `applyFrequentPayload` clear items; CartSheet `showRepeat`; `applyCableEvent` onTerminal → `refreshFrequentProducts`
- Регрессия: 89 Rails + 18 JS — 0 failures
- CHANGELOG/HANDOFF — в REVIEW

### Сессия 2026-07-31 (PHASE 2 RED · Quick Repeat F1–F3)

- F1: store `hasActiveOrder` + clear items; F2: CartSheet gate; F3: OrderStatusSheet refresh + `applyCableEvent` onTerminal
- Rails: 13 runs, 2 failures (ожидаемо); node: 4 tests, 2 fail (ожидаемо)
- Код реализации не писали; CHANGELOG/HANDOFF не трогали
- Коммит: `5493de99`

### Сессия 2026-07-31 (PHASE 0/SPEC addendum · feedback 07)

- Сохранён скрин заказчика `07_customer_feedback_status_sheet_not_full_width_2026-07-31.png`.
- Root cause: `OrderStatusSheet` с `right: 7.5rem` / `max-width: 24.5rem` создаёт узкую колонку поверх CartSheet.
- Канон: Quick Repeat скрыт при active во всех `hidden/peek/expanded`; status sheet = full viewport width; modes status = hidden/no orders, peek/collapsed, expanded/one receipt.
- Баг записан в `ISSUES.md`; следующий substep — FE/layout RED, затем GREEN до MCP.

### Сессия 2026-07-31 (PHASE 2 GREEN · Quick Repeat B1–B4)

- BE: `HIDE_REPEAT_STATUSES`, `payload`/`cached_payload`, cache `shop/freq/v3/…`
- API: `has_active_order` + empty `frequent_items` when active
- Bust: `Barista::OrderStatusUpdateService` → `bust_cache!`
- Тесты: 45 runs / 0 failures (frequent* + guest restore + email link + barista status)
- Legacy seeds: history = `issued` (не `accepted`)
- CHANGELOG/HANDOFF — в REVIEW / после F*

### Сессия 2026-07-31 (PHASE 2 RED · Quick Repeat B1–B4)

- Тесты: service (HIDE + active→[]) · API `has_active_order` · cache v3 Hash · barista bust issued/cancelled
- `bundle exec rails test` …frequent* — **37 runs, 9 failures, 1 error** (намеренный RED)
- Код реализации не писали; CHANGELOG/HANDOFF не трогали (RED-substep)

### Сессия 2026-07-31 (PHASE 1 SPEC · Quick Repeat ревизия)

- Reuse: `CustomerFrequentProductsService`, `GET frequent_products`, CartSheet/RepeatSection, cache bust OrderCreator+PaymentUpdater
- NEW gaps: `HIDE_REPEAT_STATUSES` = `accepted/preparing/ready` (= `Order.active`); API `has_active_order`; cache **v3**; bust barista status; FE clear+hide
- Решение: `pending_payment` **не** скрывает повтор (иначе peek без #35 и без секции)
- Не rewrite шагов 2/9/12 ТЗ — уже в коде; фокус ревизии = active-order gate + UI канон скринов
- Код не писали; RED ждёт намерения

### Сессия 2026-07-31 (PHASE 0 · Quick Repeat ревизия)

- Переделка существующей задачи (не новый док): ТЗ обновлён 1:1 + **NEW** `has_active_order` / hide «повторить»
- Скрины канона заменены (6 PNG `*_2026-07-31.png`); старые → `_archive_2026-07-21/`
- CBR / customer_tasks README: статус **ревизия интейк `[x]`** · SPEC ждёт go
- Код / `todo.md` — не трогали (PHASE 0 only)

### Сессия 2026-07-31 (push/deploy/MCP · #36)

- `git push` develop → `cdab89ee`; `fly deploy` → **v415**
- MCP: 01 expanded text receipt · 02 one-open (first closes) · labels/z60/350px
- Evidence: `artifacts/active_orders_accordion_receipt/mcp/`
- Cable «Потеряно соединение…» при 14 orders — note, не блокер чека

### Сессия 2026-07-31 (PHASE 3 REVIEW · #36)

- Suite: Rails receipt 4 + active 2 + mount 5 = **11/11**; JS **27/27**; rubocop presenter clean
- Sanity: N+1 PASS (`includes(:order_items)`); RLS/tenant PASS; cart untouched; receipt text-only; one-expanded; #35 peek preserved
- P2 backlog PRACTICES: ACCORDION-SPLIT (~240 lines), STATUS-CTA-COPY
- Rubocop offenses в `orders_controller` history — pre-existing, не #36
- MCP Fly / `[x]` заказчика — после deploy-апрува

### Сессия 2026-07-31 (PHASE 2 GREEN · #36)

- BE: `Shop::ActiveOrdersPresenter` + `#active` includes items/mods/totals/sales_point
- FE: `activeOrdersAccordion.js` + `ActiveOrdersAccordion.svelte` в `OrderStatusSheet`
- Тесты: Rails receipt+active+mount **11/11**; JS accordion+sheet **27/27**; cart_service зона **30/30**; vite build PASS
- Регрессия focused shop api/mount/cart — PASS
- CHANGELOG/HANDOFF полный — в REVIEW

### Сессия 2026-07-31 (PHASE 2 RED · #36)

- Rails: `active_orders_receipt_test.rb` — 4 runs, 4 failures (нет created_at/items/discount) — ожидаемо
- JS: `active_orders_accordion_test.mjs` — MODULE_NOT_FOUND `activeOrdersAccordion.js` — ожидаемо
- Код реализации не писали; CHANGELOG/HANDOFF не трогали (RED-substep)

### Сессия 2026-07-31 (SPEC ревизия · #36)

- Заказчик убрал «Повторить» / POST repeat: scope = **просмотр состава чека** (read-only)
- ТЗ переименован; артефакты → `active_orders_accordion_receipt/`; скрины заменены (1 / 2 заказа)
- A1: + subtotal/discount/total_amount; A2: modifiers name+price; B1–B5 accordion + text receipt
- `todo.md` переписан; код не писали; RED ждёт намерения

### Сессия 2026-07-31 (PHASE 1 SPEC · #36)

- Reuse: `#active` (#35), `OrderStatusSheet` peek, `CartService#add!`, `ProductTenantSetting.available`, `orderStatusProgress`
- Gaps: enrich active (items/sales_point/created_at); `POST …/repeat` + OrderRepeatService; FE accordion expanded + «Повторить»
- Решения: 404 вместо 403 (как show); optional `product_id` для per-line; не второй sticky — extend #35; без DDL
- `todo.md` переписан под #36; код не писали
- RED ждёт намерения

### Сессия 2026-07-31 (PHASE 0 · #36 Active orders accordion + repeat)

- Интейк заказчика: expanded-аккордеон активных заказов (чек + «Повторить»), multi-order
- ТЗ: `customer_tasks/Мульти-статусная шторка активных заказов с повторной покупкой.md`
- Артефакты: `artifacts/active_orders_accordion_repeat/` — 2 скрина (канон приёмки UI)
- CBR: backlog + индекс #36 · статус **интейк `[x]`** · SPEC ждёт go
- Код / todo.md — не трогали (PHASE 0 only)
- Связь: #35 compact sticky peek `[x]`; эта задача — expanded accordion + repeat из чека

### Сессия 2026-07-31 (push/deploy/MCP · #35)

- `git push` develop → `3bbd62a8`; `fly deploy` → **v414**
- MCP: labels Принят/Оплачен/Готовится/Готов · track/fill · sheet z60 рядом с cart
- Evidence: `artifacts/order_status_compact_sheet_push/mcp/`
- ISSUES #35 layering — **resolved**
- Product route иногда skeleton (slow overlay) — PARTIAL, не блокирует статус

### Сессия 2026-07-31 (MCP Fly · #35 · pre-deploy)

- FAIL vs канон: CartSheet `z=50` скрывала OrderStatusSheet `z=40`; reconnect loop
- Local fix + tests PASS → затем push/deploy выше

### Сессия 2026-07-31 (PHASE 3 REVIEW · #35)

- Suite #35: Rails **34/34** + JS **14/14** PASS; rubocop new Wallet/job files clean
- Sanity: N+1 clean; `orders/active` tenant+customer OK; claim atomic OK
- Fix REVIEW: `applyCableEvent` снимает issued/cancelled/closed со шторки
- Backlog PRACTICES: V2-#35-WALLET-PROD, PUSH-RELIABILITY, ORDERS-CTRL-SPLIT
- MCP Fly / `[x]` заказчика — ждут deploy
### Сессия 2026-07-31 (PHASE 2 GREEN B3 · #35)

- `Shop::ReadyPushJob`: PassUpdater → FCM; Unavailable → FCM-only; GenerationError → retry
- DDL `order_wallet_passes`; AppleWallet Config/PassBuilder/ApnsClient (`WALLET_SIMULATE`)
- Notifier ready → ReadyPushJob (после claim)
- Тесты: ready_push_job + claim + notifier + barista **17/17 PASS**
- Runbook: `runbooks/APPLE_WALLET_ORDER_PASS.md`
- Backlog: реальный PKCS7 + APNs devices + download UI
### Сессия 2026-07-31 (PHASE 2 GREEN A1–A3 · #35)

- A1: `order_number` в GuestOrderBroadcaster; cable forwards order_id/order_number
- A2: `orderStatusSheet.js` + `OrderStatusSheet.svelte` (peek, pointer-events) + App mount
- A2b: scroll if >2 orders
- A3: `GET /shop/api/orders/active` + refresh on reconnect/online
- Тесты: JS 13/13 · Rails A1/A3/mount+channel 12/12 PASS
- Note: b11_02 CBR (Checkout `push(/order/)`) — pre-existing fail, не из #35
### Сессия 2026-07-31 (PHASE 2 GREEN C1 · #35)

- DDL: `orders.ready_notified_at` (timestamptz, nullable)
- `Shop::ReadyPushClaim.claim!` — atomic UPDATE WHERE NULL
- `OrderStatusPushNotifier`: на `ready` claim перед enqueue; повторный skip
- Тесты: ready_push_claim + order_status_push_notifier **9 runs / 0 fail**
- Откат: `remove_column :orders, :ready_notified_at`
### Сессия 2026-07-31 (PHASE 2 RED · #35)

- RED тесты: sheet contract (order_number), ReadyPushClaim, orders/active, OrderStatusSheet mount, orderStatusSheet.js
- Rails: 10 runs, 6 fail + 3 error (ожидаемо); JS: MODULE_NOT_FOUND orderStatusSheet.js
- Код реализации не писали; CHANGELOG/HANDOFF не трогали (RED-substep)
### Сессия 2026-07-31 (PHASE 1 SPEC · #35)

- Reuse: `Shop::GuestOrderChannel` + `GuestOrderBroadcaster` + `orderStatusProgress.js` + FCM push (Solid Queue)
- Gaps: sticky `OrderStatusSheet` (home+product), multi>2 scroll, reconnect GET, `ready_notified_at` (Migration Gate), Wallet backlog
- Не создавать параллельный OrderStatusChannel; CartSheet не раздувать; FSM ready→preparing не открывать
- `todo.md` переписан под #35; код не писали
- RED ждёт намерения
### Сессия 2026-07-31 (PHASE 0 · #35 Order status compact sheet + Push)

- Интейк заказчика: сквозная sticky-шторка статуса (peek/hidden) + ActionCable + Push/Wallet из POS
- ТЗ: `customer_tasks/Интеграция статусной модели в компактную шторку PWA и Push.md`
- Артефакты: `artifacts/order_status_compact_sheet_push/` — 5 скринов (канон приёмки UI)
- CBR: backlog + индекс #35 · статус **интейк `[x]`** · SPEC ждёт go
- Код / todo.md — не трогали (PHASE 0 only)
- Связь: B1.1 full-screen статус `[x]`; эта задача — компактная шторка поверх каталога

### Сессия 2026-07-30 (MCP Fly · #34 SBP Autopay)

- Чекбокс «Привязать счет…» + `save_sbp_account:true` → **422 error 3013** Recurrent недоступны
- Ручной СБП без bind → NSPK QR PASS (`4094633d…`)
- Карта one_click → **422 error 10** Charge заблокирован
- `has_sbp_account=false`; Zero-Click / CHARGE_DECLINED live — BLOCKED
- Артефакт: `artifacts/tbank_sbp_autopayments_account_token/mcp_fly_sbp_autopay_2026-07-30.json`

### Сессия 2026-07-30 (#34 Checkout UI)

- API `sbp_accounts` в user/cards; sheet + Checkout wiring
- Zero-Click charge + CHARGE_DECLINED → manual init; toast SERVICE_UNAVAILABLE
- Тесты: user_cards_sbp 2/2 · JS checkout UI 8/8 · shop_sbp_* 32/32

### Сессия 2026-07-30 (PHASE 3 REVIEW · #34)

- Security: mismatch session/order → 404; token только от order.customer_id
- Settle: PaymentStatusUpdater после ChargeQr; with_lock
- Тест mismatch + #34 suite PASS
- Backlog: Checkout checkbox/default UI; full charge idempotency key; live MCP

### Сессия 2026-07-30 (PHASE 2 GREEN · #34)

- BE: `TbankSbpAutopay`, `SbpAccountTokenStore`, `SbpAccountTokenFromWebhook`, `SbpAutopayChargeService`
- BE: `SbpPaymentInitiator` + `save_sbp_account`; route `POST sbp/charge`; callback RequestKey
- FE: `shopSbpAutopay.js` FSM + toasts
- Тесты #34: 21/21 Ruby + 10/10 JS PASS
- Регрессия оплаты: 70 runs / 0 fail / 2 skip PASS
- Checkout checkbox UI — не вшивали в route (helpers готовы); backlog REVIEW
- Live MCP blocked терминалом (#32)

### Сессия 2026-07-30 (PHASE 2 RED · #34)

- RED тесты: TbankSbpAutopay, SbpAccountTokenStore, FromWebhook, initiator save_sbp_account, sbp/charge API, shopSbpAutopay.js FSM
- Падения ожидаемы (NameError / no route / ArgumentError / MODULE_NOT_FOUND)
- GREEN ждёт намерения

### Сессия 2026-07-30 (PHASE 1 SPEC · #34)

- SPEC: reuse MPM `payment_type=sbp` + `card_token` как AccountToken; API `sbp/init` + новый `sbp/charge`
- Gaps: `GetAddAccountQRState`, `ChargeQr`, RequestKey idempotency, checkbox, Zero-Click UI, CHARGE_DECLINED fallback
- `tbank_adapter.rb` ~260 — новые методы в отдельный сервис (не раздувать)
- Live MCP blocked тем же терминалом, что #32 (пока нет Charge/Recurrent в ЛК)
- Код не писали

### Сессия 2026-07-30 (PHASE 0 · #34 T-Kassa SBP Autopay)

- Интейк заказчика: Zero-Click checkout через `AccountToken` + `GetAddAccountQRState` / `ChargeQr`
- ТЗ: `customer_tasks/Интеграция Автоплатежей СБП Т-Касса в PWA.md`
- Артефакты: `artifacts/tbank_sbp_autopayments_account_token/`
- CBR: строка backlog + индекс #34 · статус **интейк `[x]`** · SPEC ждёт go
- Код / todo.md — не трогали (PHASE 0 only)

### Сессия 2026-07-30 (MCP SUCCESS attempt · Charge blocked)

- Deploy `c9e68271` (charge_recurrent + settle CONFIRMED) — Fly PASS
- BE на машине: `settle_confirmed!` в WidgetPaymentInitiator
- MCP Point A / Aram: order `5514597d…` + primary MIR *5953 → widget_init **422 error_code 10**
- Fly log: `Т-Банк API error 10: Метод Charge заблокирован для данного терминала`
- UI: ERROR + СБП/карта+ (без checkout) — код CoffeeOS OK
- Артефакт: `mcp_fly_inline_pay_2026-07-30_charge_blocked.json`

### Сессия 2026-07-30 (fix widget_init 422 → defer + Rebill Charge)

- Root cause: OrderCreator Init, затем widget_init Init снова → duplicate OrderId
- `defer_payment_init` + `WidgetPaymentInitiator` (rebill primary → Charge)
- Deploy + MCP: Charge blocked терминалом (не duplicate Init)

### Сессия 2026-07-30 (MCP PASS после фиксов remount/fallback)

- Deploy бандл `application-DMPdGrlR.js`
- CDP: PROCESSING «Ещё чуть-чуть…» · не checkout · ERROR + СБП/карта+ persist >5s · SMS timer
- widget_init 422 на стенде → SUCCESS не проверен
- Артефакт: `mcp_fly_inline_pay_2026-07-30_pass.json`

### Сессия 2026-07-30 (fix2: remount UI + cart clear · deploy#2)

- MCP после первого deploy: `last_order_id` OK, заказ 200, но UI пропадал — full→embedded remount
- FE: `repeatInlinePayUiStore` + clear cart перед one-click order
- Дальше: redeploy → MCP статусы/СБП/карта+

### Сессия 2026-07-30 (fix: one-click → new pending order + PROCESSING UI)

- BE: `CustomerFrequentProductsService` — `last_order_id` в payload, cache `shop/freq/v2/…`
- FE: `createRepeatInlineOrder.js` — addToCart → POST `/orders` (card) → новый `order_id`
- FE: `RepeatSection` — сразу PROCESSING, затем `runRepeatWidgetPayFlow({ fsm })`
- Тесты: frequent service/cache/API PASS · JS create+inline+sms 15/15 · payment cart 24/0 (2 skip)

### Сессия 2026-07-30 (MCP Fly #32 · FAIL — не к заказчику)

- `/up` green · bundle `application-D10vNL7z.js` содержит ротацию/SMS/✔/red
- Point A + Aram: «оплатить в клик» → `#/checkout` PaymentMethodsSheet (не inline)
- Root cause: `GET frequent_products` → `last_order_id: null` ×3 → fallback `repeatPayOneClickItem`
- SMS pinpad на checkout нет (ок для checkout; inline path не открыт)
- Артефакт: `artifacts/tbank_inline_payment_button_statuses/mcp_fly_inline_pay_2026-07-30.json`

### Сессия 2026-07-30 (#32 SMS pinpad + UI states + HTTP edge)

- `shopSmsPinPad.js` / `SmsPinPad.svelte` — таймер 00:59 + 4-digit + numpad
- `NewCardForm showSmsPinPad` только в InlinePayFallback (checkout не ломаем)
- `InlinePayFallback`: SUCCESS зелёный+✔ · ERROR красный · fallback оранжевый
- `runTbankInlineButtonCycle`: catch httpStatus≥400 → http_error
- `widgetRepeatPayFlow`: `resetAfterMs=3000` на SUCCESS/ERROR/timeout/http
- Тесты: JS 30/30 · `shop_new_card_form_step1` UI 1/1 PASS

### Сессия 2026-07-30 (#32 Шаг 4–8 GREEN · скрин в артефактах)

- Артефакт: `tbank_inline_payment_button_statuses/screenshots/01_full_flow_schema_status_sbp_cards_form.png` (+ копия `tbank_widget_oneclick_fallback/…/05_…`)
- FE: `shopInlinePayFsm.js` — poll 1500 / rotate 1800 / timeout 15s + map 1051
- FE: `widgetRepeatPayFlow.js` — RepeatSection pay orchestration
- UI: `InlinePayFallback` — белые СБП/карта+, expanded *XXXX, NewCardForm; ротация текстов #32
- Тесты: `node --test …shop_inline… + shop_widget…` **23/23 PASS**
- Backlog: SMS keypad 00:59 на скрине ещё нет в NewCardForm; RepeatSection ~231 строк (чуть >200)

### Сессия 2026-07-29 (PHASE 3 REVIEW · #33)

- Регрессия оплаты (PASS): `bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb test/services/shop/order_creator_test.rb test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_adapter_test.rb`
- RLS/tenant isolation (PASS): `bin/rails test test/integration/rls_tenant_isolation_test.rb test/integration/multi_tenant_isolation_test.rb test/integration/shop/api/tenant_isolation_test.rb`
- `bin/rubocop` (PASS)
- ReadLints: ошибок нет

### Сессия 2026-07-29 (PHASE 2 GREEN Шаги 4–7 · T-Kassa Widget #33)

- FE: `widgetInlinePay.js` — widget init + poll + isCardRelatedError
- FE: `InlinePayFallback.svelte` — inline fallback UI (статус-плашка, кнопки СБП/карта+, expanded cards)
- FE: `RepeatSection.svelte` обновлён — inline widget pay flow (init→poll→confirm/reject→fallback)
- FE: fallback SBP → reuse `shopSbpPay.js`, fallback карта+ → expanded saved cards
- Тесты FE: 17/17 PASS (FSM + widgetInlinePay labels + isCardRelatedError + integration flow)
- BE регрессия: PASS

### Сессия 2026-07-29 (PHASE 2 GREEN Шаги 1–3 · T-Kassa Widget #33)

- BE: `connection_type: "Widget"` kwarg в `TbankInlineInit.call` + `TbankAdapter#init_payment(data:)` → `DATA` в payload
- BE: `POST /shop/api/payments/widget_init` — сумма из БД, 404 missing, стандартизированные ошибки
- FE: `shopWidgetPayFsm.js` — IDLE→PROCESSING→SUCCESS/ERROR/FALLBACK (карточные ошибки → FALLBACK)
- Тесты: unit 5/5 + integration 4/4 + FE 8/8 = **17/17 PASS**
- Регрессия оплаты: 64 runs, 0 failures

### Сессия 2026-07-29 (PHASE 0 intake · T-Kassa Widget One-Click + Fallback)

- Новая задача #33: Интеграция виджета быстрой оплаты Т-Кассы и One-Click сценария в PWA
- ТЗ дословно: `customer_tasks/Интеграция виджета быстрой оплаты Т-Кассы и One-Click сценария в PWA.md`
- 4 скрина заказчика → `artifacts/tbank_widget_oneclick_fallback/screenshots/` (01–04)
- CBR строка #33 добавлена
- Отличие от #32: здесь SDK Т-Кассы (`connection_type: Widget`) + fallback СБП/карта при отказе эквайринга

### Сессия 2026-07-29 (PHASE 1 SPEC · T-Bank inline payment button)

- ТЗ → `todo.md`: 8 атомарных шагов + маппинг путей на Rails/Svelte
- Gaps: PayType O, Confirm, status GetState+Confirm, FE FSM тайминги ТЗ
- `tbank_adapter.rb` >200 — GREEN: PayType O + Confirm + status sync
- Дальше: Шаг 4 RED (Frontend: FSM IDLE→PROCESSING + polling/rotation)

### Сессия 2026-07-29 (PHASE 0 intake · T-Bank inline payment button)

- ТЗ: `customer_tasks/Интеграция inline-оплаты Т-Банка с динамическими статусами внутри кнопки.md`
- Артефакты: `artifacts/tbank_inline_payment_button_statuses/`
- CBR + `customer_tasks/README` — строка индекса
- Код / `todo.md` не трогали — ждут go → SPEC

### Сессия 2026-07-29 (Deploy · Auth funnel Flash Call×2 → SMS)

- `git push origin develop` → `cd26cb1b`
- `fly deploy` — image built + deployed, machines healthy
- MCP: витрина `655aaccb` загрузилась, API categories 200, phone_otp/send → 429 (Rack::Attack OK), логи чистые (нет 500)
- RoutingError `/uploads/products/...` — известная особенность (эфемерные файлы Fly)

### Сессия 2026-07-29 (PHASE 0 intake · Auth funnel Flash Call×2 → SMS)

- ТЗ: `customer_tasks/Рефакторинг воронки авторизации PWA Каскад Flash Call x2 SMS.md`
- Артефакты: `artifacts/auth_funnel_flash_call_x2_sms_ru/`
- CBR + `customer_tasks/README` — строка индекса
- Код / `todo.md` не трогали — ждут go → SPEC

### Сессия 2026-07-29 (PHASE 2 BUILD GREEN · Auth funnel Flash Call×2 → SMS)

- GREEN: реализация `Shop::SmsRuClient` (flash_call /code/call + sms /sms/send + dev fallback)
- `Shop::PhoneOtp`: убран messenger, flash_call через SmsRuClient, sms переиспользует код из flash_call
- `phoneAuthCascade.js`: убрана фаза MESSENGER, каскад Flash×2→SMS за 40с, добавлен `smsSentHint`
- Тесты: sms_ru_client 6/6, sms_ru_phone_otp 7/7, phone_otp 10/10, FE cascade 15/15 — все GREEN
- Регрессия shop integration: 4 runs, 0F, 0E — PASS
- Контроллер: `ip: request.remote_ip` в `send_code!`, убран messenger rescue
- Rack::Attack: убран `shop/phone_otp_messenger` throttle
- PhoneAuthCodeStep.svelte: убраны messenger imports/кнопка/fallback
- REVIEW: убран мёртвый код (MessengerDeliveryError, generate_sms_code, rescue SmsClient/FlashCallClient)
- rubocop: 0 offenses на новых файлах (rack_attack pre-existing — не трогаем)
- N+1: нет циклов, все запросы одиночные. RLS: MobileOtpCode без tenant_id — ок.
- Коммиты: RED `f7313fdb`, GREEN `b2685910` + `8b76da10`, REVIEW `8d94b95b`

### Сессия 2026-07-29 (PHASE 2 BUILD RED · Auth funnel Flash Call×2 → SMS)

- RED-тесты (3 файла): sms_ru_client_test.rb (6E), sms_ru_phone_otp_test.rb (2F+1E), cascade_smsru_test.mjs (1E)
- Коммит: `f7313fdb` `[RED]`

### Сессия 2026-07-29 (PHASE 1 SPEC · Auth funnel Flash Call×2 → SMS)

- todo.md: добавлен блок “todo — Auth funnel cascade Flash Call×2 → SMS”
- План RED: `Shop::SmsRuClient` + `phone_otp` endpoints + `Rack::Attack`, FE wizard+каскад-таймер и 422/тайминги
- Лимиты учтены: `Current.tenant_id`/RLS и запрет файлов >200 строк

### Сессия 2026-07-28 (Fly Test sticky via last_ordered · GREEN local)

- Diag: last_ordered=`af4f78d6` inactive · 7 orders 2026-07-28 > Point A
- Fix preferred + bootstrap bounce + history skip inactive
- Тесты local PASS; Fly MCP — после deploy

### Сессия 2026-07-28 (MCP после deploy v400 · DONE)

- Point A Ленин · Профиль 2bc3… · «повторить»
- Профиль: email + phone `+79639124847` Подтвержден
- session/refresh → phone=+79639124847

### Сессия 2026-07-28 (Aram real phone link · DONE)

- Владелец: настоящий номер `+7 963 912 4847`
- `link_phone!` → `+79639124847`; merge donor `e01d7bd4-…` (уже с этим phone)
- AFTER: orders 75 / payments 75 / cards 2 · Point A orders 59 / succeeded 13
- Артефакт `fly_aram_real_phone_link_2026-07-28.json`

### Сессия 2026-07-28 (Repeat recommendations + SBP 3001 · DONE)

- Intake + root cause: Fly Overnight 0 orders vs Point A freq=3
- Код: restore→bootstrap · preferred · history skip inactive · deactivate Fly Overnight
- SBP 3001 friendly message
- Deploy **v398→v399** · MCP PASS · скрин `02_fly_aram_point_a_repeat_restored.png`

### Сессия 2026-07-28 (Auth funnel · Push/Fly/MCP)

- Push `develop` → `22d136b`; `fly deploy` → **v397**
- MCP: flash/messenger/sms send+verify + 429 `retry_after` 20/30/60
- UI checkout: `phone-auth-wizard` Screen1 → Screen2 «Ждем звонок... 00:20»
- Артефакт: `artifacts/auth_funnel_cascade_flash_messenger_sms/fly_mcp_auth_funnel_2026-07-28.json`

### Сессия 2026-07-28 (Auth funnel · Шаг 6)

- `Shop::PhoneOtp`: cooldowns по каналу `flash_call=20`, `messenger=30`, `sms=60`
- `Rack::Attack`: throttles `/shop/api/phone_otp/send` по паре `phone+channel`, `429` + `Retry-After`
- Попутно закрыт баг старого `rack.attack` responder/logging (`Rack::Attack::Request`)
- Тесты: Ruby cooldown+throttle **19/0**

### Сессия 2026-07-28 (Auth funnel · Шаг 5)

- FE: Messenger (30с) / SMS (60с), кнопки WA/TG + SMS, `buildOtpSendBody`
- Backend: `Shop::MessengerClient` + `Shop::PhoneOtp` принимает `channel=messenger`; при delivery error возвращается `messenger_delivery_error` флаг
- OTP код для sms/messenger: 4 цифры (совместимость с PIN auto-verify)
- Тесты: Ruby phone_otp messenger **14/0**

### Сессия 2026-07-28 (Auth funnel · Шаг 3)

- Flash cascade: 20с «Ждем звонок...», авто Flash #2, кнопка «Запросить звонок еще раз»
- Вынос Экрана 2 → `PhoneAuthCodeStep.svelte`; `phoneAuthCascade.js`
- Тесты: Node **16/0**; Ruby wizard UI + phone_otp **8/0**

### Сессия 2026-07-28 (Auth funnel · Шаг 2)

- PIN 4 ячейки + авто-сабмит `phone_otp/verify` на 4-й цифре; «Изменить номер»
- `phoneAuthWizard.js`: `shouldAutoSubmitPin`, `buildVerifyBody`, `applyPinDigit`
- Тесты: Node **10/0**; Ruby wizard+phone_otp+cbr+cart **12/0**

### Сессия 2026-07-28 (Auth funnel · Шаг 1)

- Intake + SPEC + GREEN Экран 1
- `PhoneAuthWizard.svelte` + `phoneAuthWizard.js`: маска, autofocus, «Продолжить» → `flash_call` → Экран 2 stub
- Checkout: убраны Email OTP UI и radio channel
- Тесты: Node wizard **5/0**; Ruby auth UI + cbr_01 + cleanup + cart UX + phone_otp **13/0**
- ISSUES: checkout_ui_cleanup stale — **resolved**

### Сессия 2026-07-27 (Aram SBP E2E + deploy v396)

- Скрины + JSON E2E; фикс Receipt.Email → v396
- Повтор: `3001 Оплата через СБП недоступна` (не код)

### Сессия 2026-07-27 (Aram SBP E2E screenshots)

- OTP Aram → sheet MIR+SBP → «Оплатить быстро» → **329**
- WAITING_FOR_BANK UI снят; артефакты в `codeblack_t_kassa_sbp_tokenization/screenshots/`
- Фикс: Receipt.Email из `order.customer` + Details в ApiError

### Сессия 2026-07-27 (push / Fly / MCP CODE:BLACK lifecycle)

- `git push origin develop` → `d4f4369`
- `fly deploy -a coffeeos` → **v395**
- MCP: WAITING_FOR_BANK + «Я оплатил» → `payments/status` 404; cold start LS → waiting
- Артефакт: `artifacts/codeblack_t_kassa_sbp_tokenization/fly_mcp_pwa_lifecycle_2026-07-27.json`

### Сессия 2026-07-27 (GREEN CODE:BLACK PWA lifecycle)

- `codeblackPendingOrder.js` · `checkOrderStatus` · App visibility/cold start
- `GET /shop/api/payments/status/:order_id` · PaymentResult WAITING_FOR_BANK + «Я оплатил»
- Тесты: Node **25/0**; status+UI **23/0**; регрессия §2.3+callback **59/0** (2 skips)

### Сессия 2026-07-27 (intake CODE:BLACK T-Kassa SBP PWA lifecycle)

- ТЗ: `customer_tasks/Интеграция Т-Кассы СБП и токенизации в PWA CODE BLACK.md`
- Артефакты: `artifacts/codeblack_t_kassa_sbp_tokenization/`
- CBR #28 + backlog row; README customer_tasks
- Gap vs v2: LS pending + visibilitychange + cold start 15м + экран «Я оплатил»

### Сессия 2026-07-27 (push / Fly / MCP SBP epic)

- `git push origin develop` — 16 коммитов → `6154539`
- `fly deploy -a coffeeos` — **v394** complete
- MCP: `/up` 200 · catalog+checkout · bundle shopSbpPay/Checkout · `sbp/init` → 401 (есть роут)
- Артефакт: `artifacts/sbp_deep_link_card_tokenization/fly_mcp_sbp_epic_2026-07-27.json`

### Сессия 2026-07-27 (GREEN Шаг 10 card mask)

- `formatMaskedPan` / `formatCardRowLabel` → `**** 1234`
- 1-tap + invalid token — reuse (one_click / repeatInvalidTokenStore)
- Тесты: Node mask+repeat **17/0**; Ruby step10+repeat **10/0**

### Сессия 2026-07-27 (GREEN Шаги 7–8 characterization)

- `sbp_epic_card_tokenization_char_test.rb` — Recurrent=Y, SavedCardStore, Charge, one_click 422/`1014`
- Fake one_click/new_card stubs: `receipt:` для изоляции с adapter
- Тесты: char+one_click+new_card+adapter **38/0**; Node invalid rebill **14/0**

### Сессия 2026-07-27 (GREEN Шаг 11 SBP return polling)

- `pollSbpPaymentStatus` + `SBP_INCOMPLETE_MESSAGE`; PaymentResult wired
- Тесты: Node shop_sbp_pay **13/0**; return UI **2/0**
- success/ok → finalize poll → order; timeout/fail → «Оплата не завершена…»

### Сессия 2026-07-27 (GREEN Шаг 9 UI SBP)

- `app/frontend/lib/shopSbpPay.js` — init / redirect / poll opts / errors
- i18n `ctaSbpFastPay`; sheet SBP enabled; Checkout: order→sbp/init→nspk
- OrderCreator: sbp не simulate-accept; skip `init_gateway` для sbp
- Тесты: Node **8/0**; UI+repeat **11/0**; order_creator **22/0**; регрессия оплаты **59/0**

### Сессия 2026-07-27 (RED Шаг 9 UI SBP)

- Тесты: `shop_sbp_pay_test.mjs` (ERR_MODULE_NOT_FOUND) + `sbp_payment_ui_test.rb` (4 failures)
- Шаги 4–5 уже в `tbank_controller_test`; Шаг 6 — reuse orders/finalize
- Код UI не писали

### Сессия 2026-07-27 (GREEN Шаг 3 sbp/init · Волна A закрыта)

- `Shop::SbpPaymentInitiator` — simulate nspk / live Init+Receipt+GetQr
- Route + `payments#sbp_init`
- Тесты: initiator+api **10/0**; wave A **19/0**; tbank+order_creator **56/0**

### Сессия 2026-07-27 (RED Шаг 3 sbp/init)

- Тесты: `sbp_payment_initiator_test.rb` + `api/sbp_payment_init_test.rb`
- Прогон: 10 runs, 4 failures, 5 errors — NameError + route 404
- Simulate: fictional `qr.nspk.ru/…SIMULATE…`; live: Init+Receipt→GetQr
- Код реализации не писали

### Сессия 2026-07-27 (GREEN Шаг 2 GetQr)

- `Payments::TbankQrFetcher` — GetQr + Token через adapter; `{ payment_url:, data: }`
- Тесты: qr+adapter **28/0**
- Runbook PAYMENT.md — GetQr section

### Сессия 2026-07-27 (RED Шаг 2 GetQr)

- Тесты: `test/services/payments/tbank_qr_fetcher_test.rb` (5 кейсов)
- Прогон: 5 runs, 2 failures, 3 errors — намеренный RED
- Код реализации не писали

### Сессия 2026-07-27 (GREEN Шаг 1 Receipt)

- `Payments::TbankReceiptBuilder` — Items/Taxation из order + `TBANK_TAXATION`/`TBANK_TAX`
- `TbankAdapter#init_payment` — опц. `receipt:`; `build_token` исключает Hash/Array
- Тесты: receipt+adapter **27/0**; регрессия callback+adapter+order_creator **56/0**
- Runbook PAYMENT.md — ENV Taxation/Tax

### Сессия 2026-07-27 (RED Шаг 1 Receipt)

- Тесты: `tbank_receipt_builder_test.rb` + 3 кейса в `tbank_adapter_test.rb`
- Прогон: 27 runs, 1 failure, 6 errors — намеренный RED
- Код реализации не писали

### Сессия 2026-07-27 (SPEC SBP Deep Link + card tokenization)

- As-is: Init без Receipt; нет GetQr; SBP UI disabled; Token/webhook/Recurrent/Charge готовы
- Решения: `TbankReceiptBuilder`, `TbankQrFetcher`, `SbpPaymentInitiator`, route `/shop/api/payments/sbp/init`
- Пути ТЗ → CoffeeOS; webhook 401 (не 403); adapter 228 — не раздувать
- Код не писали — ждём RED

### Сессия 2026-07-27 (интейк SBP Deep Link + card tokenization)

- ТЗ: `customer_tasks/Интеграция оплаты СБП Deep Link и токенизации карт Т-Касса v2.md`
- Артефакты: `artifacts/sbp_deep_link_card_tokenization/` (скринов в сообщении не было)
- CBR + customer_tasks README обновлены
- Код / todo.md / SPEC — не трогали (ждём go)

### Сессия 2026-07-27 (deploy+MCP Repeat invalid token payment sheet)

- Push develop `f0877ac`; Fly **v393** (`fly deploy --remote-only --depot=false`)
- MCP: CTA «Добавить карту», PaymentMethodsSheet labels, NewCardForm, persist selection
- Артефакт: `artifacts/repeat_order_invalid_token_payment_sheet/fly_mcp_repeat_invalid_token_2026-07-27.json`
- Скрин: `screenshots/02_fly_add_card_cta_invalid_token_2026-07-27.png`

### Сессия 2026-07-27 (GREEN Repeat order invalid token payment sheet)

- `paymentMethodI18n.js`, `repeatInvalidTokenStore.js` — i18n + invalid RebillId store
- `CartSheet`: CTA «Добавить карту» при invalid token + repeat context
- `PaymentMethodsSheet`: inline/load errors, i18n labels, SBP toast
- `Checkout.svelte`: wire store, preload fail → toast, pay fail → inline + setTokenInvalid
- Тесты: `node --test repeat_invalid_token_payment_test.mjs` **14/0**; repeat+payment mirror **27/0**
- Полная shop-регрессия: 2 pre-existing mirror fail (`order_status_acceptance_cbr`, `quick_repeat_frequent_cache`) — не из этой задачи

### Сессия 2026-07-27 (RED Repeat order invalid token payment sheet)

- Тесты: `test/javascript/repeat_invalid_token_payment_test.mjs`, `test/integration/shop/repeat_invalid_token_payment_test.rb`
- Node: ERR_MODULE_NOT_FOUND `paymentMethodI18n.js` / `repeatInvalidTokenStore.js`
- Ruby: 7 runs, 7 failures (mirror grep CartSheet/Sheet/Checkout)
- Коммит `51d4560` · код не писали

### Сессия 2026-07-27 (SPEC Repeat order invalid token payment sheet)

- As-is: Svelte `PaymentMethodsSheet`, repeat → checkout autopay, нет `isTokenInvalid`
- Решения: `repeatInvalidTokenStore.js`, `paymentMethodI18n.js`, inline errors в sheet, CTA peek
- Тесты: `test/javascript/repeat_invalid_token_payment_test.mjs` (не React path из ТЗ)
- Код не писали — ждём RED

### Сессия 2026-07-27 (интейк Repeat order invalid token payment sheet)

- ТЗ: `Главный экран — повторный заказ (невалидный токен) BottomSheet выбора способа оплаты.md`
- Артефакты: `artifacts/repeat_order_invalid_token_payment_sheet/` (скрин BottomSheet «Способ оплаты»)
- CBR + customer_tasks README обновлены
- Код / todo.md / SPEC — не трогали (ждём go)

### Сессия 2026-07-27 (push+deploy+MCP Profile Email↔Phone merge)

- Push develop `9184cde` → Fly **v392** (1-й release: DDL ok, advisory lock fail; retry ok)
- MCP: GET/PATCH profile, 401, UI контакты, checkout autofill, link_* 400
- Артефакт: `artifacts/profile_email_phone_merge/fly_mcp_profile_merge_2026-07-27.json`

### Сессия 2026-07-27 (GREEN Profile Email↔Phone merge)

- DDL: `email_verified` / `phone_verified` на `mobile_customers`
- `Shop::CustomerProfileMerger` — soft-merge (orders/cards/carts/sessions)
- API: GET/PATCH profile, POST link_email/link_phone; linkers merge вместо raise
- `OrderCreator` — autofill verified email/phone из сессионного профиля
- PWA: Profile.svelte контакты+OTP; Checkout autofill + «Сохранить в профиль»
- Тесты: profile/merge/OTP зона **47/0**; оплата+refresh **30/0** (2 skips)

### Сессия 2026-07-27 (Intake + SPEC Profile Email↔Phone merge)

- ТЗ + артефакты + CBR + `todo.md` as-is/gap

### Сессия 2026-07-24 (MCP Phone OTP SMS/Flash Call)

- Push develop → deploy **v390**; secret `SHOP_OTP_LOG_FALLBACK=true`
- SMS send/verify + refresh_token 64; cooldown 422; Flash Call 4675 verify PASS
- UI checkout: блок телефона + hint flash call
- Артефакт: `artifacts/phone_otp_sms_flash_call/fly_mcp_phone_otp_2026-07-24.json`

### Сессия 2026-07-24 (GREEN Phone OTP SMS/Flash Call)

- Backend: PhoneNormalizer, SmsClient, FlashCallClient, PhoneOtp, PhoneVerifiedCustomerLinker, API + rack_attack, cooldown email+phone
- Frontend: Checkout phone block (маска, SMS/Flash Call, timer 60с, refresh_token LS)
- Тесты: phone suite + email OTP regression **41/0**; JS phone_otp_ui **5/0**
- Без DDL; `SHOP_OTP_LOG_FALLBACK` / без ключей → только лог

### Сессия 2026-07-24 (SPEC Phone OTP SMS/Flash Call)

- As-is: Email OTP + Brevo есть; `mobile_otp_codes`/`mobile_customers` есть без phone-сервиса; cooldown 60с нет
- Решения: без DDL; SMS.ru + FlashCall ENV; log fallback; linker без silent merge конфликтов; тесты Minitest
- `todo.md` — чеклист шагов 1–8; код не писали

### Сессия 2026-07-24 (интейк Phone OTP SMS/Flash Call)

- ТЗ: `Вход и регистрация по номеру телефона SMS Flash Call.md`
- Артефакты: `artifacts/phone_otp_sms_flash_call/`
- CBR + customer_tasks README обновлены
- Код / todo.md / SPEC — не трогали (ждём go)

### Сессия 2026-07-24 (MCP PWA durable sessions)

- Push `8c990c9` + deploy **v388**; MCP нашёл баг Auth (нет CSRF/API key) → fix `7de10c2` → **v389**
- Aram OTP → `shop_refresh_token`; refresh rotate 200/401; isolated context silent refresh → профиль Aram
- Артефакт: `artifacts/pwa_durable_sessions_silent_refresh/fly_mcp_aram_silent_refresh_2026-07-24.json`

### Сессия 2026-07-24 (интейк PWA durable sessions)

- ТЗ: `Долговечные сессии PWA и фикс авто-разлогина.md`
- Артефакты: `artifacts/pwa_durable_sessions_silent_refresh/`
- CBR + customer_tasks README обновлены
- Код / todo.md / SPEC — не трогали (ждём go)

### Сессия 2026-07-24 (анализ статусной модели платежей Т-Банк)

- ТЗ: `Анализ статусной модели платежей и заказов Т-Банк.md`
- Init без `PayType` → одностадийная; заказ → `accepted` только на `CONFIRMED`→`succeeded`
- Webhook `POST /callbacks/tbank` → `TbankCallbackJob`; fallback `GetState` в `TbankPaymentSync`
- API Cancel/Refund Т-Банка в коде **нет**; есть внутренняя модель `Refund` + отмена заказа barista/guest без банка

### Сессия 2026-07-24 (peek repeat plus → cart)

- ТЗ: `Peek плюс на повторе не добавляет в заказ.md`
- Корневая причина: embedded `+` только `setFrequentQty`, без `addToCart`.
- Fix: `repeatEmbeddedCart.js` + wire в `RepeatSection`; full layout без изменений (qty под 1-click).
- Тесты: `peek_repeat_plus_adds_to_cart_test` + sheet zone **52/0**.

### Сессия 2026-07-24 (default peek empty)

- ТЗ: `Дефолт шторки peek и текст без истории.md`
- Store: empty → `MODE_PEEK` (не EMPTY/HIDDEN); `empty` vh = 34 (= peekSingle).
- Тесты: `cart_sheet_default_peek_empty_test` + zone **23/0**.

### Сессия 2026-07-24 (MCP Арам — проверка фиксов шторки)

- Fly **v384** · build **prog33** · OTP `aramfifa100@gmail.com`.
- PASS: нет «тут будут твои заказы» при истории; нет глобальной «повторить в 1 клик»/«+ещё»; 3× card pay; undo баннер нет; профиль Aram.
- Артефакт: `fly_mcp_aram_fixes_2026-07-24.json` + screenshots 01–04.

### Сессия 2026-07-24 (убрать общую кнопку и «ещё»)

- ТЗ: `Убрать общую кнопку повтора и ещё.md`
- UI: удалены `shop-repeat-one-click` + `shop-repeat-more` из `RepeatSection.svelte`.
- Structural check PASS; rails test blocked: Postgres closed connection from Windows client.

### Сессия 2026-07-24 (empty placeholder vs повторить)

- ТЗ: `Empty надпись тут будут твои заказы только без истории.md`
- `CartSheet`: надпись при `frequentCount === 0`; RepeatSection empty-slot при `frequentCount > 0`.
- Тесты: `cart_sheet_empty_orders_placeholder_test` + sheet zone **52/0**.

### Сессия 2026-07-24 (убрать «Отменить» в шторке)

- ТЗ: `Убрать кнопку Отменить в шторке корзины.md` · `artifacts/cart_sheet_remove_undo_button/`.
- UI: удалён блок `shop-cart-undo` из `CartSheet.svelte`; `CART_SHEET_BUILD=prog31`.
- Тесты sheet zone: **43 runs / 0 failures**.

### Сессия 2026-07-23 (worker Fly started · OTP/session restore без re-OTP)  

- Повторный прогон: OTP → checkout Aram → шторка **МИР *5953 + *8782** → «повторить» → профиль → заказы сегодня.
- PNG на диске: `artifacts/usercards_save_card/screenshots/aramfifa_mcp_2026-07-23/` (01…07).
- JSON: `aramfifa_mcp_ui_2026-07-23.json` (пути к скринам).
- OTP-fix `fea1215` на Fly ещё **не** задеплоен.

### Сессия 2026-07-23 (worker + OTP/session restore)

- Fly: `fly machines start 48ee61ea71d948` · SolidQueue supervisor/worker up · `--restart always`.
- Корень «OTP на каждый F5»: `email_otp/status` восстанавливал verified из БД, но **не** `customer_id` → frequent пустой; UI снова просил код.
- Fix: `GuestCustomerResolver` · status вызывает `EmailVerifiedCustomerLinker` · frequent/cards через resolver · фронт `restoreGuestSession` на CartSheet/Checkout.
- Тесты: guest restore + resolver + email OTP/cards **26/0**.

### Сессия 2026-07-23 (diag aramfifa — без правок кода)

- Email `aramfifa100@gmail.com` · customer `2bc37279…` · карты **\*5953** (default) + **\*8782**, last_used сегодня.
- Заказы/оплаты: **53 / 53**, succeeded **10** — всё на tenant `2fdee1ac…` (Demo Coffee Point A); на Fly Test (`af4f78d6…`) — **0**.
- Worker Fly: был **stopped** → поднят в этой сессии. Артефакт: `artifacts/usercards_save_card/aramfifa_full_diag_2026-07-23.json`.

### Сессия 2026-07-23 (убрать сетку из expanded)

- Диагноз: expanded не пропал — сетка каталога поверх списка заказов.
- Fix: удалены `<FrequentSheetCategories />` и компонент; список `shop-cart-expanded-card` без изменений; `CART_SHEET_BUILD=prog30`.
- Тесты: customer_fixes + sheet zone **51/0**.

### Сессия 2026-07-23 (MCP gesture hit area на Fly)

- Deploy: `01KY7BWBJW2NQPAY336P1STVJJ` (v380), build prog29.
- До: min-h-14≈56px / порог 32px. После: **80×414** full-strip / порог 20px.
- Свайпы: left↓ hidden · right↑ peek · center↑ expanded · far-left↓ peek · far-right↓ hidden.
- Артефакт `fly_gesture_hit_area_mcp_2026-07-23.json` + 6 скринов.

### Сессия 2026-07-23 (GREEN: gesture hit area)

- Заказчик: свайп на весь прямоугольник полосы, чувствительнее.
- Код: `data-gesture-hit-area=full-strip`, `min-h-14`→`min-h-20`, `SWIPE_UP_PX` 32→20, `CART_SHEET_BUILD=prog29`.
- RED `ac69ca4` · тесты зоны шторки **45/0**.

### Сессия 2026-07-23 (intake: чувствительность свайпа шторки)

- Текст заказчика: «сделать под выдвижение шторки более чувствительной, чтобы реагировала на всю область. Прямоугольник.»
- Док: `customer_tasks/Чувствительность свайпа шторки hit area прямоугольник.md` · artifacts `cart_sheet_gesture_hit_area/`
- Вторая правка заказчика — текста ещё нет.

### Сессия 2026-07-23 (MCP layout prog28 после owner redeploy)

- Deploy: `01KY5BN0JKEW31V9GHAKSX6YXF` (v378), `data-cart-sheet-build=prog28`.
- OTP `mcp-quickrepeat@example.com` → empty+frequent **46vh** `layout=full` · peek **embedded** (заказ→+цена→повтор, payOnCards=0) · hidden чипы без повтора · «повторить в 1 клик» → 4 chips +1108₽ · checkout без «повтор».
- Скрины: `screenshots/fly_layout_prog28_2026-07-23/` (6 шт). Live T-Bank SKIP (точка закрыта).

### Сессия 2026-07-22 (layout шторки = канон скринов заказчика)

- Проблема: заказ и «повторить» выглядели как две полосы; в «почти hidden» торчал повтор.
- Fix: `RepeatSection layout=embedded|full`; checkout **перед** repeat; hidden без RepeatSection; peek высота `peekSingleWithRepeat`/`peekMultiWithRepeat` при frequentCount>0; build `prog28`.
- Тесты: `quick_repeat_sheet_layout_canon_test` + обновлены heights/b113/checkout UX · quick_repeat **57/0** · sheet zone **48/0**.

### Сессия 2026-07-22 (rules: намерение ≠ литерал go)

- Баг агента: ждал/не ждал слово `go` вместо смысла («ебашь/сделай»).
- Канон: § «Апрув шага = намерение» в `coffeeos-task-workflow.mdc`; SBR — порядок фаз, gate по намерению; push/deploy по-прежнему явные.

### Сессия 2026-07-22 (MCP DevTools после redeploy FIX-A…F)

- Deploy: `deployment-01KY4MHZPD7YS2D9NS4NP54B09` (v377), `/up` 200.
- Клиент `mcp-quickrepeat@example.com`: OTP verify → profile id + `frequent_products` 3 позиции **без нового заказа** (корень жалобы закрыт).
- UI: empty 34vh с повтором · card-pay ×3 · repeat → +1 105₽ · expanded categories 4×15 · checkout без «повторить».
- Артефакт `fly_fix_af_mcp_2026-07-22.json` + 6 скринов; DEMO_FEEDBACK → done *(MCP PASS)*.
- Finding: категории в шторке только при expanded+count≥2 (не блокер).

### Сессия 2026-07-22 (FIX-A…F — жалоба заказчика Quick Repeat)

- **FIX-A:** `Shop::EmailVerifiedCustomerLinker` в `email_otp#verify` — `find_or_initialize_by(email)` + `CustomerSession.set_customer_id!`; тест `email_verify_customer_link_test` 2/0.
- **FIX-B:** `normalize_modifier_options` в `CustomerFrequentProductsService` — склейка пустых вариантов, legacy jsonb без поломки.
- **FIX-C…F:** `FrequentSheetCategories` в expanded; `shop-repeat-slot-single`; empty→peekSingle при frequentCount>0; per-card `shop-repeat-card-pay`; `{#if !onCheckout}` на RepeatSection; `refreshFrequentProducts` после verify на Checkout.
- Прогоны: quick_repeat **54/0** · email_verify 2/0 · сервис 13/0.
- ⚠️ **Не задеплоено на Fly** — нужен redeploy по апруву владельца.

### Сессия 2026-07-21 (код-ревью Quick Repeat + фиксы замечаний 1–3)

- Ревью диффа `bae3fef..HEAD` по `coffeeos-code-review.mdc`: блокеров нет; RLS/N+1/секреты чисто; 3 замечания.
- RED `397dd5c`: стабильный ключ счётчика (не индекс), честный тост «Добавлено N из M», bust_cache! не роняет hot-path (подмена singleton `Rails.cache.delete` — `minitest/mock` в minitest 6 ломает optparse, стабим руками).
- GREEN `9afdff7`: `frequentCardKey(item)` = `product_id:JSON(modifier_options)` (store 120 строк, лимит ок); `RepeatSection` импортирует ключ из store (дубль keyOf удалён); `repeatAllToCart` считает added; rescue+warn в `bust_cache!`.
- Прогоны: фиксы 20/0 · фича 29/0 · оплата §2.3 24/0 (2 skips pre-existing) · T-Bank callback 31/0 · svelte compile OK · rubocop 4 файла 0 offenses.
- Nits отложены: общий кэш categories_by_name, константа тост-таймера → PRACTICES.
- ⚠️ Фиксы **не задеплоены** — на Fly пока версия до ревью.

### Сессия 2026-07-21 (MCP real-run Quick Repeat — без стабов)

- Посев на Neon (демо-стенд): клиент `mcp-quickrepeat@example.com` (8d8f3872…919e) + 4 mobile-заказа accepted за 45 дней (Cold Brew клюква ×2 — частота, кордиал ×2 — свежесть); скрипты в `scripts/scratch/mcp_quick_repeat_seed*.rb` (не коммитятся). `fly ssh console -C` теряет аргументы → сеял локальным `pg` по DATABASE_URL.
- Вход штатным email-OTP из браузера: send_code → код из таблицы `shop_email_otp_codes` → verify 200 → `user/cards` привязал customer к сессии.
- Реальный API: `frequent_products` вернул 3 позиции из реальной истории (335₽ первым по частоте 2, далее 385₽ по свежести). Секция «повторить» отрисована из API (стаб выключен, чистая вкладка).
- E2E: гость — секции нет ✓; счётчик «+» → qty 2 в localStorage мгновенно ✓; «+ещё» → expanded ✓; «повторить в 1 клик» → корзина **+1 440₽ = 335×2+385+385** (qty учтён) ✓; «оплатить в 1 клик» → #/checkout, autopay-флаг снят, guard «Укажите email» (канон) ✓. Живое списание SKIP (точка закрыта + прод T-Bank).
- Артефакт `fly_real_run_mcp_2026-07-21.json` (+5 скринов `screenshots/fly_real_run/`) с **чеклистом заказчику**; DEMO_FEEDBACK: real-run строка + **UX-3** (повтор перекрывает форму email на Оформлении).

### Сессия 2026-07-21 (deploy Fly + MCP-приёмка Quick Repeat)

- Deploy: `bin/fly_deploy.sh` через WSL (fix: PATH к `~/.fly/bin`); release + миграции + smoke checks OK.
- Smoke: `/up` 200; `GET /shop/api/frequent_products` — 401 без сессии (канон Shop::Api::Auth), 200 из браузерной сессии витрины.
- MCP (cursor-ide-browser + CDP): frequent_items засеяны fetch-стабом (у стенда нет клиентов с историей mobile-заказов); секция «повторить» в peek/expanded, «+ещё» → expanded, «повторить в 1 клик» → hidden + 3 позиции (+304₽), «оплатить в 1 клик» → checkout + шит оплаты (гость → «Укажите email», канон). Артефакт `fly_acceptance_mcp_2026-07-21.json`, 6 скринов `screenshots/fly_acceptance/`.
- Находки: UX-1 (empty 12vh клипает секцию), UX-2 (peek 2+ — повтор вытесняет карточки корзины) → DEMO_FEEDBACK open, решение владельца.

### Сессия 2026-07-21 (PHASE 3: REVIEW Quick Repeat)

- Sanity: rubocop 12 файлов фичи 0 offenses; N+1 нет (pluck + index_by, `coffeeos-performance` соблюдён); RLS-регрессия 123/0.
- Регрессии зон: оплата §2.3 + one_click step4 29/0 (2 pre-existing skips), шторка+каталог 27/0, F1–F5 21/0.
- Ops: CHANGELOG (сводка фичи), HANDOFF (таблица статуса + решения для приёмки), todo.md PHASE 3 закрыта.

### Сессия 2026-07-21 (F5 — «оплатить в 1 клик» на секции повтора)

- Scope-решение (go владельца): кнопка = позиции повтора в корзину → checkout с автооткрытым шитом оплаты (флаг `shop_repeat_autopay` в sessionStorage); списание — существующий канон one_click с подтверждением «Оплатить», молча деньги не снимаем, бэкенд оплаты не тронут.
- RED `ad620b8`: `test/integration/shop/quick_repeat_pay_one_click_test.rb` — 4 теста (store repeatPayOneClick + REPEAT_AUTOPAY_KEY + push("/checkout"), кнопка в секции, consume-флаг в Checkout, mirror).
- GREEN: store 119 строк (сжаты комментарии под лимит 120); кнопка `shop-repeat-pay-one-click`; `Checkout.svelte` onMount — минимальный дифф (consume флага → `openPaymentSheet()`).
- Тесты: F1–F5 **21 runs / 192 assertions / 0 failures**; **регрессия оплаты §2.3 + one_click step4: 29 runs / 0 failures (2 pre-existing skips)** — симуляция T-Bank локально (FakeTbank, SHOP_SIMULATE_PAYMENT); шторка+каталог **27 runs / 0 failures**; svelte compile + esbuild OK.
- Pre-existing: `checkout_ui_cleanup_test.rb` конфликтует с каноном «оплата через шторку» (падает и на чистом HEAD) → 🟡 ISSUES, чинить отдельным шагом.

### Сессия 2026-07-21 (F4 — «повторить в 1 клик» / «+ещё» / тосты)

- RED `29dacad`: `test/integration/shop/quick_repeat_actions_test.rb` — 4 теста (repeatAllToCart с сохранёнными модификаторами и счётчиками, repeatMore → expanded, repeatFeedback-тосты, кнопки/тост в секции, фиксация кастомизации Product cart_line, mirror контракта).
- GREEN: `frequentRepeatStore.js` (101 строка) — `repeatAllToCart` (последовательный `addToCart` с `modifier_options.selected_modifiers` + qty из F3-счётчиков; успех → MODE_HIDDEN + success-тост; ошибка → error-тост, режим не меняется), `repeatMore` → MODE_EXPANDED, `repeatFeedback`; `RepeatSection.svelte` (134 строки) — оранжевая «повторить в 1 клик» с busy-guard, «+ещё», тост с автоскрытием 2.5с.
- Тесты: F1–F4 **17 runs / 166 assertions / 0 failures**; регрессия шторки+каталог **27 runs / 265 assertions / 0 failures**; esbuild + svelte compile OK.

### Сессия 2026-07-21 (F3 — счётчики карточек повтора + localStorage)

- RED `abac6eb`: `test/integration/shop/quick_repeat_counters_test.rb` — 5 тестов (qty-ключ в кэше, store `frequentQuantities`+`setFrequentQty` с clamp и персистом, RepeatSection на store, фиксация клика каталога → Product, mirror clamp). Решение: конфликт ТЗ Шаг 9 (клик → сразу в корзину) vs Шаг 12 (клик → модалка модификаторов) — оставлен канон Product, вопрос заказчику.
- GREEN: `shopFrequentCache.js` + `FREQUENT_QTY_KEY`/read/writeFrequentQty; `frequentRepeatStore.js` (61 строка) + `frequentQuantities`/`setFrequentQty` (Math.max(1,…), синхронная запись) + восстановление в init; `RepeatSection.svelte` — bump через store.
- Тесты: F1–F3 **13 runs / 116 assertions / 0 failures**; регрессия шторки+каталог **27 runs / 265 assertions / 0 failures**; esbuild + svelte compile OK.

### Сессия 2026-07-21 (F2 — секция «повторить» в CartSheet)

- RED `92274e2`: `test/integration/shop/quick_repeat_section_test.rb` — 4 теста (разметка RepeatSection, слоты в CartSheet empty/peek/expanded и НЕ hidden, один drag-handle, mirror видимости).
- GREEN `71ab631`: новый `app/frontend/components/RepeatSection.svelte` (до 3 карточек из `frequentItems`: thumb/«Нет фото», line-clamp, цена оранжевым, локальный счётчик −1+); в `CartSheet.svelte` — import, `initFrequentFromCache()` + `refreshFrequentProducts()` в onMount, слоты `shop-repeat-slot-empty/peek/expanded` перед checkoutBar. Канон высот и hidden-чипы не тронуты.
- Тесты: F2 **4 runs / 48 assertions / 0 failures**; регрессия шторки (heights canon, b113, checkout UX, F1 cache) **24 runs / 263 assertions / 0 failures**; svelte compile обоих файлов OK.
- Решение: в hidden секция не рендерится (там канонные чипы корзины) — сверить с заказчиком на приёмке. Отложено в F4: синк счётчика с localStorage + add-to-cart.

### Сессия 2026-07-21 (PHASE 1: SPEC Quick Repeat Bottom Sheet — docs only)

- `todo.md` переписан под фичу: пары RED/GREEN — B1 сервис частых товаров · B2 категории (переиспользуем существующий API) · B3 кэш `shop/freq/…` TTL 30 мин + bust в `OrderCreator` (hot-path, минимальный дифф) · B4 `GET /shop/api/frequent_products` · F1 `shopFrequentCache.js` · F2 `RepeatSection.svelte` (peek/expanded/hidden, канон высот не трогаем) · F3 счётчики · F4 «повторить в 1 клик»/«+ещё» · F5 «полатить в 1 клик» (scope-вопрос).
- Маппинг ТЗ→стек: RSpec/Vitest → Minitest (`test/services/shop/`, `test/integration/shop/api/`); 401 для гостя → пустой массив (витрина гостевая, `Shop::CustomerSession`); Timecop → `travel_to`; tsc → eslint+svelte compile.
- Разведка: схема БД достаточна (`order_items.modifier_options` jsonb + `orders.customer_id/source/created_at`); `CartSheet.svelte` 514 строк → новая секция только отдельным компонентом; кэш-паттерн `Rails.cache` как в `categories_controller` (5 мин) — наш с TTL 30 мин.
- Код приложения не менялся.

### Сессия 2026-07-21 (intake Quick Repeat Bottom Sheet — без кода)

- ТЗ заказчика 1:1 → `customer_tasks/Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md` (12 TDD-шагов: backend сервис частых товаров + кэш + API, frontend bottom sheet peek/expanded/hidden + «повторить в 1 клик»).
- 6 скринов → `artifacts/quick_repeat_bottom_sheet/screenshots/` (01 peek+повтор, 02–03 expanded, 04–05 hidden, 06 «полатить в 1 клик») + README с привязкой подписей.
- Индексы: CBR (backlog + таблица задач №14), `customer_tasks/README.md`.
- Заметки агента в ТЗ: тестовые пути из ТЗ (RSpec/Vitest) не совпадают со стеком репо (Minitest/`test/`) — решение на SPEC; «оплата в 1 клик» на скрине 6 отсутствует в чек-листе шагов — уточнить scope; интеграция с существующей `CartSheet.svelte` (канон высот не ломать).
- Код приложения не менялся.

### Сессия 2026-07-21 (закрытие Bottom sheet expanded grid)

- Владелец поправил ТЗ («внутри сетки») и принял **текущий UX как канон**: expanded — 1-й ряд сетки каталога · peek — 2-й ряд · hidden — половина. Упоминания правок внутри шторки удалены из сценариев ТЗ.
- Фиксирующие тесты: `bottom_sheet_heights_canon_test.rb` (высоты 52/56·34/38·24 + prog26 · шторка без grid · каталог 8.5rem) — 3 runs / 0 fail. Намеренного RED нет: фича уже соответствует канону, тесты сразу зелёные.
- Регрессия cart sheet (8 файлов): **59 runs / 486 assertions / 0 failures**.
- Артефакты: скрин отклонённого grid-варианта `02_grid_in_sheet_rejected_2026-07-21.png`; статусы «закрыта» в CBR/README/ТЗ.

### Сессия 2026-07-21 (RESTART — откат grid из шторки)

- **Уточнение владельца:** «сетка 4 в ряд» в ТЗ относится к **каталогу на главной**, не к expanded-корзине; expanded остаётся горизонтальными строками (канон S2).
- Откат: `git checkout 273a43c^` для `CartSheet.svelte`, `cartSheetThresholds.js` (prog26) и 5 тестов; `bottom_sheet_expanded_grid_test.rb` удалён.
- Регрессия cart sheet после отката: **56 runs / 0 failures**.
- Текст заказчика в ТЗ-доке не тронут; в «Заметки агента» добавлен блок RESTART.
- Открытый вопрос до нового SPEC: вид каталога («4 в ряд» на 414px = карточки ~93px против текущих 8.5rem).

### Сессия 2026-07-21 (RED+GREEN+REVIEW Bottom sheet expanded grid)

- **RED `273a43c`:** `bottom_sheet_expanded_grid_test.rb` — 3 runs / 3 fail (ожидаемо).
- **GREEN `7683dee`:** `CartSheet.svelte` expanded-ветка → `grid-cols-4` + `overflow-y-auto`, карточки канон peek (фото → openEditCard, line-clamp-1, −/+ без «Удалить»); `CART_SHEET_BUILD` prog27; 5 старых тестов обновлены на новые testid.
- **Регрессия cart sheet (8 файлов):** 59 runs / 478 assertions / **0 fail**. Svelte compile OK (5 a11y warn — класс pre-existing). Rubocop новых правок чист (3 offenses — старые строки s2a, не трогали).
- **ISSUES:** 🟡 полный `test/integration/shop/` завис локально после 43 тестов (env Windows) — обход: таргетные списки; локализация по go.
- **Vite build:** зациклился локально («Building with Vite» рекурсия vite-plugin-ruby на Windows) — компиляцию проверили через svelte/compiler напрямую.

### Сессия 2026-07-21 (PHASE 1: SPEC Bottom sheet expanded grid — docs only)

- `todo.md` переписан под фичу: RED/GREEN план, файлы (`CartSheet.svelte` expanded-ветка, `SHEET_VH.expandedMulti`).
- Решения владельца: размеры = канон peek (~118px, gap-2); «Удалить» из карточек сетки убрать («−»=1 удаляет), финал за заказчиком; шторка остаётся 414px; вместо tsc — линт+Vite build.
- Код приложения не менялся.

### Сессия 2026-07-21 (intake Bottom sheet expanded grid — без кода)

- ТЗ заказчика 1:1 → `customer_tasks/Bottom Sheet expanded mode и внутренняя сетка 4 в ряд.md`.
- Скрин заказчика → `artifacts/bottom_sheet_expanded_grid/01_customer_expanded_current_2026-07-21.png` + README.
- Строки в CBR (backlog + таблица задач, №13) и `customer_tasks/README.md`.
- Разведка: работа — ветка `MODE_EXPANDED && count >= 2` в `CartSheet.svelte` + `SHEET_VH.expandedMulti`; по скрину Шаг 1 (высота) уже близок к цели.
- Код приложения не менялся.

### Сессия 2026-07-21 (правило customer intake — без кода)

- Новое правило `.cursor/rules/workflow/coffeeos-customer-intake.mdc` (alwaysApply): текст заказчика → док 1:1 в `customer_tasks/`, артефакты в `artifacts/<slug>/` (slug латиницей, понятные слова), строка в CBR, коммит `docs: intake …`, стоп до `go` → PHASE 1: SPEC.
- `RULES_INDEX.md` — строка в таблицу workflow.
- Код приложения не менялся.

### Сессия 2026-07-20 (CHECKPOINT docs — без кода)

- Скрин `04_fly_accepted_hidden_chips_2026-07-20.png` · `CHECKPOINT.md`
- UI-код точки: `a1abfa0`. Код не меняли.

### Сессия 2026-07-20 (catalog size + sheet heights + hidden chips)

- CategorySection `w-[8.5rem]`; SHEET_VH expanded/peek/hidden; Hidden миниатюры; B1.13-S2 канон.
- Тесты: 53 runs / 0 fail (catalog_hidden + b113 s2/s2a/s4 + checkout ux).
- Push/deploy — владелец.

### Сессия 2026-07-20 (fix fly:release ConcurrentMigrationError)

- Deploy abort: `db:migrate:queue` lock busy ×5 (Neon shared URL + empty queue migrate).
- Fix: named SolidSchemaConnection; skip empty migrates; on lock+marker → WARN skip.
- Test: `fly_release_test` PASS. Деплой — владелец.

### Сессия 2026-07-20 (fix Hidden photos for Fly)

- **CartSheet:** onerror → `shop-cart-line-thumb-empty`
- **Rake:** `demo:catalog_images` (Unsplash HTTPS) — прогнан локально на demo-point-a
- **Не деплоим** — деплой заказчик/владелец сам
- **Урок:** local MCP с uploads ≠ приёмка на Fly

### Сессия 2026-07-20 (Hidden Fly deploy v368)

- **Push:** `develop` → `7505912`
- **Deploy:** 1-й fail `ConcurrentMigrationError` solid cache lock → retry → **v368** OK
- **Image:** `deployment-01KXZYCJN44WFB2M0JP5CQXTBS` · web checks passing
- **Стоп:** заказчик проверяет на https://coffeeos.fly.dev

### Сессия 2026-07-20 (SBR PHASE 3 REVIEW — Hidden mode cards)

- **Код:** `CategorySection.svelte` — media aspect-[4/3], object-cover object-top, onerror→«Нет фото», truncate, `data-catalog-card-mode` + `cartSheetMode`
- **Тесты:** `catalog_hidden_card_test` **7 runs / 0 fail**
- **Sanity:** UI-only · RLS/N+1 N/A · файл 89 строк · CartSheet peek/expanded не меняли
- **Регрессия shop:** 311 runs / 8 fail **pre-existing** (не этот шаг)
- **Коммиты:** RED `986c304` · GREEN `71d6eb6`
- **Стоп:** апрув заказчика / MCP Fly / deploy — только по **go**

### Сессия 2026-07-20 (SBR PHASE 1 SPEC — Hidden mode cards)

- **Режим:** Spec-Build-Review (`spec-build-review.mdc`)
- **ТЗ:** [`Исправление режима отображения Hidden…`](../../milestones/veha_2/requirements/customer_tasks/Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md)
- **todo:** [`todo.md`](todo.md) — S1–S4 + edge; UI-only; peek/expanded не ломать
- **Анализ:** RLS/данные не трогаем; зона shop; точка касания `CategorySection.svelte` (+ тесты grep/DOM)
- **Стоп Gate 1:** ждать **go** → PHASE 2 RED (падающие тесты)

### Сессия 2026-07-20 (ТЗ Hidden mode — docs only)

- **ТЗ + скрины** зафиксированы · код не меняли
- **Снято:** стоп «апрув ТЗ» — владелец дал **go на SPEC**

### Сессия 2026-07-18 (UserCards deploy v366 + Fly MCP 3.4 + live attempt)

- **Deploy:** Fly **v366** verified (6a73473 на prod, redeploy не нужен)
- **Investigate:** `usercards_fly_payment_investigate_2026-07-18.json` — saved *5953+*8782; payment today `8878842078` failed без Pan/RebillId
- **MCP live:** «Новая карта» 4300*0777 save ON → «Отказ: смените карту» (prod terminal)
- **MCP скрин 8925:** `screenshots/usercards_phase34_live_2026-07-18_payment_sheet_two_cards.png`
- **Артефакт:** `usercards_phase34_mcp_2026-07-18.json` — PARTIAL_PASS
- **Стоп:** апрув скрина → go 3.5

### Сессия 2026-07-18 (UserCards deploy v366 + Fly MCP 3.4 — ранее)
- **Стоп:** апрув скрина 8925 → go 3.5

### Сессия 2026-07-18 (UserCards Фаза 3.3 — retry GetState RebillId)

- **Код:** `TbankPaymentSync#sync_for_rebill!` — 5× GetState
- **Тесты:** 26 runs payment/UserCards — 0 fail
- **Deploy:** v366 (3e9c0c3 fly_release retry)

### Сессия 2026-07-18 (SBR — spec-build-review + todo.md)

- **Правила:** `.cursor/rules/workflow/spec-build-review.mdc` — SBR ENGINE (SPEC→RED→GREEN→REVIEW)
- **Связка:** `docs/operations/session/todo.md` (живой чеклист); RED/GREEN substep в commit-ops / task-workflow

### Сессия 2026-07-18 (UserCards Фаза 3.2 — root cause 8866531465)

- **Скрипт:** `bin/usercards_fly_payment_root_cause.rb` · **артефакт:** `usercards_fly_payment_root_cause_2026-07-18.json`
- **Вердикт:** `OUR_FA_WITHOUT_REBILL_DELAYED_WEBHOOK_LATE` — retry GetState (3.3)

### Сессия 2026-07-18 (UserCards Фаза 3.1 — runbook привязки)

- **Runbook:** [`USERCARDS_SAVE_CARD_FLOW.md`](../../milestones/veha_2/runbooks/USERCARDS_SAVE_CARD_FLOW.md) — Init Recurrent → RebillId → SavedCardStore → 8925; **оплата ≠ привязка**.
- **ТЗ:** § Фаза 3 · runbooks/README.
- **Стоп:** апрув текста → **go** 3.2 root cause Fly.

### Сессия 2026-07-16 (UserCards — расследование 2-й оплаты aramfifa)

- **Скрипт:** `bin/usercards_fly_payment_investigate.rb` · **артефакт:** `usercards_fly_payment_investigate_2026-07-16.json`
- **08:42** `8866059239` — Pan *5953, RebillId ok.
- **09:56** `8866531465` — succeeded, save_card=true, **Pan/RebillId nil** (GetState тоже).
- **Стоп:** fix Init/recurrent new_card.

### Сессия 2026-07-16 (UserCards Фаза 2 — stacked checkout UX)

- **Docs:** ISSUES/HANDOFF — сняты ложные MCP PASS по stacked; checkout → код done, MCP pending.
- **Код:** `openCheckoutPayStack`; CartSheet peek strip; PaymentMethodsSheet `stacked` без backdrop; `prog25`.
- **Тесты:** `shop_checkout_cart_sheet_ux_test` — **5 runs, 0 fail**.
- **Стоп:** deploy Fly + MCP vs 1000008924/8925.

### Сессия 2026-07-16 (UserCards Фаза 1 — Fly приёмка после deploy v362)

- **Replay webhook** 0₽: aramfifa **MIR *5953** в `mobile_payment_methods` — PASS.
- **MCP:** корзина 2+3₽ (5₽), verified email, PaymentMethodsSheet «МИР Карта *5953» — PASS.
- **Новая оплата:** NOT_RUN (экономия).
- **Артефакты:** `usercards_fly_phase1_verify_2026-07-16.json`, `usercards_phase1_mcp_2026-07-16.json`, 2 PNG.
- **Стоп:** апрув заказчика.

### Сессия 2026-07-16 (UserCards Фаза 1 — fix persist)

- **Root cause:** webhook CONFIRMED+RebillId → `perform_later` при worker stopped; finalize/GetState без RebillId → payment succeeded, UserCards пусто.
- **Код:** `TbankController` perform_now; `fly.toml` SOLID_QUEUE_IN_PUMA; `OrderCreator` recurrent+save_card intent.
- **Тесты:** `shop_usercards_phase1_persist_test` 3 runs · callback+sync+review 22 runs — **0 fail**.
- **Стоп:** deploy Fly + E2E aramfifa.

### Сессия 2026-07-16 (UserCards Фаза 0 — Fly diagnose read-only)

- **Скрипт:** `bin/usercards_fly_diagnose.rb` → `usercards_fly_diagnose_2026-07-16.json`.
- **Release:** v361 · web started · **worker stopped**.
- **DB prod:** 14 card rows global; **aramfifa100@gmail.com → 0 cards**.
- **Payment:** `0a7e0f8e…` 2026-07-15 save_card=true succeeded — row не создан (H3b).
- **Env:** SHOP_SIMULATE=0; TBANK secrets present; bundle D1E05YN_ без inline pay.
- **Logs:** TbankCallbackJob enqueued CONFIRMED+RebillId; 0 hits payments/new_card.
- **ISSUES:** 🔴 UserCards save bug_13-23 открыт.
- **Стоп:** ждать **`go`** на Фаза 1 (backend fix).

### Сессия 2026-07-16 (MCP Fly — checkout UX после deploy)

- **URL:** `#/checkout` · tenant `2fdee1ac…` · viewport 390×844.
- **PASS:** peek 2 позиции (2₽+3₽) · нет «Способ оплаты»/«Оплатить →» · hint «+сумма в шторке».
- **PASS:** `+5₽` → `openPaymentSheet` → alert «Укажите email» (не форма карты сразу).
- **Бандл:** `application-D1E05YN_.js` — `shop:checkout-pay`, `prog24`, без inline pay strings.
- **NOT_RUN:** PaymentMethodsSheet (нет verified guest в MCP).
- **Артефакт:** `usercards_checkout_mcp_2026-07-16.json` + 2 PNG.
- **Стоп:** апрув заказчика.

### Сессия 2026-07-16 (checkout UX — только канон заказчика)

- **Проблема:** заказчик отклонил UX — нет peek позиций; была ложная «resolved» по grep/deploy v359.
- **ТЗ:** § **Канон UX checkout** — скрины заказчика > B1.13 «только каталог» > HANDOFF resolved.
- **Код:** `onCartSheetRouteChange` → `ensureCheckoutCartPeek` на `#/checkout`; убран inline «Оплатить →» / «Способ оплаты» из `Checkout.svelte`; оплата через `openPaymentSheet` + `CHECKOUT_PAY_EVENT`; `CART_SHEET_BUILD=prog24`.
- **ISSUES:** 🔴 reopen checkout sheet; старая resolved → superseded.
- **Тесты:** `shop_checkout_cart_sheet_ux_test` — refute «Оплатить →», assert peek canon.
- **Стоп:** push/deploy + MCP на Fly.

- Причина «нет шторки»: код был в `develop` **ahead 4**, на Fly стоял **v358** (FSM), без CartSheet peek/UserCards review.
- `git push origin develop` `511d79c..671ba86`.
- `fly deploy -a coffeeos --remote-only --depot=false` → image `deployment-01KXK3MZJS8KQWW29R6SPV6J7V`, **v359**.
- Smoke: `/up` 200 · `/shop` 200 · web checks passing.
- Бандл Fly: `Checkout-13ZTVigo.js` (`pb-[32vh]`, `payments/new_card`, `payment-methods-sheet`); `application-EFlHHrd0.js` (`shop:checkout-pay`, `shop-cart-peek-line`, `/checkout`).
- origin/develop = HEAD `671ba86`. **Стоп:** MCP / hard-refresh браузера.

### Сессия 2026-07-15 (UserCards review: БАГ-1/2/3)

- **БАГ-1:** `provider_data["save_card"]` + `SavedCardStore.allowed_for?` в webhook/GetState/call!.
- **БАГ-2:** `loadSavedCardsWithRetry` после 3DS; тумблер OFF только если список пуст.
- **БАГ-3:** brand BIN не по last4-only (`*5953` → CARD).
- Тесты: step1–6 + extremes + `shop_usercards_review_fixes` — **50 runs, 354 assertions, 0 fail**.
- **Стоп:** ждать **`go`** на push/deploy / повторный `/review`.

### Сессия 2026-07-15 (go: шторка+заказ на оформлении)

- `ensureCheckoutCartPeek` → MODE_PEEK на `#/checkout`.
- CartSheet `goCheckoutOrPay`: на checkout → `requestCheckoutPay` (откроет PaymentMethodsSheet).
- Checkout: pad `pb-[32vh]`, слушатель `CHECKOUT_PAY_EVENT`.
- Тесты: `shop_checkout_cart_sheet_ux` + b113 S2/S2b **18 PASS**; S3 **6 PASS**.
- ISSUES 🔴 закрыт (код). **Deploy / MCP — только по явному go.**

### Сессия 2026-07-15 (снят блокер B1.13: шторка на checkout)

- Причина жалобы «нет шторки»: B1.13 `{#if onCatalog}` скрывал CartSheet на `#/checkout`.
- Канон: скрины заказчика UserCards, **не** «B1.13 by design».
- `isCartSheetRoute` catalog+checkout; PaymentMethodsSheet z > CartSheet.

### Сессия 2026-07-15 (Pay FSM 0–7 + 3DS Client Error)

- `shopPayFsm` + `CheckoutPayButton` + `ThreeDsOverlay` + `shopPaySettle`.
- Close 3DS → CLIENT_ERROR «Отказ: смените карту»; Net Error State 7.
- Тесты FSM+extremes zone **30 PASS**. Vite PASS.
- Deploy `25b1c6a` OK. MCP: sheet empty + NewCard + FSM Default blue «Оплатить».
- Дальше: **приёмка заказчика**.

### Сессия 2026-07-15 (UserCards extremes)

- `TbankCallbackJob`: CONFIRMED+RebillId → `SavedCardStore` soft-fail.
- `NewCardPaymentService`: persist rescue → Success без `saved_card`.
- Checkout: нет `saved_card` → тумблер OFF; `isOfflineError` → «Нет сети: повторить».
- Тест: `shop_user_cards_extremes_test` **7 runs PASS**; step6+callback **21 runs PASS**.
- Deploy: `git push` + `fly deploy -a coffeeos --remote-only --depot=false` **OK** · `/up` 200 · shop 200.
- MCP: browser MCP **недоступен** в сессии; smoke: Checkout JS на Fly содержит «Нет сети: повторить» + `Failed to fetch`.
- Backlog: UI Client Error / 3DS overlay FSM — без go.

### Сессия 2026-07-15 (Шаг 6 — save_card=false)

- Тест: `shop_save_card_false_step6_test` — CONFIRMED без записи UserCards; Init `recurrent:false`.
- Checkout/toggle уже слали `save_card`; комментарий в `NewCardPaymentService`.
- Регрессия step1–6 + CBR: **47 runs, 322 assertions, 0 fail**. Vite PASS.
- **Стоп:** ждать **`go`** — extremes / MCP / апрув.

### Сессия 2026-07-15 (Шаг 5 — вторая карта)

- Checkout: «Новая карта» → RSA + `POST payments/new_card` + reload list.
- `SavedCardStore`: upsert without pan+exp / rebill duplicates; new cards on top.
- Тесты step1–5 + CBR: **44 runs, 297 assertions, 0 fail**. Vite PASS.
- **Стоп:** ждать **`go`** на **Шаг 6**.

### Сессия 2026-07-15 (Шаг 4 — 1 клик Charge)

- `charge` + `charge_recurrent` · `OneClickPaymentService` · `POST payments/one_click`.
- Checkout: saved card → one_click `{ card_id }` · NewCardForm не на этом пути.
- Тесты step1–4 + adapter + CBR: **60 runs, 301 assertions, 0 fail**. Vite PASS.
- **Стоп:** ждать **`go`** на **Шаг 5**.

### Сессия 2026-07-14 (Шаг 3 — список карт 1000008925)

- `GET /shop/api/user/cards` · filter expired · `PaymentMethodsSheet` · labels · Checkout wiring.
- Тесты step1–3 + CBR: **35 runs, 246 assertions, 0 fail**. Vite build PASS.
- **Стоп:** ждать **`go`** на **Шаг 4**.

### Сессия 2026-07-14 (Шаг 2 — Init→FinishAuthorize→UserCards)

- TDD green: `shop_new_card_payment_step2_test` + adapter + sync + step1 — **39 runs, 173 assertions, 0 fail**.
- Backend: `finish_authorize`, `SavedCardStore`, `NewCardPaymentService`, `POST payments/new_card`, `GET payments/card_config`.
- UserCards = `mobile_payment_methods` (без DDL).
- Frontend: `tbankCardFormat.js` + `tbankCardEncrypt.js` (RSA).
- Vite build PASS. Checkout UI wiring — **не в этом шаге** (Шаг 3).
- **Стоп:** ждать **`go`** на **Шаг 3**.

### Сессия 2026-07-14 (Шаг 1 — форма новой карты)

- TDD: red → green · `shop_new_card_form_step1_test.rb` **12 runs, 99 assertions, 0 fail**.
- Код: `app/frontend/lib/shopNewCardForm.js` · `app/frontend/components/NewCardForm.svelte`.
- Vite build PASS (tsc в проекте нет — JS/Svelte).
- ТЗ: Gherkin Шаг 1 отмечен `[x]` + Было/Стало.
- **Стоп:** ждать **`go`** на **Шаг 2**.

### Сессия 2026-07-14 (WIPE)

- Снесены старые customer_tasks (рекуррент + выбор оплаты), runbook, артефакты, dedicated код/тесты/роуты.
- Checkout снова базовый: OTP + redirect payment_url.
- Агент **не** опирается на старые коммиты/артефакты этой темы.
- **Регрессия wipe (перепрогон):** boot не висел (~25–30 с init) · payment/checkout **44 runs 0 fail** · shop API + order_creator **105 runs 0 fail 3 skip**.
- **Стоп:** ждать **`go`** на новое ТЗ.


### Сессия 2026-07-13 (B1.13 — cart sheet прижат к низу)







- Жалоба: peek корзины «висит в воздухе» (остаток `bottom: 3.5rem` под снятый бар).
- Фикс: `CART_SHEET_BOTTOM_REM=0`, build `prog21`.
- Тест: `b113_s2a_cart_sheet_acceptance_test.rb` 10 PASS.
- Запись: DEMO_FEEDBACK + B1_13.
- **Стоп:** ждать **`go` deploy** на Fly.




- MCP: `cursor-ide-browser` (chrome-devtools MCP недоступен).
- s01 PARTIAL · s02 FAIL · s03 FAIL · s04 ACCEPTED ACS · s05–s07 NOT_REACHED.
- **Стоп:** ждать **`go` deploy** (фиксы уже в develop).


- Владелец: 3DS = **ACS банка**, не SMS-keypad из макета s04.
- **Стоп:** ждать **апрув / `go` deploy** (не деплоить без go).


- **Стоп:** ждать **`go` deploy**.


- `SHEET_VH.peek` 42→30; peekOne 36; peekTwo 40; `sheetHeightVh(mode, count)`.
- Peek 1–2: полные карточки (`product_name`, mods, description, фото); ≥3 миниатюры.
- Cart JSON: `description`; Checkout: pad под sheet.
- **Стоп:** ждать **`go` deploy** → повтор MCP.


- Сопоставлены макеты s01–s07 с Fly v341 через MCP.
- **НЕ идентично:** s02/s03 карточки FAIL; s01 OTP; s04 ACS≠SMS; s05–s07 не достигнуты.
- **Стоп:** `go` на визуальный паритет (peek cards + vh).


- Fly **v341**: peek sheet на checkout **PASS**; footer disabled до email **PASS**; dual UI нет.
- **Стоп:** фикс `SHEET_VH.peek` или апрув заказчика на живую оплату с ручным скроллом.


- E7 delete card API — отложено (кнопка-обман убрана).
- **Стоп:** ждать `go` на deploy → живая оплата заказчиком.


- В ТЗ: все сценарии S1–S7 + E1–E10 отмечены `[x]`.
- **Стоп:** апрув → `/review`.


- В ТЗ customer_tasks добавлен отчёт Было/Стало по S1–S7 + E1–E10.
- Галочки `[x]` в Gherkin — сделаны отдельным шагом.
- **Стоп:** апрув → независимый `/review`.


- `bin/rails test test/integration/shop/` — **304 runs, 2019 assertions, 0 failures, 0 errors, 3 skips**.
- **Стоп:** апрув на deploy для UI peek на Fly.


- Тест: **23 runs, 0 failures**. Коммит: `4740013`.
- MCP: Fly `coffeeos.fly.dev` checkout — старый UI (v340); новый peek только после deploy.
- **Стоп:** апрув на полный `test/integration/shop/` (регрессия).


- Прогон: **23 runs, 23 failures** (красная зона).
- Код UI не трогали.
- **Стоп:** ждать `go` на реализацию.


- Прогон: **13 runs, 13 failures** (красная зона).
- Код UI не трогали.
- **Стоп:** ждать `go` на реализацию.


- Git: вырезан блок старых checkout-sheet коммитов из `develop` (`rebase --onto`); force-push.
- Deploy: Fly `coffeeos` **v340** · image `deployment-01KX66W1GSN3SP6N4SDG1QY345` · `/up` **200**.
- **Стоп:** ждать `go` на реализацию с нуля.


- **Стоп:** ждать `go` на реализацию.


- **Код:** не трогали
- **Стоп:** ждать `go` на следующий шаг

### Сессия 2026-07-10 (product card peek — S4–S7 extremes)

- **S4:** `shop-product-peek-scroll` · `overflow-x: auto` · `touch-action: pan-x`.
- **S5:** peek не открывается при `items.length === 0`.
- **S6:** `enqueueBump` catch → refresh + `cartSheetError`; UI `shop-product-peek-error`.
- **S7:** `shop-product-out-of-stock` + peek `outOfStockProductId` → disabled ±.
- **Тест:** `product_card_s4_s7_peek_extremes_test.rb` — 9 PASS; S1–S3 регрессия PASS.
- **Типы:** JS/Svelte — typecheck N/A.
- **Стоп:** MCP Fly — ждать `go`.

### Сессия 2026-07-10 (product card peek — S3 ±1 qty edit)

- **Код:** `ProductCartPeek.svelte` — −/+ через `bumpCartLine` / `removeCartLine` (как CartSheet); `stopPropagation` на кнопках.
- **Тест:** `product_card_s3_peek_qty_edit_test.rb` — 6 runs PASS.
- **ТЗ:** галочка «редактирование количества» + критерии S3 `[x]`.
- **Типы:** фронт JS/Svelte без TS — отдельного typecheck нет.
- **Стоп:** S4 скролл / S5–S7 / MCP — ждать `go`.

### Сессия 2026-07-10 (product card peek — Шаг 5 отчёт Было/Стало)

- **ТЗ:** галочки S1+S2 `[x]`; отчёт Было/Стало + «не доделано» в customer_tasks.
- **Сделано:** индикатор + ProductCartPeek; shop 313 PASS.
- **Не сделано:** S3 ±1 · S4 свайп-приёмка · S5–S7 · MCP Fly.
- **Следующий шаг:** `go` на Сценарий 3 (или UI-проверка).

### Сессия 2026-07-10 (product card peek — регрессия shop suite)

- **Команда:** `bin/rails test test/integration/shop/`
- **Результат:** **313 runs, 2300 assertions, 0 failures, 0 errors, 3 skips** PASS
- **Фикс регрессии:** `b113_s4_cart_modifiers_test.rb` — assert «В корзину» → «добавить к заказу»
- **Стоп:** suite зелёный · ждать `go` на следующий шаг (Шаг 5 / UI / S3)

### Сессия 2026-07-10 (product card peek cart — S1+S2 green / Шаг 4)

- **Код:** `Product.svelte` — `inOrderQty` + `data-testid="shop-product-in-order"`; кнопка «добавить к заказу».
- **Код:** `ProductCartPeek.svelte` — peek-list из `cartItems` (имя/qty/цена), gate по `items.length`.
- **Тесты:** S1 + S2 — **PASS** (4+4, 0 failures). Обновлён b113 assert копирайта кнопки.
- **Стоп:** ждать апрув → **Шаг 5** (полный suite shop).

### Сессия 2026-07-10 (product card peek cart — S2 red test)

- **Шаг 3 / Сценарий 2:** только тест (код Product/peek не трогали).
- **Тест:** `test/integration/shop/product_card_s2_peek_list_test.rb` — Gherkin peek-list на карточке: все позиции, имя/qty/цена из `cartItems`.
- **Прогон:** `bin/rails test test/integration/shop/product_card_s2_peek_list_test.rb` — **4 runs, 4 failures** (красная зона, ожидаемо).
- **Стоп:** апрув теста → `go` на Шаг 4 (код peek UI).

### Сессия 2026-07-10 (product card peek cart — S1 red test)

- **Шаг 1 / Сценарий 1:** только тест (код Product не трогали).
- **Тест:** `test/integration/shop/product_card_s1_in_order_indicator_test.rb` — Gherkin «уже в заказе: N» + реактивность `cartItems`.
- **Прогон:** `bin/rails test test/integration/shop/product_card_s1_in_order_indicator_test.rb` — **4 runs, 4 failures** (красная зона, ожидаемо).
- **Стоп:** апрув теста разработчиком → `go` на реализацию индикатора в `Product.svelte`.

### Сессия 2026-07-10 (product card peek cart — артефакты)

- **Новая задача:** [`отображение набранных позиций и функциональность в режиме pee.md`](../../milestones/veha_2/requirements/customer_tasks/отображение%20набранных%20позиций%20и%20функциональность%20в%20режиме%20pee.md) — карточка товара: индикатор «уже в заказе», peek с горизонтальным скроллом и ±1.
- **Артефакты:** `artifacts/product_card_peek_cart/screenshots/` — `concept_layout_wireframe.png`, `product_card_peek_mockup.png`.
- **Статус:** ТЗ готово · скрины сохранены · код не начат.

### Сессия 2026-07-08 (B1.13-S4 блок 1.1 — openEditCard по клику на картинку)

- **Код:** `cartSheetStore.js` — экспорт `openEditCard(line)` (переход с query `cart_line`) · `CartSheet.svelte` — отдельная кликабельная зона картинки в `MODE_EXPANDED` (`data-testid="shop-cart-expanded-product-image"`) + `stopPropagation()`.
- **Тесты:** `test/integration/shop/cart_expanded_image_open_edit_card_test.rb` — PASS.
- **Коммит:** `ae0fd0e`

### Сессия 2026-07-08 (B1.13-S2/S2.1 — динамический total на кнопке + undo/error)

- **Код:** `CartSheet.svelte` — кнопка `shop-cart-sheet-checkout` теперь показывает `+X₽` из `cartTotal` (вместо `Оформить`/`+цена`), отключается при `total == 0`; добавлены блоки `shop-cart-undo` и `shop-cart-error`.
- **Store:** `cartSheetStore.js` — реактивные стейты `cartUndoLine`, `cartSheetError` + `undoRemoveCartLine()`, установка `cartSheetError` в `refreshCartSheet()` при ошибке.
- **Тесты:** `test/integration/shop/cart_checkout_button_total_dynamic_test.rb`, обновлён `test/integration/shop/b113_s2_cart_popup_test.rb`.
- **Прогон:** `bin/rails test test/integration/shop/cart_checkout_button_total_dynamic_test.rb` — PASS.
- **Коммит:** `e1f34eb`

### Сессия 2026-07-08 (B1.13-S2 экстремумы — авто-шрифт + товар недоступен)

- **Код:** `CartSheet.svelte` — `checkoutButtonFontSizePx(total)` для авто-уменьшения шрифта на больших суммах (без изменения геометрии кнопки).
- **Store:** `cartSheetStore.js` — при ошибке `Товар недоступен` корзина очищается вместо кэша, `shop-cart-error` показывает нормализованное сообщение.
- **Тесты:** `cart_checkout_button_total_dynamic_test.rb` — PASS.
- **Коммит:** `ff0a42c`

### Сессия 2026-07-09 (B1.13 — сумма только внутри кнопки checkout)

- **Код:** `CartSheet.svelte` — убран серый span `roundPrice(total)₽` рядом с кнопкой в `checkoutBar`; `data-testid` суммы перенесён внутрь кнопки.
- **Тесты:** `cart_checkout_button_total_dynamic_test.rb` + b113_s2/s2a/s4_b3 — PASS.
- **Коммит:** `46e8f0b`

### Сессия 2026-07-05 (batch апрув — задачи со скринов трекера)

- **Апрув:** B1.4 PWA · B2-S1 звук · B1.11 эпик+overnight · B1.14 client · B1.13-S1.
- **ISSUES:** B1.11-BUG-OVERNIGHT → resolved.
- **Артефакт:** `customer_verified_batch_2026-07-05.json` + 5 approval JSON.

### Сессия 2026-07-05 (B1.11-BUG-OVERNIGHT Fly MCP post-deploy)

- **Fly:** `coffeeos.fly.dev/up` OK · deploy commit `546a9f1`.
- **MCP:** create точки пн 09:23–01:24 → «Точка создана» · tenant `af4f78d6-c66b-428e-8ee4-5a609c5c9131`.
- **Edit verify:** mon enabled · 09:23/01:24 · без validation error.
- **Артефакты:** `b111_bug_overnight_fly_post_deploy_2026-07-05.json` · 3 скрина Fly.
- **Стоп:** апрув заказчика.

### Сессия 2026-07-05 (B1.11-BUG-OVERNIGHT fix + MCP)

- **Код:** `TenantWeekdaySchedule` overnight · `TenantOperatingHours#open_now?` overnight · тесты.
- **Тесты:** 36 runs, 121 assertions, 0 failures.
- **MCP Chrome DevTools:** login УК → create точки пн 09:23–01:24 → «Точка создана» · tenant `b5830353-42d4-4321-a8c9-5e9efd2bb071`.
- **Артефакты:** `b111_bug_overnight_mcp_2026-07-05.json` · 3 скрина.
- **Стоп:** A1 deploy Fly + апрув заказчика.


- **Fly:** release **v327** · `2026-07-02T12:36:14Z` · image `deployment-01KWHD36…`
- **Git на стенде (по ops):** `origin/develop` **`2a34ada`** — в истории R1 `18c7a45`, R2 `776a495`, R3 `c27eb7c`, RSA `0390ca5`
- **Стоп:** ждём `go` на **D2**


- **ISSUES:** 🔴 open.
- **Не трогали:** код app/.


- **Не трогали:** app/, гемы, баг-фикс карты.

### Сессия 2026-07-03 (security hygiene — permit! + gem CVEs)

- **Код:** `weekday_schedule_params` — строковые ключи `"0".."6"`, без `permit!`.
- **Тесты:** `tenants_controller_test` 5/5 · `tenant_weekday_schedules_sync_test` 3/3 · shop integration 249 runs 0 failures · `b114_tenant_map_test` PASS.
- **Гемы:** rack 3.2.6, rack-session 2.1.2, view_component 3.25.0.
- **Не в scope:** onboarding_* integration (422 без weekday_schedules в payload) — pre-existing, не регрессия permit.

### Сессия 2026-07-03 (Sentry RUBY-9 — manager orders show)

- **Sentry triage** (9 issues): главный шум — Neon `compute time quota` (RUBY-Q/M/N/K/P/R, ~153 events, 2wk ago); квота оплачена, сайт живой.
- **Код-баг RUBY-9:** `Manager::OrdersController#show` — `includes(:product)` на `OrderItem` без ассоциации → 500.
- **Фикс:** `@items = @order.order_items` (product_name — снимок, не join).
- **Тест:** `test/integration/manager/manager_orders_show_test.rb` — 1 run, 6 assertions, 0 failures.

### Сессия 2026-07-02 (B1.13 S4 MCP browser — финальная приёмка)

- **MCP Puppeteer** браузерная проверка 12/12 checks PASS.
- push `develop` → `2a34ada`; `fly deploy coffeeos` → deployed.
- S4-b1: `role=button cursor=pointer` на картах; tap → `#/product/:id?cart_line=N`.
- S4-b2: edit mode кнопка «Сохранить», qty=2 prefilled; сохранение → каталог.
- S4-b3: 4 товара → `[data-testid=shop-cart-peek-dots]` FOUND, точки видны.
- S2 регрессия: `gesture_zone` FOUND, `height=30vh`, `mode=peek`.
- Артефакт: `b113_s4_post_deploy_2026-07-02.json` обновлён (MCP browser checks).

### Сессия 2026-07-02 (B1.13 S4 блок 4 — приёмка)

- `b113_s4_cart_modifiers_test.rb`: 24 runs, 92 assertions, 0 failures — полная S4-приёмка (tap/edit/dots/price).
- Регрессия B1.13-S2+S3+S4: **114 runs, 695 assertions, 0 failures** (все b113_s* файлы).
- **Коммиты:** `6121f90` (тест), `c059fe4` (артефакт)

### Сессия 2026-07-02 (B1.13 S4 блок 3 — dots)

- `CartSheet.svelte`: `peekScrollIndex`, `onPeekScroll`, точки под скроллом (peek 4+, оранжевый/серый, transition).
- Тест: `b113_s4_b3_peek_dots_test.rb` 12 runs; регрессия S2/S3/S4-b1 16 runs OK.
- **Коммит:** `044f460`

### Сессия 2026-07-02 (B1.13 S4 блок 2 — edit mode)

- `CartService#replace_line!` — замена модификаторов + слияние при совпадении сигнатуры.
- `CartController#update` — ветка `selected_modifiers` → `replace_line!`; `delta` — без изменений.
- `Product.svelte` — `parseCartLine()`, `editMode`, `initSelectedFromCartLine()`, PATCH-ветка в addToCart, кнопка «Сохранить».
- Тесты: `cart_service_replace_line_test.rb` 6 runs; `b113_s4_b2_product_edit_test.rb` 15 runs; регрессия S2/S3/CartService OK.
- **Коммит:** `e87faeb`

### Сессия 2026-07-02 (B1.13 S4 блок 1 — tapToProduct)

- CartSheet.svelte: `tapToProduct(line, e)` — tap по карточке (peek 2+, expanded 2+, single) → `/product/:id?cart_line=N`.
- Кнопки ± исключены через `e.target.closest("button")`, gestureZone не тронут.
- test: `b113_s4_tap_to_product_test.rb` 16 runs зелёных · регрессия S2/S3: 9 runs OK.
- **Коммит:** `8ac3f0b`

### Сессия 2026-07-01 (B1.13 docs: S4 rev0b)

- Уточнения владельца: edit только Product · tap вся карточка · PATCH modifiers · слияние строк.
- baseline S4, stage0, README, FLUTTER_API.
- Код не меняли.
- **Коммит:** `fe20065` · ops `6cc33c5`

### Сессия 2026-07-01 (B1.13 docs: S4 хвост — API + индексы)

- § S4-канон: API gap (PATCH только delta) · поток 1+ позиция.
- CBR, README, HANDOFF — статус S4-канон docs.
- Код не меняли.
- **Коммит:** `efb69c3` · ops `263efba`

### Сессия 2026-07-01 (B1.13 docs: канон S4)

- § **S4-канон:** tap на карточку → Product + update line; режимы — только свайп; long press убран.
- Архив rev1 помечен; baseline S4, README, stage0 обновлены.
- Код не меняли.
- **Коммит:** `2c940e8` · ops `86680a0`

### Сессия 2026-07-01 (B1.13 docs: уточнения канона S2)

- Только docs: peek после add; свайп hidden→peek→expanded; Q-rev2; 1 товар скролл; модификаторы 2+ → S4.
- Код не меняли.
- **Коммит:** `62dfc3e`

### Сессия 2026-07-01 (B1.13 S1-R1: апрув)

- **S1-R1:** bottom bar 2 вкладки (Каталог + Избранное), без Корзины/Профиля — сверка + апрув владельца.
- **Q-rev2:** отложено — плейсхолдер пустой корзины до ответа заказчика.
- **Дальше:** **`go` S4**.

### Сессия 2026-07-01 (B1.13 docs: канон prog20 — хвосты)

- **Без изменений кода** — только docs/JSON/README/HANDOFF.
- **Канон:** § S2-канон = prog20 (peek horizontal · expanded vertical · vh 30/44).
- **Артефакты:** S2 baseline JSON, S4 baseline, MCP 2026-06-30 → SUPERSEDED.
- **testid:** задокументированы исторические имена; приёмка по `data-cart-layout`.
- **Коммит:** `9c147b5`


- **prog19 MCP (утро):** expanded=horizontal cards + Удалить — как на скрине; владелец: expanded должен быть vertical list.
- **prog20:** swap UI — peek=horizontal cards · expanded=vertical list + Удалить.
- **MCP post-deploy:** 21/21 · S2b-03 build=prog20 layout=vertical has_delete=true
- **Deploy:** `deployment-01KWEC4BRDSEK248M67X13NVKD` · `application-DwJhUPfQ.js`
- **Коммит:** `66c4352` · ops `d771184`

### Сессия 2026-07-01 (B1.13 prog19: код — **история, superseded prog20**)

- **vh:** peekMulti=30, expandedMulti=44.
- **UI (prog19, не канон):** PEEK 2+ vertical · EXPANDED 2+ horizontal — заменено prog20.
- **Add-flow:** `CART_JUST_ADDED_KEY` — peek после add, localStorage не перебивает.
- **Тесты:** b113_s2* — 36 runs, 0 failures.
- **Дальше:** deploy → MCP · апрув · S4
- **Коммит:** `d136f16` · ops `84847b7`, `283d12f`
- **Push:** `283d12f` → `origin/develop` ✓
- **Fly deploy:** `deployment-01KWEABJGANTFHS49XY11EKFBX` · bundle `application-DXnKClqo.js` · **build=prog19** ✓ · `/up` green
- **MCP:** ждём **go** владельца после ручной проверки

