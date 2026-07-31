# SESSION_STATE

## Текущее состояние

**Дата:** 2026-07-31 (PHASE 2 GREEN · Quick Repeat F1–F3)

| Сейчас | Дальше |
|--------|--------|
| **Quick Repeat** GREEN F1–F3 `[x]` — hasActiveOrder + CartSheet gate + Cable refresh | **go** → PHASE 3 REVIEW (+ layout full-width feedback 07?) |
| GREEN B1–B4 `[x]` | — |
| **#36** visual feedback 07 | full-width status sheet |

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
- **ТЗ:** [`Исправление режима отображения Hidden…`](../milestones/veha_2/requirements/customer_tasks/Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md)
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

- **Runbook:** [`USERCARDS_SAVE_CARD_FLOW.md`](../milestones/veha_2/runbooks/USERCARDS_SAVE_CARD_FLOW.md) — Init Recurrent → RebillId → SavedCardStore → 8925; **оплата ≠ привязка**.
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

- **Новая задача:** [`отображение набранных позиций и функциональность в режиме pee.md`](../milestones/veha_2/requirements/customer_tasks/отображение%20набранных%20позиций%20и%20функциональность%20в%20режиме%20pee.md) — карточка товара: индикатор «уже в заказе», peek с горизонтальным скроллом и ±1.
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

### Сессия 2026-06-30 (B1.13 docs: канон S2 — **история**)

- **Канон:** § **B1.13-S2-канон** — единственный источник раскладки, vh, testid, persistence.
- **Persistence:** после add → `peek`; localStorage — только возврат с Избранное/Профиль.
- **Финал:** раскладки закреплены **prog20** 2026-07-01 (docs cleanup).

### Сессия 2026-06-30 prog18 (cookie overflow + минус удаляет + SW networkFirst)

- **P5:** session cookie overflow при 3+ товарах с модификаторами → корзина чистилась. Фикс: в cookie только id модификаторов, name/price из БД в `json_lines`.
- **P1:** SW `/vite/` → `networkFirst` (свежий JS онлайн).
- Регрессия shop 220/0, оплата 3/3. MCP 20/20 PASS, build=prog18. Коммит: `1185d90`

### Сессия 2026-06-30 prog17 (SW cache fix: auto version от Vite manifest)

- **Корень:** `SHOP_PWA_CACHE_VERSION` был хардкод `b14-1` → SW раздавал старый JS через staleWhileRevalidate.
- **Фикс:** `pwa_controller.rb` теперь вычисляет версию как MD5[0..7] от Vite manifest.json — меняется автоматически с каждым деплоем.
- **no-store** на `/service_worker.js` маршруте.
- MCP 20/20 PASS. Коммит: `df03f37`

### Сессия 2026-06-30 prog16 (fix double-swipe: pointer mouse-only)

- **Корень бага:** браузер стреляет pointer (pointerType="touch") + touch события одновременно → двойной вызов collapseFromSwipe/expandFromSwipe.
- **Фикс:** `onPointerDown`/`onPointerUp` в CartSheet.svelte проверяют `e.pointerType !== "mouse"` → выходят. Touch-устройства теперь обрабатываются только через touchstart/touchend.
- **MCP результат:** 20/20 PASS — все свайпы, скроллы, раскладки, localStorage.
- **Коммит:** `7449ea3` · **Deploy:** prog16

### Сессия 2026-06-30 prog15 (раскладки — **история, superseded prog20**)

- **Цель прогона (устарело):** PEEK 2+ vertical · EXPANDED 2+ horizontal — не финальный канон.
- **vh (актуально):** peekMulti=**30**vh, expandedMulti=**44**vh — без изменений в prog20.
- **Файлы:** `CartSheet.svelte`, `cartSheetThresholds.js`.
- **Тесты:** 21 runs, 0 failures (`b113_s2_layout_gestures_test.rb`, `b113_s2a`, `b113_s2b`).
- **Коммит:** `43a8189`

### Сессия 2026-06-30 prog14 (двойной свайп touch+pointer)

- **Корень бага:** inline `onpointerdown/up` в Svelte-шаблоне + `addEventListener touchstart/end` в `$effect` — оба срабатывали при одном касании.
- **Эффект:** каждый свайп вниз = 2 вызова `collapseFromSwipe` → expanded→peek→hidden за одно касание.
- **Фикс prog14:** флаг `gestureActive`; touch-обработчики приоритетны и блокируют pointer; inline `onpointerdown/up/cancel` удалены из шаблона.
- **Тесты:** 21/21 pass (S2a/S2b/layout_gestures).
- **Коммит:** `9c43fdc`
- **Деплой:** ожидает push от пользователя.

### Сессия 2026-06-30 (B1.13 Fly MCP post-deploy prog12)

- **Fly:** `data-cart-sheet-build=prog12` ✓
- **Touch-свайпы 2+:** цепочка peek↔expanded↔hidden — **6/6 PASS**
- **Скролл 2+:** expanded→peek@100px, hidden@200px — PASS
- **Баг:** 1 товар + скролл 100px остаётся в peek (должен hidden) → **prog13** фикс в коде
- **Дальше:** deploy prog13 → re-MCP

- **MCP DevTools Fly (prog11):** цепочка свайпов peek↔expanded↔hidden **работает** (pointer)
- **Баг:** `touchstart/touchend` в `onMount` — `gestureZoneEl` был `null` → на телефоне свайп не срабатывал
- **Фикс:** `$effect` для touch listeners; gesture-zone всегда `min-h-14`; удалён `cartSheetLayoutCache.js`
- **MCP скрипт** `b113_s2a_s2b_rev2_mcp.mjs` — сверка с § S2-канон (не prog5)
- **Дальше:** deploy → `data-cart-sheet-build=prog12` на Fly

- **Док:** § **B1.13-S2-канон** — единственный источник раскладки/жестов поп-апа
- **Удалено:** § S2-prog5, rev1 S2 (монолит), противоречащие формулировки в S2a/S2b
- **Артефакты:** `b113_s2_screenshot_baseline`, README S2/S3/S4 → ссылка на S2-канон
- **Дальше:** re-MCP S2a/S2b по канону · апрув заказчика · S4

### Сессия 2026-06-30 (B1.13 prog11 hidden chip + Fly verify)

- hidden: vh 20, pill-чип «Корзина» + сумма + кнопка
- `data-cart-sheet-build=prog11` на шите
- **Дальше:** deploy → проверить `data-cart-sheet-build` на Fly

### Сессия 2026-06-29 (B1.13 prog10 канон layout + hidden chip)

- **PEEK 2+** vertical · **EXPANDED 2+** horizontal (откат prog9)
- **HIDDEN** — чип с суммой по ТЗ, шапки убраны
- Логика свайпов/скролла/1 товар — без изменений
- Тесты b113_s2* — PASS
- **Дальше:** deploy → проверка заказчиком


- **Финальный канон принят:** PEEK = дефолт (добавление), EXPANDED = только 2+ горизонтальные карточки, **HIDDEN = чип** (не шапки товаров)
- **Свайпы:** hidden↑→peek, peek(2+)↑→expanded, expanded↓→peek, peek↓→hidden
- **Удалён** `cartSheetExpandedLayout` и `EXPANDED_LAYOUT_*` — лишняя сложность
- **Пороги** скролла 100/200px восстановлены (по ТЗ заказчика)
- **Коммит:** `9177aed` — fly deploy запущен
- **Дальше:** ждать deploy → ручная проверка → апрув заказчика

### Сессия 2026-06-29 (B1.13 диагноз + flex layout bug)

- **Диагноз Fly MCP DevTools:** `gestureZone: false` — на Fly старый бандл без gesture-zone (prog5b не задеплоен)
- **Новый баг найден:** `h-[calc(100%-0.75rem)]` считал gesture-zone 12px, а она стала `min-h-11`=44px → overflow в hidden/peek; фикс: `flex flex-col overflow-hidden` на контейнере + `flex-1 min-h-0` на content-дивах
- **Коммит:** `829764b`
- **Fly deploy:** `829764b` + `e6c9a7b` задеплоены — MCP DevTools PASS (`gestureZone: true`, `flex column`, новый бандл `DiTk_YEX`)
- **Push:** `a889249` — PAT обновлён (+ workflow scope), push прошёл
- **passive fix:** `a889249` — `touchstart`/`touchend` через `addEventListener({ passive: false })`, свайп больше не блокируется браузером
- **prog6 fixes `6cdb5ed`:** vertical default at load, hidden flex-row heads (w-11 compact), gesture zone 56px, scroll thresholds 60/130px
- **Дальше:** deploy → ручная проверка → апрув заказчика

### Сессия 2026-06-24 (B1.13 прогон 5b: gesture-zone UX)

- **gesture-zone** min-h-11, SWIPE 32px, cold load → expanded vertical
- **Тесты** b113_s2* — PASS
- **Дальше:** deploy владельца → re-MCP → ручная проверка

### Сессия 2026-06-24 (B1.13 прогон 5: канон положений + жесты)

- **Канон:** § B1_13 «S2-prog5» — таблицы mode×layout×жест; gap прогонов 1–4 задокументирован
- **Код:** `cartSheetExpandedLayout` vertical|horizontal; expand/collapse по канону; 1 товар без peek
- **Тест:** `b113_s2_layout_gestures_test.rb` + b113_s2* — PASS
- **MCP:** скрипт обновлён (horizontal, 1-item hidden↔expanded); Fly `[ ]`
- **Дальше:** deploy → re-MCP → апрув → S4

### Сессия 2026-06-24 (B1.13: layout поп-апа по макетам + жесты)

> ⚠️ **Устарело** — актуальный канон § **B1.13-S2-канon** (hidden = чип).

- **Раскладка (история):** expanded 2+ — горизонтальный компактный список; peek — вертикальный список карточек; hidden — вертикальные «головки» (отменено)
- **Тест:** `b113_s2_layout_gestures_test.rb` + регрессия b113_s2* — PASS
- **Дальше:** redeploy → re-run MCP → апрув заказчика · S4

### Сессия 2026-06-27 (B1.13: MCP S2a/S2b 14/14 — swipe fix)

- **MCP:** `b113_s2a_s2b_rev2_mcp.mjs` — **14/14 PASS** (swipe: delta 72px + Pointer/Touch dispatch)
- **Код:** CartSheet — `pointercapture`, `touch-action: none`, `onpointercancel`
- **Артефакт:** `b113_s2a_s2b_rev2_post_deploy_2026-06-27.json` обновлён
- **Дальше:** redeploy CartSheet UX → апрув S2a/S2b · Q-rev2

### Сессия 2026-06-27 (B1.13 прогон 4: Fly MCP S2a/S2b)

- **MCP:** `b113_s2a_s2b_rev2_mcp.mjs` на `coffeeos.fly.dev` — **13/14 PASS**
- **Артефакт:** `b113_s2a_s2b_rev2_post_deploy_2026-06-27.json` + 6 скринов
- **Blocked:** S2b-03 swipe — на стенде нет pointer handlers; фикс `onpointerdown/up` в коммите → redeploy + re-run
- **Deploy:** владелец (предыдущий) + нужен повтор для swipe
- **Дальше:** redeploy → `node bin/b113_s2a_s2b_rev2_mcp.mjs` → 14/14

### Сессия 2026-06-24 (B1.13-S2a прогон 3: сверка приёмки с товаром)

- **Дотянуто:** peek — `shop-cart-peek-total` (сумма заказа); константы `SHEET_TRANSITION_MS`, `CART_SHEET_BOTTOM_REM`, `CART_SHEET_MAX_WIDTH_PX`
- **Код:** `setCartSheetMode` — программное переключение режимов
- **Тест:** `b113_s2a_cart_sheet_acceptance_test.rb` (9 tests) + регрессия S2/S2b — **26 runs, 0 failures**
- **Не трогали:** пустая корзина (Q-rev2) · deploy · Fly MCP
- **Дальше:** deploy + MCP прогон 4


- **Код:** `cartSheetModeCache.js` — ключ `coffeeos_shop_cart_sheet_mode_v1`, TTL `shopLocalStorage`
- **Код:** `cartSheetStore.js` — `onCatalogRouteChange`, persist на уходе, restore при возврате на каталог
- **Код:** `CartSheet.svelte` — hashchange → `onCatalogRouteChange`
- **Тесты:** `b113_s2b_mode_persistence_test.rb` (6 tests) + регрессия S2b/S2 — **17 runs, 0 failures**
- **Не сделано:** deploy · Fly MCP DevTools (прогон 4)
- **Дальше:** S2a сверка приёмки · deploy + MCP в конце

### Сессия 2026-06-24 (B1.13-S2b прогон 1: скролл 100/200 px)

- **Код:** `cartSheetThresholds.js` — `SCROLL_TO_PEEK_PX=100`, `SCROLL_TO_HIDDEN_PX=200`; убраны vh-пороги
- **Код:** `cartSheetStore.js` — `handleCatalogScroll`: hidden @200 до peek @100 (Q-rev3)
- **Тесты:** `b113_s2b_scroll_thresholds_test.rb` (3 tests) + регрессия `b113_s2_cart_popup_test.rb` — **11 runs, 0 failures**
- **MCP:** `b113_s2_cart_popup_mcp.mjs`, `b113_s3_cart_controls_mcp.mjs` — scroll 100+100 px (не Fly)

### Сессия 2026-06-26 (B1.13: убран Q-rev6 — peek S2a+S3 без противоречия)

- **B1_13:** Q-rev6 удалён; канон: peek = сумма/+цена (S2a) + +/- (S3-rev2, уже на Fly)
- **Дальше:** Q-rev2 → `go` S2a/S2b

### Сессия 2026-06-26 (B1.13 rev2 gate: ответы владельца Q-rev3/4)

- **Q-rev3:** 100px → peek, 200px → hidden (как док; подстройка на S2b)
- **Q-rev2:** открыт
- **Дальше:** Q-rev2 → `go` S2a

### Сессия 2026-06-26 (B1.13-S3-rev2: post-redeploy Fly MCP 12/12)

- **Deploy:** владелец (bump-queue `cartSheetStore` на стенде)
- **MCP:** повтор `b113_s3_cart_controls_mcp.mjs` — **12/12 PASS**
- **Артефакт:** `b113_s3_rev2_post_deploy_2026-06-26.json` (обновлён timestamp)
- **Дальше:** апрув S3-rev2 · `go` S2a/S2b

### Сессия 2026-06-26 (B1.13-S3-rev2: Fly MCP 12/12 PASS)

- **Deploy:** владелец 2026-06-26
- **MCP:** `bin/b113_s3_cart_controls_mcp.mjs` — expanded +/-, minus @1, Удалить, peek, checkout
- **Артефакт:** `b113_s3_rev2_post_deploy_2026-06-26.json` + 3 скрина
- **Фикс MCP:** retry bump, catalog `#/` для peek, API-empty на 04b
- **Фикс UI (локально):** очередь PATCH bump, minus/+ без `busy` disabled — **нужен redeploy**
- **Дальше:** апрув S3-rev2 · `go` S2a/S2b

### Сессия 2026-06-25 (B1.13-S3-rev2: +/- disabled @1, Удалить, optimistic UI)

- **Backend:** `CartService#update_quantity!` — qty&lt;1 → 404 «Минимум 1» (не удаляет строку)
- **Frontend:** `cartSheetStore` — `atMinQty`/`atMaxQty`, `optimisticBump`/`optimisticRemove`, `MODE_EMPTY` при последней позиции
- **UI:** `CartSheet` — minus disabled @1 (peek + expanded)
- **Тесты:** `b113_s3_rev2_cart_controls_test.rb` (6) + `cart_service_test` + `b113_s2_cart_popup_test` — **30 runs, 0 failures**
- **MCP:** `bin/b113_s3_cart_controls_mcp.mjs` обновлён (rev2 шаги 03b/03c/04b)
- **Дальше:** deploy владельца → `node bin/b113_s3_cart_controls_mcp.mjs` → `go` S2a/S2b

### Сессия 2026-06-25 (B1.13: КАНОН 2 вкладки + профиль в шапке — закрыто навсегда)

- **B1_13:** § **КАНОН** — bottom bar **Каталог + Избранное**; **Профиль › ID** только в шапке; «3 вкладки» в тексте заказчика **не приёмка**
- **Q-rev1 / Q-epic-1:** не переоткрывать

### Сессия 2026-06-25 (B1.13 rev2: 4 дока заказчика в B1_13)

- **Доки:** S1-R1 (bottom bar) · S2a (поп-ап 3 состояния) · S2b (скролл 100/200px) · S3-rev2 (+/-/Удалить/SLA) — **дословно**
- **Канон:** Q-rev1 закрыт — 2 вкладки + профиль в шапке
- **Открыто:** Q-rev2…6 до скринов и `go`
- **Дальше:** скрины rev2 → `go` S2a → S2b → S3-rev2

### Сессия 2026-06-25 (B1.13-S3: управление в поп-апе корзины)

- **Код:** `CartSheet` peek +/- · expanded +/- Удалить · hidden миниатюра · `MAX_ITEM_QUANTITY=99`
- **API:** guard max qty на `CartService#update_quantity!`
- **Тесты:** `b113_s3_cart_controls_test.rb` (5 критериев) + `cart_service_test` max qty
- **Макеты:** `b113_s3_customer_{peek,expanded,hidden_chip}_mode.png`
- **MCP pre-deploy:** `b113_s3_post_deploy_2026-06-25.json` — step 01 PASS · step 02 FAIL (нет `shop-cart-expanded-plus` на Fly)
- **Скрипт:** `bin/b113_s3_cart_controls_mcp.mjs`
- **Коммит:** `6fcc9d8`
- **Дальше:** deploy → повтор MCP PASS · `go` S4



### Сессия 2026-06-25 (B1.13-S2: фаза 3 Fly MCP PASS 9/9)

- **Deploy:** владелец · стенд `coffeeos.fly.dev`
- **MCP:** `b113_s2_cart_popup_mcp.mjs` — **9/9 PASS**
- **Артефакт:** `b113_s2_post_deploy_2026-06-25.json` + скрины 320/360/428
- **ISSUES:** deploy blocker → **resolved**
- **Дальше:** апрув заказчика S2 · `go` S3

### Сессия 2026-06-25 (B1.13-S2: фаза 3 MCP скрипт + pre-deploy probe)

- **Скрипты:** `bin/b113_s2_cart_popup_prep_fly.rb` · `bin/b113_s2_cart_popup_mcp.mjs`
- **Deploy:** **blocked** — `flyctl auth login` недоступен агенту
- **MCP probe:** 2/9 PASS на текущем Fly (pre-S2) · артефакт `b113_s2_post_deploy_2026-06-25.json`
- **ISSUES:** 🔴 deploy pending
- **Дальше:** владелец deploy → повтор MCP

### Сессия 2026-06-24 (B1.13-S2: фаза 2 автотесты)

- **Тесты:** `b113_s2_cart_popup_test.rb` — 8 runs · `b113_s1` — 5 runs · регрессия `test/integration/shop/` — 147 runs, 0 failures (после фикса b11_02 assertion)
- **Дальше:** фаза 3 Fly MCP + deploy


- **Коммит:** `c27eb7c`
- **Deploy:** владелец на `coffeeos.fly.dev`
- **Доки:** TBANK_RSA, CardHolder, legacy guard, Q-R2 → реализовано по v2
- **Дальше:** апрув заказчика · secret RSA на Fly


- **Тесты:** 32 runs, 296 assertions, 0 failures
- **Дальше:** фаза 3 Fly deploy + MCP


- **Checkout:** summary + шторка вместо `saved-card-block` / таб «Картой»
- **Дальше:** фаза 2 FSM 0–7


- **Дальше:** `go` R3 код


- **Тесты:** Rails 18 runs + node 6 tests + vite build — 0 failures
- **Хвост:** `TBANK_RSA_PUBLIC_KEY` на Fly · deploy после R3


- **Тесты:** 38 runs, 120 assertions, 0 failures
- **Дальше:** `go` R2 (документ 2)


- **Правило:** документ 1→R1→стоп · документ 2→R2→стоп · документ 3→R3 · один `go` на R





### Сессия 2026-06-24 (ops: fly_deploy WSL)

- **Проблема:** `./bin/fly_deploy.sh` из WSL `/mnt/c/` — `load build context` ERROR; retry → `docker.sock missing hostname`
- **Фикс:** `--remote-only` (как CI) · `unset DOCKER_HOST` · WSL `/mnt/*`: `git archive` + overlay uncommitted → `~/.cache/coffeeos-fly-deploy`
- **Доки:** `FLY_DEMO_STAND.md` §4 WSL · `bin/README.md`
- **Дальше:** владелец — `./bin/fly_deploy.sh` · B1.14-4 cart
| **B2.1 табло** | **ЗАКРЫТА** · апрув `[x]` 2026-06-18 | backlog фаза 2 в CBR |
| **B2.1 B2-S1** | CLOSED OPS · MCP 9/9 · deploy `[x]` · заказчик `[ ]` | апрув заказчика |
| **B1.1** | апрув `[x]` 2026-06-18 | — |
| **B1.7 checkout** | **ЗАКРЫТА** · апрув `[x]` 2026-06-04 | — |
| **B1.4 PWA** | код задеплоен · OPS_PASS · заказчик `[ ]` | апрув |
| **B2.2** | stage0 `[x]` · этап 1 `[ ]` | единый экран «Меню» |

### Сессия 2026-06-23 (B1.14-3d: карта на списке точек УК)

- **УК index:** `_tenants_index_map` · `tenants_map_controller.js` · `Platform::TenantsMapPins`
- **Shared:** `platform/leaflet_setup.js` (форма + список)
- **Тесты:** tenants_map_pins + b114_tenants_map_index — 4 runs (с 3c), 0 failures
- **Дальше:** deploy · B1.14-4 cart

### Сессия 2026-06-23 (B1.14-3c: карта Leaflet в форме точки УК)

- **УК:** `_tenant_map_fields.html.erb` — кнопка «Указать на карте» · lat/lng · Leaflet + OSM
- **Stimulus:** `tenant_map_controller.js` — клик по карте → координаты в форму
- **CSP/importmap:** `unpkg.com` для leaflet (без Яндекс-геокодера)
- **Карточка точки:** координаты в «Входы и URL»
- **Тесты:** `b114_tenant_map_test.rb` — 2 runs, 0 failures
- **Дальше:** deploy · B1.14-4 cart

### Сессия 2026-06-23 (B1.14-3b: дропдаун по городу + geo + demo C)

- **Миграция:** `tenants.latitude`, `tenants.longitude`
- **API:** `CustomerTenantHistory` — все `sales_point` в городе · сортировка: текущая → haversine → без координат
- **Сервис:** `Shop::TenantGeo` (normalize city, haversine)
- **Demo:** `demo-point-c` (org alt), координаты A/B/C, цены +0/+10/+20, разное расписание
- **Тесты:** tenant_geo + customer_tenant_history + b114 API + demo seed — **12 runs, 94 assertions, 0 failures**; b114 header — 2 runs, 0 failures
- **Дальше:** deploy владельца · B1.14-4 cart · Leaflet в УК — backlog

### Сессия 2026-06-23 (ops: Fly deploy Depot 401 → fix)

- **Проблема:** второй `fly deploy` — Depot builder `401 Unauthorized` при push образа (первый deploy прошёл, но без B1.14-3 на стенде).
- **Фикс:** `bin/fly_deploy.sh` (`--depot=false`) · `FLY_DEMO_STAND.md` § Depot 401 · CI `deploy.yml` · `INFRA_STACK.md`
- **Deploy:** `deployment-01KVT2DYNPBFBXC1JNHETRRQYZ` · release_command OK · `/up` 200 · bundle содержит `display_address` (B1.14-3)
- **Дальше:** Fly MCP скрины after · `go` B1.14-4

### Сессия 2026-06-23 (B1.14-3: Header адрес точки + дропдаун)

- **Frontend:** `Header.svelte` — `display_address` вместо CoffeeOS · дропдаун `/shop/api/tenants` · `shopTenantHeader.js` (localStorage, bootstrap redirect)
- **App.svelte:** `bootstrapShopTenant` при старте
- **Тесты:** `b114_header_tenant_address_test.rb` + b113 + b114 API — **10 runs, 75 assertions, 0 failures**
- **Дальше:** deploy → MCP скрины · B1.14-4 cart

### Сессия 2026-06-23 (B1.14-2: API tenant address + demo seed)

- **API:** `GET /shop/api/config` — `tenant`, `last_ordered_tenant_id` · `GET /shop/api/tenants`
- **Сервисы:** `Shop::TenantAddress`, `Shop::CustomerTenantHistory`
- **Seed:** `Demo::EnvironmentSetup` — city/address у demo-point-a/b
- **Тесты:** `bin/rails test test/services/shop/tenant_address_test.rb test/services/shop/customer_tenant_history_test.rb test/integration/shop/api/b114_tenant_address_api_test.rb test/integration/shop/api/config_controller_test.rb test/services/demo/environment_setup_test.rb` — **12 runs, 89 assertions, 0 failures**
- **Runbook:** `FLUTTER_API.md` — контракт B1.14
- **Дальше:** `go` на B1.14-3 (Header)

### Сессия 2026-06-23 (B1.14: скрины baseline заказчика)

- **Скрины:** `b114_shop_header_coffeeos_before` (витрина #1) · `b114_uk_tenants_card_before` (УК #2+#3)
- **Артефакт:** [`b114_screenshot_baseline_2026-06-23.json`](milestones/veha_2/artifacts/demo-feedback/b114_screenshot_baseline_2026-06-23.json)
- **README:** [`README_b114_baseline_2026-06-23.md`](milestones/veha_2/artifacts/demo-feedback/screenshots/README_b114_baseline_2026-06-23.md)
- **Дальше:** апрув ТЗ → `go` на код

### Сессия 2026-06-23 (B1.14: этап 0 — ТЗ адрес точки в шапке)

- **ТЗ:** [`B1_14_shop_tenant_address_header.md`](milestones/veha_2/requirements/customer_tasks/B1_14_shop_tenant_address_header.md) — текст заказчика дословно · scope · ответы владельца Q1–Q10
- **Артефакт:** [`b114_stage0_scope_2026-06-23.json`](milestones/veha_2/artifacts/demo-feedback/b114_stage0_scope_2026-06-23.json)
- **Ops:** CBR · README customer_tasks · CHECKLIST · HANDOFF · CHANGELOG
- **Код:** не начат · ждём апрув + `go`

### Сессия 2026-06-24 (B1.13-S2: фаза 1 код)

- **Файлы:** CartSheet, cartSheetStore, cartSheetThresholds, BottomNav, Catalog scroll, CartRedirect
- **Стоп:** фаза 2 — тесты + Fly MCP по команде

### Сессия 2026-06-24 (B1.13-S2: ответы + пропорции)

- **Ответы Q-S2-2…10** закрыты в `B1_13` · открытых вопросов нет
- **Пропорции (история):** expanded ~36–40% · peek ~16% · hidden ~9% — **заменено** vh-таблицей § S2-канон (30/44/20)
- **Скрины:** 4 макета на диске (повторно не копировали)

### Сессия 2026-06-24 (B1.13-S2: канон bottom bar)

- **Q-epic-1 закрыт:** 2 вкладки · профиль в шапке · опечатка в тексте S2
- **ТЗ:** `B1_13` — канон-блок + таблица приёмки CoffeeOS для S2

### Сессия 2026-06-24 (B1.13: чеклисты S2–S4)

- **ТЗ:** gate + чеклист реализации для S2, S3, S4 в `B1_13_shop_nav_profile_header.md`
- **S1:** Fly MCP в чеклисте `[x]`
- **Дальше:** `go` на S2

### Сессия 2026-06-23 (B1.13-S1: Fly MCP post-deploy)

- **MCP chrome-devtools:** 5/5 критериев PASS на `coffeeos.fly.dev`
- **Проверки:** нет «Витрина» · шапка «Профиль» (гость) · bottom nav Каталог/Корзина/Избранное · клик → `#/profile` 101 ms · экран «Гость»
- **Артефакт:** [`b113_s1_post_deploy_2026-06-23.json`](milestones/veha_2/artifacts/demo-feedback/b113_s1_post_deploy_2026-06-23.json)
- **Скрины:** `b113_s1_post_deploy_{320,360,428,profile}_2026-06-23.png`
- **Дальше:** апрув заказчика S1

### Сессия 2026-06-22 (B1.13-S4: макеты модификаторы + горизонтальный скролл — 3 скрина)

> ⚠️ **Устарело** — горизонтальный скролл >3 товаров: канон **expanded** (§ S2-канон), не peek.

- **Скрины (иллюстрация):** peek >3 · chip · expanded — сверять с § S2-канон.
- **Артефакт:** [`b113_s4_screenshot_baseline_2026-06-22.json`](milestones/veha_2/artifacts/demo-feedback/b113_s4_screenshot_baseline_2026-06-22.json).

### Сессия 2026-06-22 (B1.13-S3: макеты управления в поп-апе — 3 режима)

- **Скрины:** peek (−/+ под миниатюрами) · expanded (Удалить, модификаторы) · hidden chip.
- **Артефакт:** [`b113_s3_screenshot_baseline_2026-06-22.json`](milestones/veha_2/artifacts/demo-feedback/b113_s3_screenshot_baseline_2026-06-22.json).

### Сессия 2026-06-22 (B1.13-S2: макеты поп-апа корзины — 4 скрина)

- **Скрины:** empty · expanded×1 · expanded↔peek · expanded multi + свайп.
- **Ключ:** внизу у нас сейчас 4-tab bar с «Корзина»; у заказчика — **поп-ап заказов** над баром.
- **Артефакт:** [`b113_s2_screenshot_baseline_2026-06-22.json`](milestones/veha_2/artifacts/demo-feedback/b113_s2_screenshot_baseline_2026-06-22.json).

### Сессия 2026-06-22 (B1.13-S1: baseline скрин заказчика #1)

- **Скрин #1:** каталог витрины — шапка **CoffeeOS + «Витрина»**, PWA-баннер, секции меню.
- **Артефакт:** [`b113_s1_catalog_before_2026-06-22.png`](milestones/veha_2/artifacts/demo-feedback/screenshots/b113_s1_catalog_before_2026-06-22.png) · [`b113_s1_screenshot_baseline_2026-06-22.json`](milestones/veha_2/artifacts/demo-feedback/b113_s1_screenshot_baseline_2026-06-22.json).
- **Дальше:** скрин #2 bottom nav с «Профиль» · апрув + `go` S1.


- **Репорт:** после deploy заказчика — 2-я оплата снова Т-Банк снизу, нет «Сохранённая карта».


- **Было:** Т-Банк embed снизу на checkout (скрин заказчика).
- **Тест:** 15/15 PASS local (checkout, r2, settle, r3, recurrent).
- **Дальше:** **deploy Fly** · MCP post-deploy · real-card 1→2.


- **Баг:** 2-я оплата — снова iframe Т-Банка; нет saved card на checkout.
- **Тест:** 17/17 PASS local (settle, r3, checkout, recurrent, sync).




- **Deploy:** владелец · `75dc252` на coffeeos.fly.dev.


- **Сделано:** снят `Payment.svelte`, маршрут `/payment` из `App.svelte` — оплата только на `#/checkout`.
- **Тест:** shop integration 18 runs, 159 assertions, 0 failures.


- **Deploy:** владелец на Fly (`783b4ff`).


- **Ошибка:** R2/R3 сдали без снятия 3 экранов — заказчик прав.
- **Сделано:** inline pay на checkout, кнопка статусов, без `push("/payment")`.
- **Дальше:** deploy → MCP → апрув.


- **Fly MCP:** tenant `2fdee1ac-…` — immediate `#/order/:id` · poll webhook → redirect · finalize POST в network.
- **Дальше:** апрув заказчика · real-card.


- **Дополнение к шагу 2:** `payment_started` · `awaiting_settlement` после return из 3DS.
- **deepLinkRedirectCallback:** не меняли (full redirect); resume через sessionStorage.
- **Тест:** 2/2, 19 assertions PASS.
- **Дальше:** deploy → Fly MCP repro (шаг 3 return path).


- **Deploy:** владелец на Fly.
- **MCP:** tenant `2fdee1ac-…` — order→callback→accepted→finalize `payment_settled` PASS.
- **ISSUES:** 🔴 → **resolved**.


- **Было:** UI зависает — `finishSuccess()` только из `integration.js`; embed fallback молчит.
- **Стало:** `Payment.svelte` → `beginSettlementWatch()` (poll finalize 1.5s + cable) → `finishSuccess()` → `#/payment-result`.
- **Бэкенд:** `POST /callbacks/tbank` → accepted → finalize `payment_settled` (тест callback).
- **Не делали:** fly deploy, MCP на tenant заказчика.
- **Дальше:** **go deploy** → repro.

### Сессия 2026-06-19 (B1.11 Fly MCP post-deploy)

- **Deploy:** владелец → `coffeeos.fly.dev`.
- **Fly MCP:** `/up` 200 · categories `meta.operating_hours` (is_open=true) · витрина B каталог · barista-b табло · gm-b shifts · uk «Режим работы» на edit.
- **Тест:** `ruby bin/rails test` b111 suite — **37 runs, 122 assertions, 0 failures**.
- **Артефакт:** [`b111_operating_hours_post_deploy_2026-06-19.json`](milestones/veha_2/artifacts/demo-feedback/b111_operating_hours_post_deploy_2026-06-19.json) — `fly_mcp: pass`.
- **Дальше:** **стоп** — заказчик проверяет на Fly; «ок» закрывает пункт · иначе правки в backlog.
- **Агент:** ждать, код не менять.

### Сессия 2026-06-21 (demo: смены открыты + Сб–Вс A)

- **demo:seed:** `ensure_demo_shifts_open!` · A Пн–Пт 08–22, Сб–Вс 10–20.
- **Тест:** `environment_setup_test` — 3 runs, 49 assertions, 0 failures.
- **Fly:** после deploy — `bin/rails demo:seed`.

### Сессия 2026-06-21 (B1.11 Fly MCP — шапка витрины post-deploy)

- **Deploy:** владелец → `coffeeos.fly.dev`.
- **Fly MCP:** API A/B `schedule_display` match · browser header под CoffeeOS · A closed banner · B open.
- **Тест:** `operating_hours_schedule_text` + b111 — **10 runs, 34 assertions, 0 failures**.
- **Артефакт:** [`b111_header_schedule_post_deploy_2026-06-21.json`](milestones/veha_2/artifacts/demo-feedback/b111_header_schedule_post_deploy_2026-06-21.json).
- **Дальше:** апрув заказчика.

### Сессия 2026-06-21 (B1.11 — часы в шапке витрины + demo A/B)

- **Код:** `Shop::OperatingHoursScheduleText` · `schedule_display` в API · `Header.svelte`.
- **Demo seed:** A `08–20/09–17` · B `09–22/10–20` — разные строки на витринах.
- **Тест:** 13 runs, 81 assertions, 0 failures.
- **Дальше:** deploy (`fly deploy` + `demo:seed`) → заказчик A vs B → апрув.

### Сессия 2026-06-19 (B1.11 handoff — ждём заказчика)

- **Статус:** код + Fly MCP + тесты — **done с нашей стороны**.
- **Блокер:** апрув заказчика (`customer_approval: pending` в артефакте).
- **Действие агента:** **стоп** до «ок» или списка правок.

### Сессия 2026-06-19 (B1.11 этап 7 — integration + manager UI + артефакт)

- **Manager:** alert «Требуется закрытие смены» на `/manager/shifts`.
- **Тест:** 28/28 PASS (b111 + manager + block_g fix).
- **Артефакт:** [`b111_operating_hours_post_deploy_2026-06-19.json`](milestones/veha_2/artifacts/demo-feedback/b111_operating_hours_post_deploy_2026-06-19.json).
- **Дальше:** deploy → Fly MCP → апрув заказчика.

### Сессия 2026-06-19 (B1.11 этап 5–6 — табло + POS + logout)

- **Табло:** `BoardOrdersQuery` → пусто без смены; красный баннер + звук при конфликте.
- **POS:** заказ в зале вне расписания — без блока (shift open).
- **Logout:** `ShiftScheduleLogoutHook` → note на смене для менеджера.
- **Тест:** 16/16 PASS.
- **Дальше:** Fly MCP + артефакт.

### Сессия 2026-06-19 (B1.11 этап 4–5 — shop API + checkout)

- **API:** `Shop::OperatingHours`, config/categories meta, guard orders create.
- **UI:** `ShopClosedBanner`, Checkout disabled pay + баннер.
- **Тест:** b111 integration 7/7; shop regression (vite/pwa — pre-existing skip).
- **Дальше:** табло (п.5).

### Сессия 2026-06-19 (B1.11 этап 3c — open_now? / next_open_at)

- **Сервис:** `TenantOperatingHours` — timezone точки, `open_now?`, `next_open_at`.
- **Тест:** 6/6 PASS.
- **Дальше:** shop API `is_open` / guard оплаты (п.4).

### Сессия 2026-06-19 (B1.11 этап 3b — форма УК)

- **Было:** форма точки без блока расписания.
- **Стало:** «Режим работы» пн–вс (sales_point) — чекбоксы + open/close; sync create/update; ≥1 день.
- **Тест:** sync + tenants_controller — **7/7 PASS**.
- **Артефакт:** скрин до — [`b111_uk_tenant_form_before_2026-06-19.png`](milestones/veha_2/artifacts/demo-feedback/screenshots/b111_uk_tenant_form_before_2026-06-19.png).
- **Дальше:** сервис `open_now?` / `next_open_at` (чеклист п.3).

### Сессия 2026-06-19 (B1.11 этап 3a — миграция + модель)

- **БД:** `tenant_weekday_schedules` (weekday 0–6, enabled, opens_at/closes_at) + RLS.
- **Модель:** `TenantWeekdaySchedule`, `Tenant#weekday_schedules`.
- **Тест:** `tenant_weekday_schedule_test.rb` — **6/6 PASS**.
- **Дальше:** форма УК (чеклист п.2).

### Сессия 2026-06-19 (B1.11 — ответы раунд 2, готовность полная)

- **Уточнения:** корзина ok / оплата off · баннер «след. утро раб. дня» · чекбоксы пн–вс · табло красный баннер+звук · POS в зале → табло.
- **Артефакт:** [`b111_customer_answers_round2_2026-06-19.json`](milestones/veha_2/artifacts/demo-feedback/b111_customer_answers_round2_2026-06-19.json).
- **Дальше:** **`go`** на код B1.11.

### Сессия 2026-06-19 (B1.11 — ответы Q1–Q10, готовность к коду)

- **Ответы владельца:** Q5–Q10 дословно + дефолты Q1–Q3 → `B1_11_tenant_operating_hours.md`.
- **Артефакт:** [`b111_customer_answers_confirmed_2026-06-19.json`](milestones/veha_2/artifacts/demo-feedback/b111_customer_answers_confirmed_2026-06-19.json).
- **Статус:** **READY_FOR_APPROVAL** — код **не начинать** без **`go`**.



### Сессия 2026-06-19 (Веха 1 — формальное закрытие)

- **Апрув владельца:** закрыть В1 заочно (H.3 §1 + A–G достаточно).
- **Ops:** `veha_1/checklists/CHECKLIST.md` § I + H.3 `[x]`; `PRACTICES.md`, `README.md`; `HANDOFF`, `CHANGELOG` v1.210.
- **Хвосты → В2:** QA 5.1; `demo:seed` в release; полный LIVE_DEMO MCP §2–10.


- **Дальше:** шаг 2 — polling `finalize` на `#/payment`.


- **Tenant заказчика:** `2fdee1ac-4674-41ee-b89e-87b45643f789` (не MCP-tenant).
- **ISSUES:** 🔴 open — нужен payment_id/trace для repro.


- **Deploy:** владелец (до MCP).


- **Lib:** `shopOneClickPay.js`, `CheckoutPayButton.svelte`.
- **Backend:** идемпотентность recurrent по `client_order_uuid`.
- **Не сделано:** `fly deploy`, Fly MCP R3 post-deploy, апрув заказчика.


- **Стенд:** `https://coffeeos.fly.dev` · tenant `655aaccb-004a-4bb9-a50a-ce618854dda3` · Neon DB.

### Сессия 2026-06-19 (Neon Launch + deploy OK + ops)

- **Neon:** Launch plan; compute Active; deploy `release_command` **OK** (image `01KVFG8VW9Y`).
- **Fly MPG:** `coffeeos-db` **destroyed** (~$38/мес снято).
- **CI:** `deploy.yml` — только `workflow_dispatch`; агент — `fly deploy` только по апруву.
- **Billing:** Neon spending limit **$15** — включён владельцем в Console.

### Сессия 2026-06-19 (инфра: убран внешний DATABASE_URL → Fly MPG)

- **БД:** создан `coffeeos-db` (Fly Managed Postgres, ams), attach к `coffeeos`; старый `DATABASE_URL` (внешний хост) снят.
- **Код:** `schema.rb` — без `pg_stat_statements` в schema:load (Fly MPG без superuser).
- **Docs:** `INFRA_STACK.md` — канон стека; запрет Supabase/Neon/Render без апрува; Supabase вычищен из ops.
- **Deploy:** `fly deploy -a coffeeos` после фикса schema.


- **Deploy:** `ded6371` — `docker-entrypoint` fix; временно `--skip-release-command`.
- **Причина:** случайный внешний `DATABASE_URL` (не Fly) — quota exceeded.
- **Решение:** миграция на Fly MPG (см. сессию выше).




- **Следующий:** R2 web-фрейм + 3DS → ждём **`go`**


- **Тесты:** 8 R1 + 30 regression §2.3 — 0 failures.

- **Scope:** Т-Банк · 1 user = 1 card · только веб-витрина.
- **Ответы Q1–Q7:** закрыты 2026-06-18 (все карты храним, главная = последняя оплата; card only; идемпотентность при retry).
- **Код:** не трогаем до апрува и **`go`**.

### Сессия 2026-06-18 (B1.11 — режим работы точки, этап 0 ТЗ)

- **Источник:** заказчик — поле «Режим работы» в УК → витрина + табло.
- **ТЗ:** [`B1_11_tenant_operating_hours.md`](milestones/veha_2/requirements/customer_tasks/B1_11_tenant_operating_hours.md) — текст дословно, Q1–Q10.
- **Артефакт:** [`b111_stage0_scope_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b111_stage0_scope_2026-06-18.json).
- **Код:** не трогаем до апрува и **`go`**.

### Сессия 2026-06-18 (B1.10 — апрув заказчика, ЗАКРЫТА)

- **Источник:** убрать «Блог» из навигации → **принято**.
- **Артефакт:** [`b110_customer_approval_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b110_customer_approval_2026-06-18.json).
- **ТЗ:** [`B1_10_remove_blog_nav.md`](milestones/veha_2/requirements/customer_tasks/B1_10_remove_blog_nav.md).

### Сессия 2026-06-18 (B1.9 — апрув заказчика, ЗАКРЫТА)

- **Источник:** toggle-модификаторы на карточке → **принято**.
- **Артефакт:** [`b19_customer_approval_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b19_customer_approval_2026-06-18.json).
- **Backlog:** CC-2 (восстановление выбора после возврата из корзины) → CBR B1.9-CC2.

### Сессия 2026-06-18 (B1.7 BR-6 — апрув заказчика)

- **Источник:** баг-репорт №6 — отмена на `#/payment` → **принят**.
- **Артефакт:** [`b17_br6_customer_approval_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b17_br6_customer_approval_2026-06-18.json).
- **ТЗ:** [`B1_7_checkout_order_screen.md`](milestones/veha_2/requirements/customer_tasks/B1_7_checkout_order_screen.md) § BR-6.

### Сессия 2026-06-18 (B1.7 BR-5 — апрув заказчика)

- **Источник:** баг-репорт №5 — второй товар в корзину → **принят**.
- **Артефакт:** [`b17_br5_customer_approval_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b17_br5_customer_approval_2026-06-18.json).
- **ТЗ:** [`B1_7_checkout_order_screen.md`](milestones/veha_2/requirements/customer_tasks/B1_7_checkout_order_screen.md) § BR-5.
- **Backlog:** нет — scope закрыт.

### Сессия 2026-06-18 (B2.1 — апрув заказчика, ЗАКРЫТА)

- **Источник:** док заказчика — интерактивное табло баристы → **done** (MVP + ревизия).
- **Артефакт:** [`b21_customer_approval_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b21_customer_approval_2026-06-18.json).
- **ТЗ:** [`B2_1_barista_order_board.md`](milestones/veha_2/requirements/customer_tasks/B2_1_barista_order_board.md) — приёмка заказчика `[x]`.
- **Backlog (вне апрува):** брак/переделка/возврат, `defect_reasons`, звук отмены, списание при отмене, `prep_kitchen`, эскалация 5 мин → CBR «Блок 2 — backlog».

### Сессия 2026-06-04 (B1.7 — апрув заказчика, ЗАКРЫТА)

- **Источник:** док заказчика — «Доработка экрана оформления заказа» → **done**.
- **Артефакт:** [`b17_customer_approval_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/b17_customer_approval_2026-06-04.json).
- **ТЗ:** [`B1_7_checkout_order_screen.md`](milestones/veha_2/requirements/customer_tasks/B1_7_checkout_order_screen.md) — BR-1…BR-7, колонка «Заказчик» `[x]`.

### Сессия 2026-06-17 (B1.7 BR-7 — checkout «Оплатить» при пустом «Имя», CLOSED OPS)

- **Фикс:** `Checkout.svelte` — `canPay` без `name.trim()`; email/OTP без изменений.
- **Deploy:** `coffeeos.fly.dev` 2026-06-17.
- **MCP:** `bin/b17_br7_checkout_name_pay_prep_fly.rb` + `bin/b17_br7_checkout_name_pay_mcp.mjs` — **7/7 PASS**.
- **Артефакт:** [`b17_br7_checkout_name_pay_post_deploy_2026-06-17.json`](milestones/veha_2/artifacts/demo-feedback/b17_br7_checkout_name_pay_post_deploy_2026-06-17.json).
- **Скрин после:** [`screenshots/b17_br7_checkout_name_pay_after_2026-06-17/`](milestones/veha_2/artifacts/demo-feedback/screenshots/b17_br7_checkout_name_pay_after_2026-06-17/).
- **Дальше:** включено в апрув B1.7 `[x]` 2026-06-04.

- **Реализация:** `OrderBoardSound` + Stimulus `barista-board-sound`; WAV `public/audio/barista_new_order.wav` (2s); turbo-stream hook на `#barista-board-slots`; баннер NotAllowed.
- **Deploy:** `coffeeos.fly.dev` 2026-06-17.
- **MCP:** `bin/b21_s1_sound_prep_fly.rb` + `bin/b21_s1_sound_mcp.mjs` — **9/9 PASS** · latency **27 ms**.
- **Артефакт:** [`b21_s1_sound_post_deploy_2026-06-17.json`](milestones/veha_2/artifacts/demo-feedback/b21_s1_sound_post_deploy_2026-06-17.json).
- **Скрины:** [`screenshots/b21_s1_sound_2026-06-17/`](milestones/veha_2/artifacts/demo-feedback/screenshots/b21_s1_sound_2026-06-17/).
- **Дальше:** апрув заказчика `[ ]`.

### Сессия 2026-06-04 (B2.1 B2-S1 — регистрация звука табло, только доки)

- **Задача заказчика (неделя_2):** звуковое оповещение о новом заказе на `/barista` (PWA/браузер); unlock `AudioContext` по «Открыть смену»; баннер при `NotAllowedError`.
- **ТЗ / чеклист:** [`B2_1_barista_order_board.md`](milestones/veha_2/requirements/customer_tasks/B2_1_barista_order_board.md) § B2-S1.
- **Журнал:** [`DEMO_FEEDBACK.md`](milestones/veha_2/requirements/DEMO_FEEDBACK.md) — строка **open**.
- **Артефакт:** [`b21_s1_sound_notification_registration_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/b21_s1_sound_notification_registration_2026-06-04.json) — `pending_customer_approval`.
- **Ссылки заказчика:** [Chrome Autoplay Policy](https://developer.chrome.com/blog/autoplay) · [MDN Web Audio API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Using_Web_Audio_API).
- **Код:** **не трогаем** до апрува на реализацию (gate в ТЗ).
- **Дальше (после апрува):** repro Fly → JS + аудио на табло → `bin/b21_s1_sound_mcp.mjs` (TBD) → deploy.

### Сессия 2026-06-16 (B1.7 BR-6 — fix cancel on #/payment, OPS CLOSED)

- **Симптом заказчика:** `#/payment` — «Отмена…» залипает, заказ `#3565088f-…` 64₽ не отменяется.
- **Фикс:** `Payment.svelte` — `destroyed` вместо `finished` в `onDestroy`; cancel + `reconnect_token`; err на intro; отмена в `loading`. `orders#abandon` — `try_reconnect_from_params!` с `params[:id]`.
- **MCP:** `b17_br6_payment_cancel_prep_fly.rb` + `b17_br6_payment_cancel_mcp.mjs` — **6/6 PASS** на Fly tenant заказчика.
- **Артефакт post-deploy:** [`b17_br6_payment_cancel_post_deploy_2026-06-17.json`](milestones/veha_2/artifacts/demo-feedback/b17_br6_payment_cancel_post_deploy_2026-06-17.json) — 6/6 PASS · апрув заказчика `[x]` 2026-06-18.
- **Дальше:** апрув заказчика `[ ]`.

### Сессия 2026-06-04 (B1.7 BR-6 — регистрация бага, только доки)

- **Репорт заказчика:** на `#/payment` кнопка «Отмена заказа» не отменяет заказ; заказ `#3565088f-5af1-48e0-95b6-c456f3bc26f8`, **64₽**.
- **ТЗ / чеклист:** [`B1_7_checkout_order_screen.md`](milestones/veha_2/requirements/customer_tasks/B1_7_checkout_order_screen.md) § BR-6.
- **Журнал:** [`DEMO_FEEDBACK.md`](milestones/veha_2/requirements/DEMO_FEEDBACK.md) — строка **open**.
- **Артефакт:** [`b17_br6_payment_cancel_repro_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/b17_br6_payment_cancel_repro_2026-06-04.json) — `pending_customer_approval`.
- **Скрин:** `screenshots/b17_br6_payment_cancel_customer_2026-06-04.png` — положить из чата заказчика в repo при наличии файла.
- **Код:** **не трогаем** до апрува на фикс (gate в ТЗ).
- **Контекст:** CBR §2.3 этап 4.4 abandon ранее PASS — трактуем как регрессию / новый repro.
- **Дальше (после апрува):** repro на Fly → `bin/b17_br6_payment_cancel_mcp.mjs` (TBD) → fix `Payment.svelte` / abandon.

### Сессия 2026-06-04 (B1.7 BR-5 — post-deploy PASS, OPS CLOSED)

- **Deploy Fly:** пользователь `fly deploy -a coffeeos` — OK (assets:precompile).
- **MCP post-deploy:** `b17_br5_cart_second_product_mcp.mjs` **7/7** · `b17_br5_catalog_card_flow_mcp.mjs` **5/5** · `b17_br5_quick_add_category_mcp.mjs` **PASS**.
- **Артефакт:** [`b17_br5_regression_post_deploy_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/b17_br5_regression_post_deploy_2026-06-04.json) — `pass: true`.
- **Fly warning** «not listening on 0.0.0.0:3000»: **ложное срабатывание при старте** — `fly.toml` / Dockerfile уже `-b 0.0.0.0`, `PORT=3000`, health `/up` PASS; долгий boot (release_command + demo:seed). **Действий не требуется**, мониторить только если `/up` упадёт.
- **Статус:** OPS **CLOSED** · апрув заказчика `[ ]` · следующий — **второй баг** заказчика.

### Сессия 2026-06-04 (B1.7 BR-5 — fix cart UI on second product)

- **Repro Fly:** hash-switch p1→p2 — API 2 товара OK, баннер + DOM корзины FAIL ([`b17_br5_regression_repro_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/b17_br5_regression_repro_2026-06-04.json)).
- **Фикс:** `Product.svelte` (`params.id`), `Cart.svelte` (`hashchange` + `shop:cart-added`), `shopCartAdd.js`, `CategoryProducts.svelte`.
- **Скрины:** до `b17_br5_regression_before_p2_add_2026-06-04.png`, после `b17_br5_regression_after_2026-06-04.png`.
- **Дальше:** `fly deploy` → `node bin/b17_br5_cart_second_product_mcp.mjs`.

### Сессия 2026-06-04 (B1.7 BR-5 — регрессия, только доки)

- **Репорт заказчика:** второй товар в корзину — нет перехода на `#/cart` и нет индикации добавления (текст в ТЗ без правок).
- **ТЗ / чеклист:** [`B1_7_checkout_order_screen.md`](milestones/veha_2/requirements/customer_tasks/B1_7_checkout_order_screen.md) § BR-5 регрессия.
- **Журнал:** [`DEMO_FEEDBACK.md`](milestones/veha_2/requirements/DEMO_FEEDBACK.md) — строка **open**.
- **Код:** **не трогаем** до апрува на фикс.
- **Прогон (после апрува):** `node bin/b17_br5_cart_second_product_mcp.mjs`.
- **Гипотеза:** регрессия после B1.9 / route-switch в `Product.svelte` или quick-add в каталоге.

### Сессия 2026-06-15 (B1.10 — убрать «Блог», OPS PASS)

- **Запрос заказчика:** убрать вкладку «Блог» из навигации; LCP ≤ 1.5 с в WebView Telegram/Instagram.
- **ТЗ:** [`B1_10_remove_blog_nav.md`](milestones/veha_2/requirements/customer_tasks/B1_10_remove_blog_nav.md) — scope: `Header.svelte`, блог в БД не трогаем.
- **Код:** удалена ссылка `<a href="/blog">` в `Header.svelte`; скрин «до» `b110_blog_nav_before.png`.
- **Fly MCP:** Playwright — нет «Блог» в шапке **PASS** · апрув заказчика `[x]` 2026-06-18 ([`b110_customer_approval_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b110_customer_approval_2026-06-18.json)).
- **Статус:** OPS **CLOSED** · апрув заказчика `[ ]`.
- **Следующий шаг:** [B1.9](milestones/veha_2/requirements/customer_tasks/B1_9_product_modifier_toggle.md) toggle-модификаторы.

### Сессия 2026-06-16 (B1.9 — хвосты: route switch + dedup groups)

- **#2 route switch:** `Product.svelte` — сброс `selected` при смене `params.id`, poll только при совпадении `loadedProductId`.
- **#1 dedup groups:** `Shop::ModifierGroupsPresenter` в `products_controller` — merge групп с одинаковым `name`.
- **MCP:** `b19_route_switch_modifiers_mcp.mjs`, `b19_modifier_groups_dedup_mcp.mjs` — PASS на Fly.
- **Тест:** `products_controller_test` — dedup duplicate group names.

### Сессия 2026-06-16 (B1.9 — toggle модификаторы, OPS PASS)

- **Код:** `Product.svelte` + `modifiers.js` — toggle «+», без «обязательно», add без модификаторов.
- **Fly MCP:** 6/6 PASS — Бразилия 12₽ → +30₽ → 42₽ → 12₽, add в корзину без модификаторов.
- **Артефакты:** [`b19_modifier_toggle_post_deploy_2026-06-15.json`](milestones/veha_2/artifacts/demo-feedback/b19_modifier_toggle_post_deploy_2026-06-15.json), скрин [`b19_modifier_toggle_product_2026-06-16.png`](milestones/veha_2/artifacts/demo-feedback/screenshots/b19_modifier_toggle_product_2026-06-16.png).
- **Коммиты:** `ef90f16`, `2809d7a` · апрув заказчика `[ ]`.

### Сессия 2026-06-15 (B1.9 — toggle модификаторы, ТЗ до апрува)

- **Запрос заказчика:** убрать «обязательно» на карточке товара; toggle модификаторов; add в корзину без выбора опций.
- **ТЗ:** [`B1_9_product_modifier_toggle.md`](milestones/veha_2/requirements/customer_tasks/B1_9_product_modifier_toggle.md) — scope только `Product.svelte` + `modifiers.js`.
- **Код:** `[ ]` — **не начинаем** до апрува (gate в ТЗ).
- **Открыто:** CC-1 multi vs single внутри группы; скрин «до» — положить `b19_modifier_required_before.png` в artifacts/screenshots.
- **Следующий шаг:** апрув → реализация → Fly MCP.

### Сессия 2026-06-14 (B1.7 BR-5 — второй товар в корзину)

- **Симптом:** после Товара 1 в корзине — карточка Товара 2 «не добавляется»; на Fly при `#/product/p1` → `#/product/p2` header остаётся P1, в корзине qty=2 одного товара.
- **Причина:** `svelte-spa-router` не remount `/product/:id` — `Product.svelte` не перечитывал `params.id`.
- **Фикс:** `$effect` reload по `params.id`; баннер «добавлен в корзину» на `Cart.svelte`; `CategoryProducts` quick-add не блокирует другой товар.
- **API Fly:** два разных `product_id` → 200, 2 lines — PASS ([`b17_cart_second_product_api_2026-06-14.json`](milestones/veha_2/artifacts/demo-feedback/b17_cart_second_product_api_2026-06-14.json)).
- **MCP:** Playwright 7/7 + Chrome DevTools — **PASS** 2026-06-15 ([`b17_cart_second_product_post_deploy_2026-06-15.json`](milestones/veha_2/artifacts/demo-feedback/b17_cart_second_product_post_deploy_2026-06-15.json)).
- **Статус:** BR-5 **CLOSED** (код + Fly) · апрув заказчика `[x]` 2026-06-18.
- **Очередь:** B1.9 (toggle модификаторы).

### Сессия 2026-06-12 (B2.1 ревизия — 6 карточек + live)

- **Макет:** `b21_customer_mockup_6_cards.png`, анализ `b21_revision_mockup_analysis_2026-06-12.json`.
- **Код:** сетка 6 слотов, тап белый→жёлтый→ready off board; `OrderBoardBroadcaster` → `#barista-board-slots`.
- **Доки:** R0–R2 `[x]` в B2_1; **R2 Fly MCP PASS** 2026-06-13 (`b21_revision_r2_mcp_fly_2026-06-13.json`).

### Сессия 2026-06-13 (B2.1 R2 — Fly MCP live)

- **Скрипт:** `bin/b21_revision_r2_live_fly.rb` — разметка 6 слотов + turbo-cable + turbo-stream 200 на Fly.
- **Артефакты:** `b21_revision_r2_mcp_fly_2026-06-13.json`, `b21_mcp_fly_2026-06-13.json`.
- **Дальше:** R4 Fly скрины + приёмка заказчика.

### Сессия 2026-06-13 (B2.1 — приёмка заказчика MCP path)

- **Скрипты:** `bin/b21_revision_customer_mcp.rb`, `bin/b21_revision_customer_mcp.mjs`, `bin/b21_revision_fly_screenshots.*`, `bin/b21_revision_acceptance_fly.rb`.
- **Скрины:** `screenshots/b21_revision_customer_mcp_2026-06-13/` (01–07, имена как в ТЗ заказчика 1.1–1.4).
- **Артефакты:** `b21_revision_acceptance_2026-06-12.json` — PASS, `internal_signoff: true`, `customer_signoff: false`.
- **Chrome DevTools MCP:** login на Fly через браузер → HTTP 500; прогон через Playwright (curl/Ruby login OK).
- **Дальше:** формальная подпись заказчика.

### Сессия 2026-06-13 (B2.1 — сверка скринов и JSON)

- **Скрипт:** `bin/b21_revision_verify_screenshots_json.rb`
- **Результат:** PASS — 7 PNG `b21_revision_fly_2026-06-13/`, acceptance JSON verdict/status/ui_checks совпадают
- **Артефакт:** `b21_revision_screenshots_json_verify_2026-06-13.json`

### Сессия 2026-06-13 (B2.1 — закрытие ops, handoff)

- **OPS CLOSED:** R0–R4 + MCP + сверка JSON — PASS; `customer_signoff` ждёт заказчика
- **Handoff:** `b21_customer_handoff_2026-06-13.md` + скрины `b21_revision_customer_mcp_2026-06-13/`
- **Хвосты:** smoke PARTIAL → не блокер (R4); DevTools login 500 → tech-debt
- **Дальше:** B2.2 этап 1 (единый layout menu+cart)

### Сессия 2026-06-14 (B1.7 — localStorage TTL 24ч)

- **Задача:** не держать вечно имя/email/корзину/каталог в localStorage на телефоне
- **Фикс:** `shopLocalStorage.js` — обёртка `{ savedAt, ttlMs, payload }`, TTL **24ч** (как OTP verify на бэке); legacy ключи сбрасываются при чтении
- **Файлы:** `shopGuestProfile.js`, `shopCartCache.js`, `catalog.js`, `Cart.svelte`
- **Артефакт:** [`b17_localstorage_ttl_2026-06-14.json`](milestones/veha_2/artifacts/demo-feedback/b17_localstorage_ttl_2026-06-14.json)

### Сессия 2026-06-14 (B1.7 — cart/add 500, cookie overflow)

- **Баг:** «В корзину» → `POST /shop/api/cart/add` 500, переход на `/cart` не происходит (tenant `655aaccb…`)
- **Корень:** `removed_modifiers` писались в Rails session cookie → `ActionDispatch::CookieOverflow` (~4KB)
- **Фикс:** `CartService` — removed только при `json_lines`; compact legacy session; ошибка в `Product.svelte`
- **Не баги:** PWA `beforeinstallprompt` info; 404 картинок `/uploads/products/*` на Fly
- **Артефакт:** [`b17_cart_cookie_overflow_2026-06-14.json`](milestones/veha_2/artifacts/demo-feedback/b17_cart_cookie_overflow_2026-06-14.json)

### Сессия 2026-06-14 (B1.7 — checkout orders 500 после OTP)

- **Баг:** checkout «Оплатить» → `/shop/api/orders` 500 после подтверждения email
- **Фикс:** T-Bank transport → `OrderCreator::Error` (422); `mark_verified` rescue; api.js 500 message
- **Коммит:** `e0e0f56`

### Сессия 2026-06-14 (B1.7 — баг-3 checkout «сессия истекла», permanent fix)

- **Баг:** повторный checkout / PWA — «сессия истекла» после реального OTP (заказчик `razmikg1988@gmail.com`)
- **Корень:** верификация была привязана к `session_id`; при смене cookie/PWA терялась
- **Фикс:** `shop_email_verifications` unique `(tenant_id, email)` — источник истины по email; `Checkout.svelte` без «сессия истекла», optimistic verify + `profileSyncing`
- **Миграция:** `20260613120000_email_primary_shop_email_verifications`
- **Fly:** `bin/b17_checkout_session_fly.rb` + MCP после деплоя
- **Артефакт:** [`b17_checkout_session_2026-06-14.json`](milestones/veha_2/artifacts/demo-feedback/b17_checkout_session_2026-06-14.json)

### Сессия 2026-06-13 (B1.7 — баг-3 checkout «сессия истекла», partial)

- **Баг:** повторный checkout — OTP «сессия истекла» при сохранённом email в localStorage
- **Фикс (partial):** `EmailVerification` fallback по tenant+email; `Checkout.svelte` status?email=; UX сообщения
- **Fly:** `bin/b17_checkout_session_fly.rb` + Playwright + **Chrome DevTools MCP PASS** (isolatedContext)
- **Артефакт:** [`b17_checkout_session_2026-06-13.json`](milestones/veha_2/artifacts/demo-feedback/b17_checkout_session_2026-06-13.json)

### Открытый баг заказчика (B1.1, не B2.1)

- **Баг-1 (2026-06-04):** экран статуса гостя — WS без F5 — **FIXED** 2026-06-13 · [`b11_bug1_guest_ws_2026-06-13.json`](milestones/veha_2/artifacts/demo-feedback/b11_bug1_guest_ws_2026-06-13.json)

### Tech-debt (B2.1)

- **Fly browser login HTTP 500** (Chrome DevTools MCP) — Playwright/curl OK; разбор отдельно, не блокирует приёмку

### Сессия 2026-06-13 (B2.1 R3 — тесты + smoke)

- **Тесты:** tap accepted→preparing→ready off board, limit 6, `OrderBoardBroadcasterTest`.
- **Smoke:** `bin/b21_revision_fly_smoke.rb` (REVISION=1).

### Сессия 2026-06-12 (B1.1 ревизия — UI экрана статуса)

- **ТЗ:** правки заказчика в `B1_1_order_status_progress.md` §Ревизия + макеты `b11_order_status_revision_2026-06-12/`.
- **Код:** `OrderStatus.svelte` — макет (зелёный самовывоз, qty `1x`, оплата, отмена); `orderStatusProgress.js` — ETA «8–12 мин», иконки; WS reconnect без лимита.
- **Не в прогоне:** доставка, табло/кухня, кнопка «Оплатить 3₽» — бэклог в B1_1.
- **R4 Fly:** MCP путь заказчика + 8 скринов, `b11_revision_acceptance_2026-06-12.json`, WS обновления без reload.
- **Скрипты:** `b11_revision_fly_prep.rb`, `b11_revision_fly_status.rb`.

### Сессия 2026-06-18 (B1.1 — апрув заказчика, CLOSED)

- **Источник:** док заказчика — B1.1 → **done**.
- **Артефакт:** [`b11_customer_approval_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b11_customer_approval_2026-06-18.json).

### Сессия 2026-06-12 (B1.4 — хвосты, деплой, промокод)

**Сделано в коде:**
- Офлайн add в корзину (`shopOfflineCart.js`, `shopCartAdd.js`)
- `client_order_uuid` → колонка БД + unique index (не Rails.cache)
- Скрипты приёмки: `b14_run_acceptance.sh`, `b14_pwa_browser_shots.mjs`; удалён flaky `acceptance_fly.mjs`
- Промокод убран из **корзины** (BR: нет на checkout — нет и в cart UI)

**Не сейчас (долги):** слияние 2 SW, Background Sync, A/B install, per-tenant icons, iOS скрин, перепрогон Playwright шаг 3, приёмки заказчика, домен `*.shop…` — см. [`B1_4_pwa_shop.md`](milestones/veha_2/requirements/customer_tasks/B1_4_pwa_shop.md) §Долги.

**Git:** push `develop` `9f64e2a` ✅  
**Деплой Fly:** ⏳ владелец — `flyctl auth login` → `fly deploy -a coffeeos` (release → `client_order_uuid` migrate).

### Сессия 2026-06-12 (B1.4 PWA — формальное закрытие OPS)

- **Fly smoke:** `b14_pwa_fly_smoke.rb` — PASS.
- **PWA audit:** programmatic 100% (LH 13+ без категории pwa).
- **LCP:** 183 ms repeat visit (4G throttle).
- **Скрины:** 5 в `b14_pwa_2026-06-11/`.
- **Артефакт:** `b14_pwa_acceptance_2026-06-12.json` — OPS_PASS.
- **Заказчик:** `[ ]` — после апрува.

**Ops на блок:** commit + SESSION_STATE всегда (без вопроса); `PRACTICES` (CR); `QA_ACCEPTANCE_RUN` + `artifacts/` (QA); `CHANGELOG` + `HANDOFF`; `CHECKLIST` `[x]` только по факту.

### Сессия 2026-06-11 (B2.1 — push pipeline simulation)

- **FCM_SIMULATE=1** — полный цикл без Google и без телефона: notifier → job → `sent`.
- **Скрипты:** `bin/b21_push_pipeline_fly.rb`, `shop:push:smoke ORDER_ID=…`.
- **Тесты:** `push_pipeline_simulation_test` + `fcm_client_test` simulate.
- **Fly:** `b21_push_pipeline_fly.rb` — **PASS** v211, body «начали готовить», `status=sent`.
- **Артефакт:** `b21_push_pipeline_sim_2026-06-11.json`.

### Сессия 2026-06-11 (B2.1 хвост — removed_modifiers с витрины)

- **Фича:** витрина пишет `removed_modifiers` (все опции − выбранные) → корзина → `OrderItem.modifier_options` → табло «БЕЗ …».
- **Код:** `Shop::ModifierSelection`, `Product.svelte`, тесты checkout.
- **Деплой:** ✅ Fly **v210** `632bccf`, `/up` 200.

### Сессия 2026-06-11 (витрина checkout — OTP desync fix)

- **Баг:** localStorage `emailVerified` без серверной session → блок «Контакты» + ошибка «Подтвердите email» (кейс Арам/aramfifa).
- **Фронт:** `Checkout.svelte` — `/email_otp/status` источник истины; не пишем verified в localStorage до успеха; preflight перед оплатой.
- **Бэк:** таблица `shop_email_verifications` (`tenant_id` + `session_id` + email, TTL 24ч) — общая между web-инстансами без Redis.
- **Сервис:** `Shop::EmailVerification` — session + Postgres; verify/status/order читают оба слоя.
- **Тесты:** `email_verification_test`, `email_verification_db_fallback_test` + регрессия OTP/checkout.
- **Деплой:** ✅ Fly **v209** `2026-06-11` — `develop` `77571f9`+`dd3d956`, `/up` 200, миграция `shop_email_verifications` через `fly:release`.
- **Гостю:** пусть Арам зайдёт и попробует checkout; смотрим результат.

### Сессия 2026-06-11 (B2.1 — formal acceptance OPS_PASS)

- **Прогон:** `bin/b21_acceptance_fly.rb` — критерии MVP **1–9 формально PASS** на Fly.
- **Скрипты:** `b21_acceptance_prep.rb`, `b21_acceptance_fly.mjs` — замер табло ~850ms, FIFO, модификаторы, FCM pipeline, stage2/4 Fly.
- **Артефакт:** `b21_acceptance_2026-06-11.json` — `status: OPS_PASS`, `internal_signoff_ready: true`.
- **Дальше:** внутренняя приёмка (ты) → подпись заказчика → B2.2.

### Сессия 2026-06-11 (B2.1 — браузерный e2e витрина→бариста→гость Fly)

- **Playwright:** `bin/b21_mcp_e2e_fly.mjs` — клики ГОТОВИТСЯ/ГОТОВ, гость WS ≤5с без reload — **PASS**.
- **Оркестратор:** `bin/b21_mcp_e2e_fly.rb` — prep + e2e + smoke + MCP + тесты — **PASS** (`b21_mcp_e2e_2026-06-11.json`).
- **Скрины:** `stage5_e2e_*`, пересняты `stage3_guest_preparing/ready`.
- **Smoke fix:** `ГОТОВИТСЯ` проверяется после заказа на табло, не на пустом board.
- **Acceptance:** критерии 7, 9 формально PASS.
- **Дальше:** подпись заказчика, FCM устройство (опц.).

### Сессия 2026-06-11 (B2.1 этап 3 — скрины гостя Fly)

- **Скрины:** `stage3_guest_preparing.png`, `stage3_guest_ready.png` — Fly demo A, подзаголовки B2.1.
- **Скрипты:** `b21_stage3_guest_screenshots_prep.rb`, `b21_stage3_guest_screenshots.mjs`, `b21_stage3_fly_status.rb`.

### Сессия 2026-06-11 (B2.1 этап 5 — Fly smoke e2e PASS)

- **Smoke:** `FLY_BIN=flyctl ruby bin/b21_barista_board_fly_smoke.rb` — **PASS** (`order_8e2bc72e`, vitrina→табло).
- **Артефакты:** `b21_fly_smoke_2026-06-11.json`, `b21_acceptance_2026-06-11.json` обновлены.
- **Этап 5 ops gate:** `[x]` код; приёмка заказчика — потом.
- **Дальше:** stage3 guest скрины, MCP e2e бариста→гость, FCM устройство.

### Сессия 2026-06-11 (B2.1 fix — новые заказы на табло при >50 accepted)

- **Баг:** `limit(50)` по всему тенанту — на Fly demo новые витринные заказы не попадали в HTML.
- **Fix:** `BoardOrdersQuery.board_scope` — текущая смена + витрина с `opened_at`; без лимита; counts/broadcast выровнены.
- **Тесты:** regression >50 + `order_<uuid>`; unit scope vitrina/FIFO — PASS.
- **Smoke:** `order_<uuid>` + retry в `b21_barista_board_fly_smoke.rb`.
- **Коммит:** `24266e0` · deploy пользователем — перепрогон smoke из WSL с `flyctl`.

### Сессия 2026-06-11 (B2.1 post-deploy Fly)

- **Deploy:** B2.1 на `coffeeos.fly.dev` — markup smoke **PASS** (ГОТОВИТСЯ, order-card, cancel overlay).
- **MCP verify:** `b21_mcp_fly_2026-06-11.json` — **PASS**.
- **Скрины Fly:** пересняты `barista_board_after.png`, `stage5_e2e_vitrina_to_board.png`.
- **Skip:** vitrina→board OTP — flyctl token не в shell агента.

### Сессия 2026-06-11 (B2.1 этап 5 — ops gate)

- **Тесты:** полный suite 702 runs (9 fail / 5 err вне B2.1); B2.1 FIFO/cancel/card PASS.
- **Скрипты:** `bin/b21_barista_board_fly_smoke.rb`, `bin/b21_mcp_fly_verify.rb`.
- **MCP:** cursor-ide-browser — скрины stage2/4 localhost + Fly vitrina/board.
- **Артефакты:** `b21_acceptance_2026-06-11.json`, `b21_mcp_fly_2026-06-11.json`, `b21_fly_smoke_2026-06-11.json`.
- **Fix:** overlay cancel `display:none` по умолчанию (не торчал без `is-visible`).
- **Блокер Fly:** deploy B2.1 + `flyctl auth login` для vitrina→board OTP.
- **Не закрыто:** подпись заказчика, stage3 guest скрины, FCM.

### Сессия 2026-06-11 (B2.1 этап 3–4 — гость + отмена)

- **Этап 3:** push тексты, guest subtitles, WS retry, `b21_stage3_guest_notify`.
- **Этап 4:** cancel overlay на карточке, resync колонки, `b21_stage4_cancel`.

### Сессия 2026-06-11 (B2.1 этап 2 — FIFO)

- **FIFO:** `BoardOrdersQuery`, resync колонок при смене статуса, без drag-hint.
- **Не в этапе:** этапы 3–5 (гость, отмена, fly).
- **Артефакт:** `b21_stage2_fifo_2026-06-11.json`.

### Сессия 2026-06-10 (B2.1 этап 1 — карточка табло)

- **Код:** `_order_card`, стили, helper, N+1 fix.
- **Не в этапе:** FIFO hint, отмена overlay, fly deploy, guest e2e — этапы 2–5.
- **Артефакт:** `b21_stage1_card_ui_2026-06-10.json` + stage1 скрины.

### Сессия 2026-06-10 (B2.2 — ТЗ меню + создать)

- **ТЗ:** `B2_2_barista_menu_create_merge.md` — единое «Меню», стоп-лист с карточки, POS Сбер, без наличных.
- **Этап 0:** baseline Fly (menu + create) + 2 макета заказчика; `b22_stage0_mapping_2026-06-10.json`.
- **Макет 2:** полный текст эквайринга — «запрос на эквайринг сбера на аппарат».
- **Порядок:** после B2.1 (табло).

### Сессия 2026-06-10 (B2.1 — ТЗ табло бариста)

- **ТЗ:** `B2_1_barista_order_board.md` — MVP: web `/barista`, карточка, FIFO, модификаторы, B1.1 WS/push.
- **Не MVP:** PWA, кухня, брак/переделка/возврат — фаза 2/3.
- **Артефакт:** `b21_stage0_mapping_2026-06-10.json` · скрин `barista_board_before.png`.

### Сессия 2026-06-10 (B1.7 BR-fixes)

- **BR-1/BR-2:** убраны промокод и наличные с checkout · Fly MCP PASS · коммит `ffd3cfc`.

### Сессия 2026-06-10 (B1.1 закрытие — Firebase на Fly)

- **Secrets:** все `FIREBASE_*` на `coffeeos` (`bin/fly_firebase_secrets.sh`).
- **Локально:** `config/secrets/firebase-service-account.json` + `bin/minify_firebase_env.rb`.
- **Smoke:** `b11_fly_smoke_2026-06-10.json` **PASS** — в т.ч. `push_register` HTTP 200.
- **MCP Fly:** `b11_mcp_fly_2026-06-10.json` **PASS** — catalog, firebase SW, OrderStatus bundle.
- **Тесты:** B1.1 suite 21 runs, 113 assertions PASS.
- **Доки:** CBR + customer_tasks README — B1.1 заказчик `[x]`.
- **Ручной хвост:** push в шторке на телефоне (1 прогон владельцем).

### Сессия 2026-06-10 (B1.1 push FCM v1 end-to-end)

- **API:** `POST /shop/api/push/register` — сохранение `push_token`.
- **FCM:** `FcmClient` HTTP v1 + `FirebaseConfig`; SW `/firebase-messaging-sw.js`.
- **UI:** «Разрешить уведомления» на `OrderStatus.svelte`.
- **Док:** `docs/operations/dev/FIREBASE_PUSH.md` — ENV для Fly.

### Сессия 2026-06-10 (B1.1 этап 5 — push + WS session)

- **Push:** `OrderStatusPushNotifier` + `PushNotification` + `SendPushNotificationJob` + `FcmClient`.
- **WS:** `GuestOrderChannel` — подписка по customer session без `reconnect_token`.
- **ТЗ:** убраны кухня, доставка, «оплачен после кухни»; цепочка витрина → бариста.
- **Тесты:** B1.1 suite 20 runs, 118 assertions PASS.
- **Fly:** develop pushed; `OrderStatus` в bundle на coffeeos.fly.dev; smoke PARTIAL (нет flyctl auth).
- **Приёмка заказчика:** `[x]` 2026-06-10.
- **Не сделано:** PNG макеты в репо (файлы не на диске).

### Сессия 2026-06-10 (B1.1 этап 4 — приёмка)

- **Тесты:** `order_status_acceptance_cbr_test` 7× PASS; B1.1 suite 18 runs.
- **Fly/MCP:** deploy develop → OrderStatus на Fly.
- **Артефакт:** `b11_acceptance_2026-06-10.json`.

### Сессия 2026-06-09 (B1.1 этап 3 — отмена)

- **API:** `POST /shop/api/orders/:id/cancel`; `guest_can_cancel?` (accepted / pending_payment).
- **UI:** кнопка отмены, тексты guest vs kitchen (WS + API).
- **Тесты:** service + integration (6 runs).
- **Следующее:** **go** на этап 4 (MCP Fly + приёмка).

### Сессия 2026-06-09 (B1.1 этап 2 — WebSocket)

- **Shop::GuestOrderChannel** + broadcaster на смену статуса (бариста, оплата, cash).
- **Frontend:** `@rails/actioncable`, баннер reconnect, live-патч статуса.
- **Следующее:** **go** на этап 3 (отмена гостем).

### Сессия 2026-06-09 (B1.1 этап 1 — статический UI)

- **Экран** `#/order/:id`: прогресс-бар 4 шага, состав, самовывоз, итого.
- **API:** `order_json` + tenant pickup; редиректы checkout/payment-result.
- **Тесты:** `orders_controller_test` — новые поля JSON.
- **Следующее:** **go** на этап 2 (WebSocket).

### Сессия 2026-06-09 (B1.1 этап 0 — согласование)

- **B1.1 этап 0 `[x]`:** маппинг 4 шага ↔ `Order.status`; расхождение ТЗ (оплата до кухни); UI из макетов; план этапов 1–4.
- **Артефакт:** `artifacts/demo-feedback/b11_stage0_mapping_2026-06-09.json`; папка скринов `screenshots/b11_order_status_2026-06-09/` (PNG — положить при наличии).
- **Следующее:** **go** на этап 1 (статический `/order/:id`).

### Сессия 2026-06-09 (customer_tasks: вынос ТЗ из CBR)

- **Новое:** `requirements/customer_tasks/` — B1_7 checkout (текст заказчика + наша приёмка), B1_1 прогресс-бар (текст заказчика).
- **CBR:** индекс задач + ссылки; полные тексты убраны из CBR.

### Сессия 2026-06-09 (commit-ops: отчёт Сделано / Не сделано)

- **Усилено:** `coffeeos-commit-ops.mdc` — запрет любых вопросов про коммит; commit до отчёта.
- **Отчёт:** `coffeeos-task-workflow.mdc` — таблица **Сделано | Не сделано** + хеш.
- **Синхрон:** `.cursorrules`, `AGENTS.md`, `RULES_INDEX`, `HANDOFF`, `demo-feedback/README`, `AGENTS/git.md`, `veha_1/CODE_REVIEW`.
- **Push:** только по явной просьбе (не путать с commit).

### Сессия 2026-06-08 (гармонизация правил)

- **RULES_INDEX.md** + `coffeeos-index.mdc`; AGENTS.md + `.cursorrules` = workflow.
- **Symlinks** `.cursor/rules/coffeeos-*.mdc` → `project/`.
- **Доки:** пути `project/coffeeos-*` в PRACTICES, HANDOFF, CODE_REVIEW, db/README.
- **Push:** по **`go`**.

### Сессия 2026-06-08 (корень репо — scratch)

- **Перенос:** 19× `tmp_*` из корня → `scripts/scratch/` (gitignore).
- **Обновлено:** `.cursorrules` (индекс на `.cursor/rules/workflow/`), `coffeeos-repo-layout.mdc`.
- **Push:** по **`go`**.

### Сессия 2026-06-08 (task-workflow — задачи и отчёт)

- **Новое:** `coffeeos-task-workflow.mdc` — старт сессии (таблица), go, тесты, честный отчёт, backlog → CBR/DEMO_FEEDBACK.
- **Обновлено:** `coffeeos-agent-workflow.mdc` — краткий индекс, ссылка на task-workflow.
- **Коммит:** всегда; push по явной просьбе.

### Сессия 2026-06-08 (repo-layout — структура репозитория)

- **Новое:** `coffeeos-repo-layout.mdc` — Rails-пути, docs/operations, тесты, переносы с go, README sync.
- **Коммит:** всегда; push по явной просьбе.

### Сессия 2026-06-08 (dev-gates — DoD и регрессия)

- **Новое:** `coffeeos-dev-gates.mdc` — приоритет правил, DoD, зоны `bin/rails test`, hot-path, migration/API gate.
- **Обновлено:** `coffeeos-agent-workflow.mdc` — ссылка на dev-gates.
- **Коммит:** всегда; push по явной просьбе.

### Сессия 2026-06-08 (commit-ops — всегда коммит + ops)

- **Новое:** `coffeeos-commit-ops.mdc` — канон коммита (перебивает user rules «коммит по просьбе»).
- **Обновлено:** `coffeeos-agent-workflow.mdc` — ссылка только на commit-ops.
- **Push:** только по явному апруву.
- **Дальше:** следующие правила — ждать **`go`**.

### Сессия 2026-06-08 (правила агента — workflow + project)

- **Структура:** `.cursor/rules/workflow/` + `project/`; `coffeeos-file-size-split.mdc`.
- **Коммит:** `b0f58c2` (локально, не push).

### Сессия 2026-06-06 (W1.4 — сверка категорий: **PASS**, апрув заказчика)

- **Апрув:** заказчик 2026-06-06.
- **Код:** `Shop::Catalog.tenant_menu`; barista = vitrina scope.
- **Fly FULL A+B:** 5 cat / 18 prod, diffs=[].
- **Тест:** `uk_menu_w14_category_sync_test.rb`; PTS disable/sold_out — integration test.
- **Артефакт:** [`mcp_w14_category_sync_fly_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_w14_category_sync_fly_2026-06-06.json).
- **Backlog:** barista UI стоп-листа; kiosk sync.
- **Дальше:** **блок 2** табло.

### Сессия 2026-06-06 (W1.3 — обязательные модификаторы: **PASS** post-deploy)

- **Fly post-deploy:** UK curl → Hot/Iced в группы `W13-REQ-SIZE`; vitrina блок без выбора ✅; **happy path** Hot → корзина ✅ (`W12-PHOTO-001` 299₽).
- **Polling:** `W12-PLAIN-001` **179₽** на vitrina A без F5 (cache bust `update_product` работает).
- **Хвосты W1.2:** optional `W12-Size`, `W12-FILE-001`, vitrina B DOM — закрыты ранее.
- **Тест:** `test/integration/platform/uk_menu_w13_required_modifiers_test.rb`.
- **Скрины:** `w13_cart_hot_happy_fly_2026-06-06.png`, `w12_polling_price_179_fly_2026-06-06.png`.
- **Артефакт:** [`mcp_w13_required_modifiers_fly_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_w13_required_modifiers_fly_2026-06-06.json).

### Сессия 2026-06-06 (W1.2 — УК меню → витрина: **PASS**)

- **Fly MCP:** категория `W12-FLY-0606`, товары `W12-PHOTO-001` (299₽, picsum URL), `W12-PLAIN-001` (149₽); API A/B ✅; DOM витрина A ✅.
- **Тест:** `test/integration/platform/uk_menu_w12_vitrina_test.rb` — 33 assertions, модификаторы optional + PNG upload.
- **Артефакт:** [`mcp_w12_uk_menu_vitrina_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_w12_uk_menu_vitrina_2026-06-06.json).
- **Хвосты закрыты в follow-up:** см. W1.3 сессию и `mcp_w13_…json`.

**Артефакты (для агента в другом редакторе):** точка входа — [`milestones/veha_2/artifacts/README.md`](milestones/veha_2/artifacts/README.md). Прогон 10: `artifacts/prog10/{_index,smoke,kiosk,shop,staff-rbac,connectivity,platform-ent,warehouse}/`. Сводный индекс: `prog10/_index/prog10_final_index.json`. Скрипты `bin/prog10_*` пишут в эти подпапки (OUT обновлён). Старый плоский путь `artifacts/prog10_*.json` **удалён** — везде относительные ссылки `artifacts/prog10/...`.

### Сессия 2026-06-06 (§2A.3 — сессии точки: **PASS**)

- **Апрув заказчика:** 2A.3 закрыт `[x]`.
- **Код:** `Auth::SessionTracker`; `/admin/monitoring/:id/sessions`.
- **Commit:** `824204d`, `1e4b813`. MCP: `mcp_section_2a_3_sessions_2026-06-06.json`.

### Сессия 2026-06-06 (§2A.4 — транзакции точки: **PASS**, блок 2A закрыт)

- **Апрув заказчика:** 2A.4 закрыт `[x]`. **Блок 2A полностью закрыт.**
- **Commit:** `b63242c`, `45a22ce`. MCP: `mcp_section_2a_4_2026-06-06.json`.
- **Дальше:** **Блок 2** — табло баристы.

### Сессия 2026-06-06 (§2A.4 — транзакции точки, на апрув)

- **Код:** `Platform::TenantTransactionsOverview`; `/admin/monitoring/:id/transactions` (HTML + JSON); `/health/tenants/:id/transactions`.
- **UI:** сводка статусов, фильтры, список платежей с PaymentId, отказы, ▸ JSON.
- **Commit:** `b63242c`. MCP: [`mcp_section_2a_4_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2a_4_2026-06-06.json).
- **Скрин:** `tenant_transactions_point_a_2026-06-06.png` (Fly: 13 платежей, 716 RUB succeeded).
- **Дальше:** апрув 2A.4 → **Блок 2** табло баристы.

### Сессия 2026-06-06 (§2A.3 — сессии точки: онлайн + все пользователи, на апрув)

- **Код:** `Auth::SessionTracker` → таблица `sessions`; `Platform::TenantSessionsOverview`; `/admin/monitoring/:id/sessions` (HTML + JSON).
- **UI:** сводка ролей; блок «Сейчас онлайн»; все пользователи + последний вход/выход; журнал входов 24ч; ▸ JSON на каждой строке (в т.ч. чужие сессии).
- **LoginJournal:** audit с `context_tenant_id` (точка franchise/manager).
- **Commit:** `824204d`. MCP: [`mcp_section_2a_3_sessions_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2a_3_sessions_2026-06-06.json).
- **Скрин:** `tenant_sessions_point_a_2026-06-06.png` (Fly: 8 users, 1 online, role summary).
- **Дальше:** апрув 2A.3 → 2A.4 транзакции.

### Сессия 2026-06-06 (§2A.3 UX — человеческая лента + JSON, на апрув)

- **UI:** лента событий понятным текстом; **▸ JSON** у каждой строки; `/admin/session` — HTML-карточка + JSON.
- **Commit:** `bd130e2`. Скрины: `monitoring_human_feed_2026-06-06.png`, `session_human_page_2026-06-06.png`.

### Сессия 2026-06-06 (§2A.3 — логин / user ID, на апрув)

- **2A.2:** `[x]` PASS (апрув заказчика).
- **Код:** `Auth::LoginJournal` — audit `user_login`/`user_logout`; nav показывает email + user id; `/admin/session` JSON.
- **Commit:** `123c059`. MCP: [`mcp_section_2a_3_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2a_3_2026-06-06.json).
- **Скрины:** `session_user_id_nav_2026-06-06.png`, `session_json_2026-06-06.png`.
- **Дальше:** апрув 2A.3 → 2A.4 транзакции.

### Сессия 2026-06-06 (§2A.2 — журнал событий, на апрув)

- **2A.1:** `[x]` PASS (апрув заказчика).
- **Код:** `Health::TenantEventFeed` — детали под каждой проверкой + `unified_feed` 24ч.
- **UI:** drill-down — таблица строк под каждым check + единая лента.
- **JSON:** `/health/tenants/:id/events`, `/admin/monitoring/:id/events`; show включает `check_details`.
- **Commit:** `d46e3ed`. MCP: [`mcp_section_2a_2_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2a_2_2026-06-06.json).
- **Дальше:** апрув 2A.2 → 2A.3.

### Сессия 2026-06-06 (§2A.1 — мониторинг точек УК, на апрув)

- **UI:** `/admin/monitoring` — сводка всех точек; `/admin/monitoring/:id` — проверки + журнал 24ч.
- **JSON:** `/health/tenants` (+ `recent_events` на show).
- **TenantChecker:** + `pending_payment`, `shop_vitrina`, `app`; audit events на drill-down.
- **Smoke:** `fly:health_smoke`; MCP: [`mcp_section_2a_1_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2a_1_2026-06-06.json).
- **Скрины:** `artifacts/demo-feedback/screenshots/monitoring_summary_2026-06-06.png`, `monitoring_drilldown_point_a_2026-06-06.png`.
- **Commit:** `72afacc`. **Дальше:** апрув → 2A.2 журнал событий.

### Сессия 2026-06-06 (§2.3 **закрыт** — апрув + 5.3)

- **Апрув заказчика:** §2.3 ок («если что позже вернётся»).
- **5.3 PASS:** MCP inventory + retest Fly smoke (`b697b433-…`, `38eed006-…`).
- **Тест:** fix `TbankControllerTest` REJECTED → `cancelled` (4.5 journal); commit `38f4c5e`.
- **MCP:** [`mcp_section_2_3_stage5_3_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage5_3_2026-06-06.json).
- **Дальше:** блок 2 — табло баристы.

### Сессия 2026-06-06 (§2.3 этап 5.2 — «Заказы за сегодня»)

- **Fly:** `fly:stage5_2_smoke` — order `72801b25-8fbe-4b8f-9a7f-a26d22868444` → `history_found: true`, `accepted`, 179₽.
- **Тест:** `qa_section_2_3_stage5_e2e_test.rb` — history after finalize (17 assertions).
- **Deploy:** `deployment-01KTE2SYJK31BGHHRVWQ9AH9Z2`, commits `22908cb`…`9ad1da9`.
- **MCP:** [`mcp_section_2_3_stage5_2_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage5_2_2026-06-06.json).
- **Дальше:** этап 5.3 — финальный MCP + DEMO_FEEDBACK.

### Сессия 2026-06-06 (§2.3 этап 5.1 — оплата → webhook → accepted)

- **Fly:** `fly:callback_smoke` — order `05c99c7e-9215-45ff-a54d-627b23bc11f0` → `accepted`, payment `succeeded`, callback HTTP 200.
- **Тест:** `test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb` — cart → card → CONFIRMED → finalize (13 assertions).
- **MCP:** [`mcp_section_2_3_stage5_1_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage5_1_2026-06-06.json).
- **Дальше:** этап 5.2 — заказ в «Заказы за сегодня».

### Сессия 2026-06-06 (§2.3 этап 4.5 — журнал отказов оплаты)

- **Код:** `Shop::PaymentFailureJournal` — abandon, FailURL, webhook `REJECTED` → `OrderStatusLog` + `AdminAuditLog` (`shop_payment_failed`).
- **Менеджер:** `/manager/incidents` — блок «Отказы оплаты (витрина)»; история статусов на заказе.
- **УК:** `/health/tenants` → `checks.failed_payments.recent_events` (namespace может переименоваться).
- **Deploy (апрув):** `deployment-01KTE1S9XJ4ASQND4RY885J84R`, commits `1c7809e`…`cae4e8e` на Fly.
- **Дальше:** этап 5 — полная оплата до webhook.

### Сессия 2026-06-06 (§2.3 — оболочка CoffeeOS на оплате)

- **UI:** intro-экран (сумма, способ, оранжевая кнопка) → iframe; маска T-Pay/SberPay; `setTheme(dark)`.
- **Deploy:** `deployment-01KTE0P9PZSVF3YNJYEMC1DVXX`, commit `7a0533c`.
- **Скрины:** [`stage4_payment_shell_paying_2026-06-06.png`](milestones/veha_2/artifacts/demo-feedback/screenshots/stage4_payment_shell_paying_2026-06-06.png).
- **Ограничение:** логотип/поля карты внутри iframe — зона банка (PCI); 100% свой UI только без iframe.

### Сессия 2026-06-06 (§2.3 этап 4.2 — integration.js PASS)

- **Fix API:** `iframe.create('shop-payment')` + `mount(container, PaymentURL)` по [доке T-Bank](https://developer.tbank.ru/eacq/intro/developer/setup_js/setup_iframe); script `integrationjs.tbank.ru`.
- **Deploy:** `deployment-01KTDZYTAVDCSJNWKEFF86D2E4`, commit `5829f09`.
- **MCP:** корзина → оформление → `#/payment` — форма T-Pay/SberPay/карта **в iframe на нашей странице** — **PASS**.
- **Скрин:** [`stage4_payment_iframe_2026-06-06.png`](milestones/veha_2/artifacts/demo-feedback/screenshots/stage4_payment_iframe_2026-06-06.png).
- **Артефакт:** [`mcp_section_2_3_stage4_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage4_2026-06-06.json).
- **Дальше:** этап 5 — полная оплата + webhook.

### Сессия 2026-06-05 (§2.3 этап 4 — iframe оплата)

- **Код:** `Payment.svelte`, `tbankPayment.js`, `Shop::PaymentConfig`, CSP T-Bank, API `provider_payment_id`, `/shop/api/config`.
- **Deploy:** `deployment-01KTDZ0609R0DFVNCMK1AYV3N5`, commits `ebd5b31` + fallback embed.
- **MCP:** checkout → `#/payment` PASS; integration.js PARTIAL → embed `PaymentURL`.
- **Артефакт:** [`mcp_section_2_3_stage4_2026-06-05.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage4_2026-06-05.json).
- **Дальше:** этап 5 — полная оплата + webhook.

### Сессия 2026-06-05 (Fly deploy fix — release_command)

- **Проблема:** release_command SIGINT через ~4 с при boot Rails на 1 GB.
- **Fix:** `release_command_vm` 2x/2GB, timeout 10m, sleep+echo, health check только web — commit `8672def`.

### Сессия 2026-06-04 (§2.3 этап 2 — заказ после банка, PASS)

- **Баг:** после Т-Банка заказ не виден в «Заказы за сегодня» (сессия гостя терялась).
- **Фикс:** `GuestOrderReconnect` + `reconnect_token` + `/session/reconnect` + frontend `shopGuestSession.js`.
- **MCP:** [`mcp_section_2_3_stage2_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage2_2026-06-04.json), deploy `01KTC026K62C7QHT6JC3VRKNRS`.
- **Дальше:** этап 3 (оформление UX).

### Сессия 2026-06-04 (§2.3 — чеклист этапы 1–5, ops)

- **Главный документ:** [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](milestones/veha_2/requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md) — §2.3 MCP → код → iframe T-Bank → полная оплата.
- **Согласовано:** бариста/TV только `accepted`; fail/отказ — менеджер/УК; MCP обязателен перед `done`.
- **Следующий шаг:** этап 4 (iframe T-Bank / статусы).
- **Этап 3:** PASS — [`mcp_section_2_3_stage3_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage3_2026-06-04.json).
- **Ops:** `SESSION_STATE`, `DEMO_FEEDBACK` (честный статус), `CHANGELOG` v1.119.

### Сессия 2026-06-04 (УК → Меню → витрины A/B — ЗАКРЫТО на Fly)

- **Handoff для агента:** [`HANDOFF_UK_MENU_VITRINA.md`](milestones/veha_2/runbooks/HANDOFF_UK_MENU_VITRINA.md).
- **Критерий:** правки в УК → витрины **A/B без F5** за **~8–16 с** — **PASS** (`e398981` + MCP).
- **Создание товара:** УК → Меню в **браузере** → сразу на API A/B — **PASS** (`OPS-POSTDEPLOY-001` после deploy `1861f4f`). Заход в Меню «для PTS» в обычном flow **не нужен**.
- **Коммиты:** `589e397` PTS+API · `e398981` polling 8s · `1861f4f` publish sync вне TX · ops `ca684ab`/`f59bd1a`/`1861f4f`.
- **MCP:** [`mcp_uk_menu_autorefresh_fly_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_uk_menu_autorefresh_fly_2026-06-04.json).
- **Дальше:** §I живое демо; апрув push/deploy — владелец репо.

### Сессия 2026-06-04 (franchise staff + sync ops)

- **Код:** `staff_management_visible?` — GM/УК видят «Персонал», `franchise_manager` — нет; `require_staff_management!` на `StaffController`.
- **Коммиты:** `7311338`, `62ced8e`; ops `8ee6584`.
- **MCP Fly:** franchise — нет 👥, `/manager/staff` → redirect; gm-a — есть 👥 — **PASS** — [`mcp_franchise_staff_fly_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_franchise_staff_fly_2026-06-04.json).

### Сессия 2026-06-04 (§2.5 + A↔B + онбординг)

- **MCP Fly Slow 3G:** скелетон, фон `#1a1a1a`, меню — **PASS** — [`mcp_section_2_5_fly_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_5_fly_2026-06-04.json); post-deploy `ca6f2ef` — skeleton не залипает.
- **§2 A↔B:** `CustomerSession` fix + MCP — [`mcp_shop_ab_fly_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_shop_ab_fly_2026-06-04.json); коммит `6c5cc0b`.
- **Онбординг:** `Product.svelte` — баннер/подсветка; MCP post-deploy **PASS** (`6c5cc0b`).
- **Offline каталог:** текст ошибки в `Catalog.svelte` — post-deploy проверен.
- **Не делали:** физический подвал; оверлей >5 s (меню <5 s на Slow 3G).

### Сессия 2026-06-04 (§2.3–2.4: оплата, корзина при возврате с банка)

- **Код:** `OrderCreator` — корзина чистится только при `accepted`; `PendingOrderSession` + reuse pending; `PaymentReturnsController`; `PaymentResult.svelte`; `POST abandon/finalize`, `DELETE /cart`.
- **Тесты:** `order_creator_test`, `qa_section_2_3_payment_cart_test` — 0 failures (2 skip без TBANK в CI).
- **Fly deploy:** `deployment-01KT8Q97MRQS1S4T060MR3Y3ZQ` (release_command OK; warning listen 0.0.0.0:3000 — стенд отвечает).
- **MCP Fly post-deploy:** §2.3 **PASS** (корзина после банка: Бразилия 179₽) — [`mcp_section_2_3_fly_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_fly_2026-06-04.json).
- **§2.4 MCP+БД Fly:** двойной «Оплатить» — один редирект, 2-й клик blocked; `db_orders_count: 1` (`fly ssh` runner, тел. `+79001112244`) — [`mcp_section_2_4_fly_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_4_fly_2026-06-04.json).
- **Не в MCP:** успех оплаты + история (§2.4 дубли в БД — **PASS**, `db_orders_count: 1`).

### Сессия 2026-06-03 (§2.2: платные модификаторы)

- **Код:** миграция `20260603150000` + `Demo::EnvironmentSetup#repair_brazil_shop_modifier_prices!` (+15/+20/+40 на Бразилию); UI «· обязательно» на группах; корзина/оплата уже считали `price_delta`.
- **Тесты:** `qa_section_2_2_modifiers_test` — 179+20+40=239, заказ 199₽.
- **Fly:** нужен **redeploy + demo:seed** (или migrate на release); MCP — после.
- **MCP Fly (redeploy):** +15/+20/+40 на карточке; кордиал → **199₽** в корзине — **PASS** (`mcp_section_2_2_fly_2026-06-03.json`).
- **Следующий:** §2.3–2.4 оплата.

### Сессия 2026-06-03 (handoff ops: УК/staff, онбординг, апрув)

- **УК vs франчайзи:** staff у УК/GM (`/admin` → Точки → **Панель менеджера**); у franchise **«Персонал» убран** — см. сессию 2026-06-04 franchise staff.
- **Подсказки онбординга:** реализованы `6c5cc0b`, MCP post-deploy **PASS**.
- **Апрув:** PDF не блокер на каждый шаг; финальный прогон PDF позже.

### Сессия 2026-06-03 (post-deploy MCP batch)

- **После fly deploy:** Chrome MCP — §2 A↔B заказы, §3.6 `franchise@` → `/manager`, §1.3 «Открыть смену», §1.2 «Управляющий точки», §1.4 склад точки vs цех — **PASS**.
- **Артефакт:** `artifacts/demo-feedback/mcp_post_deploy_fly_2026-06-03.json`.
- **§2.2** модификаторы — отдельный MCP **PASS** (`mcp_section_2_2_fly_2026-06-03.json`). **Дальше:** §2.3–2.5.

### Сессия 2026-06-02 (§2.1: MCP Fly — витрина меню)

- **MCP Fly:** 3 шага PDF §2.1 на `shop?tenant_id=2fdee1ac-…` — каталог (Черный + карточки) → категория → карточка **Фильтр-кофе Бразилия** (179₽, Температура/Вкус/Интенсивность). **PASS**.
- **Приёмка:** скрин заказчика = карточка товара (не отдельный `<img>`).
- **Артефакт:** `artifacts/demo-feedback/mcp_section_2_1_fly_2026-06-02.json`.
- **§2.1 до апрува** заказчика в PDF.

### Сессия 2026-06-03 (§1.4: MCP Fly — остатки)

- **MCP Fly:** бариста A продажа Бразилия → **`/manager/inventory` точка A:** beans **3992→3974**, milk **−3400→−3550**; **цех** beans **−242** без изменений.
- **Решение:** не связываем цех↔точки в §1.4; правим текст сценария для заказчика (`LIVE_DEMO_SCENARIOS_PLAIN` §1.4).
- **Артефакт:** `artifacts/demo-feedback/mcp_section_1_4_fly_2026-06-03.json`.
- **§1.4 до апрува** заказчика (понимание: смотреть склад **управляющего точки**).

### Сессия 2026-06-02 (§1.3: смена — UI открыть/закрыть)

- **Код:** `CashShifts::OpenService`; POST open — бариста + manager; плашки в шапке; экран «Смены/Касса» с кнопками.
- **Демо:** seed закрывает смены A/B (не авто-открытие).
- **Тесты:** `qa_section_1_3_shift_flow_test` 4/0; `open_service_test` 2/0.
- **MCP:** `mcp_section_1_3_fly_2026-06-02.json` — прогон на Fly после deploy.
- **§1.3 до апрува** заказчика.

### Сессия 2026-06-02 (§1.2: изоляция GM + подпись роли)

- **MCP Fly:** §1.2 шаги 1–3 — изоляция A/B **PASS** (179 vs 189, gm-a без Point B); артефакт `artifacts/demo-feedback/mcp_section_1_2_fly_2026-06-02.json` + скрин дашборда.
- **Код:** `manager/shared/_layout` — для `general_manager` подпись **«Управляющий точки»**; тесты `qa_section_1_2_gm_isolation_test` (3/0), office panel обновлён.
- **Fly:** подпись на проде ещё «Офис-менеджер» до **deploy**; изоляция уже OK.
- **§1.2 до апрува:** функционально закрыт ops; апрув заказчика + перепроверка подписи после deploy.
- **Коммит:** `fix(manager): GM role label and §1.2 isolation QA` (+ ops).

### Сессия 2026-06-02 (§E: фидбек PDF + фиксы shop/franchise)

- **PDF:** `artifacts/demo-feedback/customer_qa_prog10_2026-06.pdf` (§1–3; §4+ нет).
- **DEMO_FEEDBACK:** 5 строк (2 blocker in_progress, 3 open).
- **Код:** `Shop::CustomerSession` — история заказов по точке; `franchise_owners#create` + `demo:seed` repair `organization_id`; login — приоритет роли `franchise_manager`.
- **Не сделано:** UI витрины (назад/свайп/+1), дотест оплаты, подвал slow-net; §4+ PDF.
- **Следующий:** deploy Fly → проверка заказчиком → `done` в DEMO_FEEDBACK.

### Сессия 2026-06-02 (ops: реорганизация артефактов вехи 2)

- **Зачем:** плоский каталог `veha_2/artifacts/prog10_*` был нечитаем для человека и агента; нужна группировка по смыслу блоков QA, без «одна папка = один файл».
- **Сделано:**
  - `artifacts/README.md` — оглавление вехи 2.
  - `artifacts/demo-feedback/README.md` — заготовка под §E (PDF/скрины заказчика; цепочка с `veha_1/artifacts/`).
  - `artifacts/prog10/README.md` — оглавление прогона 10.
  - **7 подпапок:** `_index` (сводки, tenant_ids, final_index), `smoke`, `kiosk`, `shop`, `staff-rbac`, `connectivity`, `platform-ent`, `warehouse`.
  - `git mv` всех JSON/MD артефактов прогона 10; `prog10_final_index.json` перенесён в `_index/` с путями относительно `prog10/`.
  - Обновлены ссылки: `QA_ACCEPTANCE_RUN`, `PROG10_TENANTS`, `PRACTICES`, `POSTMORTEM`, `CHANGELOG`, `SESSION_STATE`.
  - `bin/prog10_*` — дефолты `OUT` и пути к `tenant_ids.json`.
- **Не в коммите:** PDF в корне `artifacts/` (untracked) — положить в `demo-feedback/` при §E.
- **Push:** не делали (локальные коммиты).
- **Следующий шаг по вехе:** апрув блока 14 → §E [`DEMO_FEEDBACK.md`](milestones/veha_2/requirements/DEMO_FEEDBACK.md) → §I.

### Сессия 2026-06-02 (gate: тесты + Fly ops)

- **`bin/rails test`:** **562 runs, 0 failures** (WSL).
- **Fly deploy / secrets:** не выполнено агентом (нет `flyctl` token). Владелец: `flyctl auth login` → `fly secrets list -a coffeeos` (нужны `CALLBACK_SHARED_SECRET`, `CALLBACK_SHARED_TOKEN`) → `fly deploy`.
- **Веха 2 не закрыта** — только gate; §E / §I без изменений.
- **SEC-07:** задача закреплена в CHECKLIST блок 4 + PRACTICES V2-SEC-07.

### Сессия 2026-06-02 (прогон 10 — блок 14 postmortem)

- **Postmortem:** `POSTMORTEM_2026-05-28.md` — § «Прогон 10» (итог, fix, backlog, lessons).
- **Блоки 0–14** в CHECKLIST/QA — закрыты по ops.
- **Следующий:** апрув блока 14 → §E [`DEMO_FEEDBACK.md`](milestones/veha_2/requirements/DEMO_FEEDBACK.md) → §I (живое демо + «веха 2 закрыта»).

### Сессия 2026-06-02 (прогон 10 — блок 13 финал)

- **Апрув блока 12** → перепрогон Fly: `prog10/_index/prog10_final_block13.json` (9× cash+card, stress 8, kiosk 9×).
- **Stress wave 2:** `prog10/smoke/prog10_stress_wave2.json` обновлён.
- **Индекс:** `prog10/_index/prog10_final_index.json`; QA хвосты PASS/SKIP в `QA_ACCEPTANCE_RUN` §10d.
- **Следующий:** апрув блока 13 → блок **14** (postmortem).

### Сессия 2026-06-02 (прогон 10 — блок 12 склад)

- **Апрув блока 11** от заказчика → старт блока 12.
- Прогонены тесты склада/связности: `prep_kitchen_movements_test` + `onboarding_connectivity_test` = **6 runs, 50 assertions, 0 failures**.
- Артефакт: `prog10/warehouse/prog10_warehouse_block12.json` (barista PASS, prep movement PASS, foreign confirm blocked PASS).
- Зафиксировано: auto-link «точка → общий цех» в **V2-BACKLOG-PREP-MULTI** (после В2, Веха 3).
- Следующий: блок **13** (curl 9×, stress, RBAC, артефакты).

### Сессия 2026-06-02 (прогон 10 — блок 11 CON-02…06)

- **Апрув блока 3** от заказчика → старт блока 11.
- **CON-02:** Fly demo-a/b разные PTS (`prog10/connectivity/prog10_connectivity_con02_fly.json`); `tenant_isolation_test` 2/0.
- **CON-03/04/06:** `onboarding_connectivity_test` 3/0; **CON-05:** `prog10/staff-rbac/prog10_staff_isolation.json`.
- **Backlog:** `V2-BACKLOG-PREP-MULTI` — общий цех на несколько точек после В2.
- **Следующий:** апрув блока 11 → блок **12** (barista↔цех).

### Сессия 2026-06-02 (прогон 10 — блок 3 закрыт: CR-05 + CR-04)

- **CR-05:** `with_kiosk_tenant_guc!`; тесты **7/0**; Fly `POST /kiosk/api/auth` **9/9** — `prog10/kiosk/prog10_kiosk_auth_fly_cr05.json` (`bin/prog10_kiosk_auth_fly_verify.rb`).
- **CR-04:** **wontfix** на Fly 1 pod; при смене хостинга / 2+ инстансов → **Redis** — `PRACTICES`.
- **Git:** push `develop` **23 коммита** → `d80b518`. **Fly deploy:** не выполнен (нет `flyctl auth`); curl на текущем Fly — PASS.
- **Следующий:** апрув блока 3 → блок **11** (не начинать без апрува).

### Сессия 2026-06-02 (прогон 10 — блок 10 добивка: card + SHP-03)

- **card curl 5/5** — `prog10/shop/prog10_shop_vitrina_card_curl.json`; **card MCP 5/5** — редирект на оплату.
- **SHP-03/05** — `/shop` без tenant_id: `prog10/shop/prog10_shop_shp03.json`, `prog10/shop/prog10_shop_shp03_mcp.json`.
- **Следующий:** апрув блока 10 → **блок 3** (CR-05 GUC). Блок 11 — не начинать без апрува.

### Сессия 2026-06-02 (прогон 10 — блок 10, витрина 5 точек)

- **curl:** `bin/prog10_shop_vitrina.rb` — меню/корзина/checkout/история API — **5/5** (`prog10/shop/prog10_shop_vitrina_curl.json`).
- **MCP:** Puppeteer UI — каталог → корзина → наличные → SHP-09 — **5/5** (`prog10/shop/prog10_shop_vitrina_mcp.json`).
- **Следующий:** блок **11** — после апрува.

### Сессия 2026-06-02 (прогон 10 — блок 9, kiosk → barista ×9)

- **curl:** `bin/prog10_kiosk_barista.rb` — киоск auth + cash order + barista JSON/HTML — **9/9** (`prog10/kiosk/prog10_kiosk_barista.json`).
- **MCP:** Puppeteer — login barista, заказ на `/barista` — **9/9** (`prog10/kiosk/prog10_kiosk_barista_mcp.json`); demo-prep без панели barista — ожидаемо.
- **Следующий:** блок **10** — после апрува.

### Сессия 2026-06-02 (прогон 10 — блок 8, ENT карточка УК)

- MCP Puppeteer на **demo-a**: ENT-02 (Копировать URL), ENT-07 (edit + partial), ENT-08 (Создать staff → `/manager/staff`).
- Артефакты: `prog10/platform-ent/prog10_ent_card_mcp.json`, `prog10/platform-ent/prog10_ent_card_mcp.md`.
- **Следующий:** блок **9** — после апрува.

### Сессия 2026-06-02 (прогон 10 — блок 7, MCP 9 точек + STF-03)

- **curl:** 9/9 без изменений (`prog10/staff-rbac/prog10_staff_isolation.json`).
- **MCP +9 точек:** STF-01/02/04 на 9 точках; **STF-03** — создание barista на всех 9 (`prog10/staff-rbac/prog10_staff_mcp_9pt.json`); **STF-04** — login новых → `/barista` на sales_point (для `demo-prep` barista-модуль ожидаемо недоступен: `GET /barista` не отдаёт панель).
- **STF-03 UI:** demo-b — fill+click; остальные точки — POST форм в сессии Puppeteer (UK).
- **Следующий:** блок 8 — после твоего апрува (техготово 9/9).

### Сессия 2026-06-02 (прогон 10 — блок 7, MCP 3 org — срез 1)

- Первый срез 3 org: `prog10/staff-rbac/prog10_staff_mcp_3org.json` (STF-01/02/04 + ISO JSON).

### Сессия 2026-06-02 (прогон 10 — блок 6, staff wizard)

- В карточке точки УК добавлен wizard «первая команда»: шаблон логинов по роли (`gm`, `barista`, `shift`, для цеха `pkm/pkw`).
- В `STAFF_ACCESS` отмечены закрытыми хвосты: wizard и шаблон логинов для новой org.
- Тесты: `entry_points_test` 7/0; полный suite **561 runs, 2318 assertions, 0 failures**.
- Следующий: блок 3 (CR-05, CR-04).

### Сессия 2026-06-02 (прогон 10 — блок 5, gate кода)

- Полный `bin/rails test` в WSL: **559 runs, 2311 assertions, 0 failures**.
- Синхронизированы статусы блока 5 в `QA_ACCEPTANCE_RUN`, `PRACTICES`, `CODE_REVIEW`.
- Код не меняли; только ops-фиксация статуса gate.
- Следующий: блок 3 (CR-05, CR-04).

### Сессия 2026-06-02 (прогон 10 — блок 4, ops)

- **V2-CR-02:** auto-check секретов на Fly не выполнен — в среде нет `flyctl`.
- **Зафиксировано:** manual-check перед deploy обязателен (`CALLBACK_SHARED_SECRET`, `CALLBACK_SHARED_TOKEN` в Fly).
- **SEC-07:** `shop-api-key` в meta оставлен как backlog (демо-стенд).
- **Тесты:** suite **559/0**.
- **Следующий:** блок 3 (CR-05, CR-04).

### Сессия 2026-06-01 (прогон 10 — блок 2, витрина)

- **CSRF:** витрина в браузере — проверяем настоящий токен, не только заголовок.
- **Заказы:** чужой гость не видит заказ по id (только свой в сессии).
- **Тесты:** shop auth/orders 13/0; suite **559/0**.
- **Следующий:** блок 3 (kiosk GUC, CacheCounter).

### Сессия 2026-06-01 (прогон 10 — блок 1, код perf)

- **Код:** `CatalogBootstrap` — один prefetch PTS; `EntryPoints` — один запрос FeatureFlag.
- **Тесты:** onboarding 9/0; полный suite **555/0** (WSL).
- **Ops:** V2-CR-01 done, V2-006 в CODE_REVIEW; блок 1 ✅ в QA таблице.
- **Следующий:** блок 2 (CR-03, SEC-08).

### Сессия 2026-06-01 (прогон 10 — блок 0, план добивки)

- Зафиксированы: нет прогона 11; scope; таблица блоков 0–14; правило ops.
- Доки: `QA_ACCEPTANCE_RUN`, `PRACTICES`, `CODE_REVIEW`, `CHANGELOG` v1.77.
- **Код не трогали.** Следующий шаг: **блок 1** после апрува.

### Сессия 2026-06-01 (прогон 10c — финал QA)

- Shop 9×, stress wave 2, kiosk cash+card 9×, Prog10 barista login, prep, logout.
- Коммит `docs(ops): prog10c close full QA acceptance scope`.

### Сессия 2026-06-01 (прогон 10b)

- 9× cash/card, kiosk, RBAC, checkout MCP.

### Сессия 2026-05-30 (прогон 10 — черновик)

- Промежуточный журнал → дополнен 2026-06-01 (см. выше).

### Сессия 2026-05-30 (V2-T8 — flaky events_controller_test) — **done**

- **Проблема:** тест callback anti-replay — timestamp «299 с назад» на границе 300 с → иногда 401.
- **Fix:** `travel_to` + **200 с** запас; `ActiveSupport::Testing::TimeHelpers` в тест-классе.
- **Прогон:** `events_controller_test.rb` **23/0**; целевой тест **×5 PASS**.
- **Ops:** V2-T8 done — `PRACTICES`, `CHECKLIST` §H, `POSTMORTEM`, `CHANGELOG` v1.69.
- **§I:** не трогали.

### Сессия 2026-05-30 (Kiosk auth API — без закрытия §I)

- **Код:** `POST /kiosk/api/auth` (`c44b1eb`).
- **Docs:** FLUTTER_API, postmortem черновик.
- **§I:** галочки **не** ставить без апрува заказчика.

### Сессия 2026-05-25 (Fly URL: режим B vs поддомены A)

- **Проблема:** `fly certs add "*.coffeeos.fly.dev"` → ACME отказ; поддомены `{slug}.coffeeos.fly.dev` не резолвятся.
- **Решение:** два режима в `docs/operations/dev/SHOP_URL_MODES.md`. Fly demo = `?tenant_id=`; канон прод = `{slug}.{SHOP_BASE_DOMAIN}`. Slug в БД не трогаем.
- **Код:** `UrlBuilder` без дефолта домена; `fly.toml` без `SHOP_BASE_DOMAIN`; `demo:shop_urls`.
- **Следующий шаг владельца:** deploy develop → `fly ssh … demo:shop_urls` → smoke H.3. Свой домен — чеклист **A-inf** В2.

### Сессия 2026-05-26 (В2 онбординг §3)

- ONBOARDING §3 «Заготовочный цех» — `[x]`; тесты 2/0; код без изменений.

### Сессия 2026-05-26 (В2 онбординг §2)

- ONBOARDING §2 «Точка продаж» — `[x]`; добавлено `address` в форму; тесты 5/0.

### Сессия 2026-05-26 (В2 онбординг §1)

- ONBOARDING_CHECKLIST §1 «Организация» — `[x]`; код без изменений; тесты onboarding org.

### Сессия 2026-05-26 (передача заказчику на живое демо)

- Стенд Fly проверен: `/up`, витрина A/B, логин barista.
- **Готово к H.3:** [`../demo/CUSTOMER_HANDOFF.md`](../demo/CUSTOMER_HANDOFF.md), UUID витрин в plain-доке и DEMO_LOGINS.
- H.0 smoke отмечен `[x]` в чеклисте; **H.3 живое демо** — ждёт заказчика.

### Сессия 2026-05-25 (handoff: В2 старт, В1 открыта в ops)

- Push **15 коммитов** В1 + **fix(deploy)** `4a25187`.
- Ops: папка `milestones/veha_1/` в git (`.gitignore`); CHANGELOG v1.50–v1.54.
- Живое демо: `LIVE_DEMO_SCENARIOS.md` + `LIVE_DEMO_SCENARIOS_PLAIN.md` (простой язык, URL витрин, роли gm/shift в словаре).
- **Не в git** на момент записи: `LIVE_DEMO_SCENARIOS*.md`, частично `CHECKLIST`/`README` — закоммитить при удобстве.

## Что сделано

- ✓ Архивирован старый docs-контур в `docs/archive/2026-05-11-reset` (без удаления истории).
- ✓ В `docs/product` оставлены только базовые: `01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`.
- ✓ Создан `docs/product/core` и загружены 11 файлов ядра.
- ✓ Core-файлы переименованы по смыслу с сохранением индексов `01..11`.
- ✓ Добавлен `docs/product/core/README.md` (карта ядра).
- ✓ В `docs/agents/AGENTS.md` удалён блок «Воркфлоу задачи».
- ✓ Выполнено сравнение core SQL-доков с `db/schema.rb`.
- ✓ Размечены все 25 гэпов по статусам: `rename-only` / `missing-table`.
- ✓ Зафиксирован порядок батчей B0..B5 и анти-ошибочный чек-лист для каждого батча.
- ✓ Выполнен B1: добавлены `admin_audit_logs` и `feature_flags_logs` (миграция `20260511174500`).
- ✓ Прогон тестов после B1: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Выполнен B2: добавлены `billing_plans`, `billing_subscriptions`, `tenant_invitations` + `tenants.plan_id` FK (миграция `20260511180000`).
- ✓ Прогон тестов после B2: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Выполнен B3: добавлены `loyalty_accounts`, `loyalty_transactions`, `promo_code_usages`, `push_notifications`, `order_feedback` (миграция `20260511181500`).
- ✓ Прогон тестов после B3: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Прогон тестов после B3.5: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Выполнен B4: добавлены `pickup_calls`, `pickup_display_settings`, `pickup_events`; в `orders` добавлены `ready_at`, `issued_at`, `pickup_method` (миграция `20260511184500`).
- ✓ Прогон тестов после B4: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- ✓ Выполнен B5: `production_recipes`, `production_batches`, `supply_orders`, `supply_order_items`; расширение `ingredients` под production (миграция `20260511190000`).
- ✓ Прогон тестов после B5: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

## Результат анализа core→schema

- Покрытие по таблицам (baseline до батчей): `37/62` (≈ `59.7%`).
- После B1–B5 с rename-mapping: **`62/62`** по целевому списку gap-таблиц.
- Расхождения:
  1. Нейминг (singular/plural, `*_log` vs `*_logs` и т.д.).
  2. Отсутствующие таблицы этапов 9-12 (billing/loyalty/pickup/production/push и смежные).
- Вывод: текущее состояние рабочее, но не полностью синхронизировано с 11-этапной core-моделью.

## Следующий шаг

**Веха 1:** H.2 + code review (`docs/operations/milestones/veha_1/qa/CODE_REVIEW.md`, `docs/operations/milestones/veha_1/qa/QA_ACCEPTANCE_RUN.md`).  
**Владелец:** апрув → коммит/деплой → H.3 демо → § I.

Чеклист и журнал В1: `docs/operations/milestones/veha_1/` ([README](milestones/veha_1/README.md)).

## Блокеры

Нет

## Заметки

Цель текущего этапа: строгое выравнивание реализации под 11 core-доков без разрушения рабочего контура. Тактика: маленькие обратимые батчи + тесты + smoke после каждого батча.

---

[2026-05-01 18:18] | Действие: Ужесточен протокол ведения состояния в `.cursor/rules/prd-factory-agent.mdc` (добавлен `Hard Persistence Gate`: fail-closed блокировка продолжения без обязательных записей в `SESSION_STATE/ISSUES/HANDOFF/CHANGELOG`; добавлен обязательный стартовый блок `last_done/current_state/next_step` для новых сессий). | Следующий шаг: Проверить соблюдение gate в следующей реальной задаче и подтвердить, что агент сначала обновляет операции-доки, затем продолжает. | Вопросы: нет.

[2026-05-01 19:30] | Действие: Создана миграция для добавления уникального индекса на key_hash в solid_cache_entries. Деплой выполнен. Миграция прошла успешно. Ошибка 500 на /shop/api/categories сохраняется. | Следующий шаг: Диагностировать почему SolidCache все еще падает. Проверить схему БД на production. | Статус: blocked | Вопросы: нет.

[2026-05-01 19:45] | Действие: Диагностирована проблема — Rack::Attack использует increment для rate limiting, но SolidCache не поддерживает это правильно. Добавлена конфигурация Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new. | Следующий шаг: Деплой исправления на production. | Статус: in_progress | Вопросы: нет.

[2026-05-01 19:50] | Действие: Деплой выполнен. Ошибка исправлена. /shop/api/categories теперь возвращает 401 (требуется авторизация) — это правильное поведение. | Следующий шаг: Нет | Статус: done | Вопросы: нет.
[2026-05-01 21:14] | Действие: Обновлено правило PRD Factory для ускорения и устранения конфликта записей: `SESSION_STATE` после каждого действия (кратко), `ISSUES` сразу при ошибке, `CHANGELOG/HANDOFF` батчем в конце логического шага; добавлено правило "PRD/ARCHITECTURE читать полно один раз за сессию". | Следующий шаг: Проверить правило на следующей задаче и подтвердить снижение количества лишних записей. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: Добавлена rake `shop:catalog:load` + `ALLOW_SHOP_CATALOG_LOAD` в `.env.example` для заливки каталога без полного seed. | Следующий шаг: Локально `bin/rails shop:catalog:load`; на Fly при необходимости с секретом ALLOW_SHOP_CATALOG_LOAD=1. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: Prod `/shop/api/categories` давал 500: Solid Cache пишет через `Rails.cache`, индекс для upsert должен быть на стороне cache-миграций + защита read/write кэша в `CategoriesController`. Добавлено `db/cache_migrate/20260502100000_ensure_solid_cache_key_hash_unique_index.rb`, `safe_cache_read/write`, `db/cache_schema.rb` обновлён. Деплой `fly deploy --no-cache`. Проверка: GET categories → HTTP 200. | Следующий шаг: При необходимости Resolve в Sentry для RUBY-3; мониторинг новых событий. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: PRD Factory режим C→B — глубокий аудит `prd-factory-agent.mdc` + `docs/agents/AGENTS.md`: 100 сценариев «триггер → ожидание → типичный сбой → рычаг усиления»; выявлено ключевое противоречие батч-записей (v10) vs «обновляй все ops-доки после каждого шага» (AGENTS). Отчёт пользователю в чате; файлы инструкций не менялись. | Следующий шаг: По явному go — точечные дополнения в `.cursor/rules/prd-factory-agent.mdc` и/или приписка приоритета в `AGENTS.md` без переписывания существующего смысла. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: По `go` пользователя — дополнения анти-игнор: `.cursor/rules/prd-factory-agent.mdc` (TL;DR срочность, приоритет операционки над AGENTS при конфликте, конец сессии HANDOFF+SESSION_STATE, git rewrite + Merge Conflict Gate, расширение Воркфлоу handoff’ами и mid-sprint); `docs/agents/AGENTS.md` — новые пункты без удаления старых. | Следующий шаг: Коммит при желании пользователя; соблюдение новых пунктов в следующих задачах. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: Инвентаризация «PRD в архиве»: в репозитории нет папки `docs/archive/` и нескольких версий продуктового PRD — канон один: `docs/product/PRD.md` + `docs/product/ARCHITECTURE.md` (оба короткие); рядом процессные `SPRINT_1_PROMPT.md`, `START.md`, AGENTS/pm/architect и т.д.; `CHANGELOG` v1.0 перечисляет создание канона; `docs/shop_api_auth.md` из старого CHANGELOG в дереве не найден. | Следующий шаг: Расширение PRD под онбординг точки — только после явного `go` и фиксации требований. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: Уточнение: в `docs/` не только `product/`+`operations/`+`agents/` — полный `cmd dir` показывает `ARCHIVE.md`, `features/` (в т.ч. `ADMIN_PANELS_LOGIN.md` — сценарии франчайзи/УК), `architecture/`, `guides/`, `prep-kitchen/`, `stack/`, `troubleshooting/`, `analysis/`, `sprint_24-04/`, `reviews/`, `project/`, `devdep/` и др. Отдельной папки `docs/archive/` нет; `docs/ARCHIVE.md` трактует весь `docs/` как архивный слой, канон в `docs/product/`. | Следующий шаг: по задаче — читать feature/architecture гиды, сверять с кодом (возможен drift). | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: По `go` — сформирован перечень вопросов для PRD (онбординг точки: кто жмёт, состав сущностей, роли/дубликаты franchise_manager, выдача пароля, канон URL shop/manager, каталог, MVP границы, идемпотентность, «своя БД» = RLS vs отдельный PG). Ответ в чате; `PRD.md` не менялся. | Следующий шаг: ответы пользователя/PM → внести в `docs/product/PRD.md` (или приложение) → затем `go` на архитектуру/реализацию. | Статус: done | Вопросы: см. чат 2026-05-02.

[2026-05-02] | Действие: Ответы заказчика по онбордингу внесены в `docs/product/PRD.md` (секция + глоссарий); `docs/operations/journal/CHANGELOG.md` v1.9. | Следующий шаг: `go` на обновление `ARCHITECTURE.md` (поддомены, shop↔tenant, сервис онбординга) → реализация. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: По `go` выполнен Architect Pre-Feature шаг: `docs/product/ARCHITECTURE.md` дополнен секцией по онбордингу v1 (точка входа УК, состав сущностей, URL/поддомены, tenant/RLS, аудит, идемпотентность, границы v1). Обновлён `docs/operations/journal/CHANGELOG.md` до v1.10. | Следующий шаг: `go` на Change Protocol — декомпозиция реализации по файлам/миграциям/тестам без кода в этом шаге. | Статус: done | Вопросы: нет.

[2026-05-02] | Действие: По `go` выполнен Change Protocol без кода: определены этапы реализации онбординга точки (сервис провижининга, контроллерный orchestration, поддоменный резолвер tenant, аудит, загрузка каталога на tenant, тесты интеграции и модели, rollout под feature flag). | Следующий шаг: `go` на реализацию Этапа 1 (сервис + минимальный wiring без миграций). | Статус: done | Вопросы: требуется подтвердить формат поддомена (slug org + slug address).

[2026-05-03] | Действие: По `go` реализован онбординг точки в УК: `Platform::TenantOnboarding::{Provision, CatalogBootstrap, UrlBuilder}`; create/update в транзакции с откатом при ошибке; автоматические PTS для активных продуктов; витрина резолвит tenant по поддомену (`SHOP_BASE_DOMAIN`, в проде по умолчанию coffeeos.fly.dev); flash со ссылкой на витрину; тесты + интеграция shop API по Host; `.env.example` — `SHOP_BASE_DOMAIN`. Миграций нет. | Следующий шаг: на Fly при необходимости wildcard DNS для `*.coffeeos.fly.dev`; полный `bin/rails test`. | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Зафиксирован Шаг 1 — `docs/operations/reference/GAP_LIST_CORE_SCHEMA.md` (сравнение core->schema, покрытие 59.7%, список missing/extra, контроль ошибок на этапе gap-list, план Шага 2). | Следующий шаг: апрув пользователя на Шаг 2 (классификация `rename-only`/`missing-*`/`intentional`, затем батч-миграции с тестами). | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: По апруву пользователя завершена классификация всех 25 гэпов в `docs/operations/reference/GAP_LIST_CORE_SCHEMA.md`, добавлены статусы, батчи B0..B5 и чек-лист анти-ошибок (baseline, collisions, reversible migrations, test+smoke после каждого батча). | Следующий шаг: старт B0 (rename-only mapping), затем B1 с первой парой таблиц. | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Выполнен B1 — миграция `20260511174500_create_admin_audit_and_feature_flags_logs.rb` (таблицы `admin_audit_logs`, `feature_flags_logs`), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B2 (`billing_plans`, `billing_subscriptions`, `tenant_invitations`) по тому же safety-протоколу. | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Выполнен B2 — миграция `20260511180000_create_billing_and_tenant_invitations.rb` (таблицы `billing_plans`, `billing_subscriptions`, `tenant_invitations`; добавлен `tenants.plan_id` + FK), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B3 (`loyalty_accounts`, `loyalty_transactions`, `promo_code_usages`, `push_notifications`, `order_feedback`). | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Выполнен B4 — миграция `20260511184500_create_pickup_tables_and_orders_fields.rb` (таблицы `pickup_calls`, `pickup_display_settings`, `pickup_events`; поля `orders.ready_at`, `orders.issued_at`, `orders.pickup_method` + constraint/indexes), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B5 (`production_batches`, `production_recipes`, `supply_orders`, `supply_order_items`). | Статус: done | Вопросы: нет.

[2026-05-14] | Действие: Удалён `.cursor/rules/prd-factory-agent.mdc`. Переписан `.cursorrules` (верх: ISSUES сразу и до «решено», SESSION_STATE батчами, коммиты, продукт Vision/Functional/Business, ARCHITECTURE по готовности, деструктив только с явным «да»). Синхронизирован `docs/agents/AGENTS.md`; шапка `docs/operations/ISSUES.md`; `CHANGELOG.md` v1.20. | Следующий шаг: по необходимости — коммит ветки с этими правками. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Оценка практик Dodo; В1 — только Service Objects, без Domain Folders. Правила: `coffeeos-core.mdc` п.9, `coffeeos-services.mdc`, `AGENTS.md`. Журнал: `MILESTONE_PRACTICES.md`. Код не меняли. | Следующий шаг: апрув → батч приведения кода. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Добавлены unit-тесты prep_kitchen stock (3 файла) + health `TenantChecker`; прогон `test/services/` + platform tenants (86/0) и полный suite (337/0). `db:migrate` test для `20260520000001–02`. | Следующий шаг: апрув → сервис отмены заказа бариста; при необходимости — ISSUES на `MovementCreator` nested save. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: `Barista::OrderCancellationService` + тесты; контроллер `cancel` тонкий; fix `qty_change` и безопасное обновление остатка. Прогон barista tests 47/0. Чеклист VEHA_1 п. A отмена — [x]. | Следующий шаг: MovementCreator или следующий пункт чеклиста от пользователя. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: `MovementCreator` — transaction, movement create! затем items; тесты happy-path (10/0 stock). Чеклист VEHA_1 — [x]. | Следующий шаг: следующий пункт чеклиста от пользователя. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Аудит оркестрации в контроллерах — 3 новых сервиса (status update, payment callback, publish product). Чеклист A «пройти контроллеры» [x]. Тесты 75/0. | Следующий шаг: пункт B чеклиста от пользователя. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Полный `bin/rails test` после рефактора Service Objects (блок A): **347 runs, 1166 assertions, 0 failures**. Сводка «что/зачем» — `MILESTONE_PRACTICES.md` § «Рефактор Service Objects». Чеклист A полностью [x]. | Следующий шаг: блок B чеклиста. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Блок B — CRUD и связи MVP-моделей: `test/models/mvp_core_models_test.rb` (17 runs). Полный suite **364/1217/0**. Чеклист B первый ⭐ [x]. | Следующий шаг: демо-среда (2 точки, PTS, роли). | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Блок C — prep_kitchen_worker RBAC; `prep_kitchen_worker_rbac_test.rb` (6); полный suite **439/1644/0**. Чеклист C prep_kitchen_worker [x]. | Следующий шаг: platform/УК RBAC. | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Блок **E спец-тесты** — `block_e_shop_flow_test.rb` (5), auth browser session; shop suite **57/147/0**. MCP и полный suite **не запускали**. | Следующий шаг: **апрув** → MCP DevTools shop → полный suite → `[x]`. | Статус: awaiting_mcp_approval | Вопросы: нет.

[2026-05-21] | Действие: Блок **E фаза 1** — Svelte shop: fix categories `{data}`, modifiers required/optional, mock «Оплатить», история `?today=1`, skeleton, double-click, cart modifiers, browser CSRF auth для same-origin `/shop`. Локально: `test/integration/shop/` + `test/services/shop/` **51/113/0**. | Следующий шаг: **апрув** → спец-тесты E → MCP → полный suite → `[x]`. | Статус: superseded | Вопросы: нет.

[2026-05-21] | Действие: Блок **D закрыт** — полный `bin/rails test` **455/1795/0**; fix тестов под глобальные `order_cancel_reasons` (Demo::EnvironmentSetup) + PTS assertions; чеклист D все `[x]`. | Следующий шаг: блок **E** (Shop Svelte). | Статус: done | Вопросы: нет.

[2026-05-21] | Действие: Критические фиксы D — movement form/params; миграция `20260523140000` (trigger `generate_order_number`); `Demo::EnvironmentSetup` (смена, cancel reasons, stock, stop-list reset); целевые тесты **42/206/0**. | Следующий шаг: **апрув** → `bin/rails test` → `[x]` блок D. | Статус: superseded | Вопросы: нет.

[2026-05-23] | Действие: Блок D — MCP **POST**-флоу 7 ролей (org/tenant/owner/open_as_manager; switch_tenant; GM price+staff; barista order+cancel; PK movement confirm/min_qty/stop-list; PK worker blocked). Подготовка: demo:seed + tmp/mcp_setup.rb + restart rails s. GET ранее OK. Полный suite **не запускали**. | Следующий шаг: **апрув** → `bin/rails test` → `[x]` блок D. | Статус: superseded | Вопросы: barista repeat order — исправлено v1.41.

[2026-05-23] | Действие: Блок D — Chrome DevTools MCP: 7 ролей, все GET-экраны OK; fix login email regex; dev db:migrate; smoke 7/84/0. POST-флоу не гоняли. Полный suite **не запускали** — ждём апрув. | Следующий шаг: апрув → `bin/rails test` → `[x]` блок D. | Статус: in_progress | Вопросы: нет.

[2026-05-21] | Действие: Блок D prep — `DEMO_LOGINS.md`, `test_login.rake`→`Demo::EnvironmentSetup`, чеклист D+MCP, `block_d_panel_screens_test` (7/84/0). MCP Chrome DevTools errored. Полный suite **не запускали** — ждём апрув. | Следующий шаг: апрув → `bin/rails test`; MCP visual flows. | Статус: superseded | Вопросы: включить MCP в Cursor Settings.

[2026-05-24] | Действие: Блок **G закрыт** — апрув на полный suite; `bin/rails test` **479/1896/0** (~286 s), ошибок/failures нет. Фиксы до прогона: `PortKiller`/`bin/ensure-server`, JS корзины barista, `normalize_cart_items`, `@shift` на create-order. MCP barista+shop OK. Чеклист G все `[x]`; `MILESTONE_PRACTICES` §G, `CHANGELOG` v1.48. | Следующий шаг: блок **H** — ручной QA `qa_scenarios.md`, живое демо. | Статус: done | Вопросы: нет.

[2026-05-25] | Действие: Push **16 коммитов** В1 на `develop`; Fly deploy fix (npm win32, v1.53). Доки живого демо: `LIVE_DEMO_SCENARIOS*.md`. Ops: `HANDOFF.md`, `CHANGELOG` v1.54. **В1 официально не закрыта** — параллельный старт **В2**. | Следующий шаг: агент **В2** по `HANDOFF.md`; В1 закрыть заочно (H.3 + §I). | Статус: veha2_active_veha1_open | Вопросы: закоммитить LIVE_DEMO в git при удобстве.
