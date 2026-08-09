# Архив CHANGELOG — 2026-07

> Перенесено из `docs/operations/journal/CHANGELOG.md`.
> Агент: не читать на старте; только по явному запросу про этот месяц.

## 2026-07-31 — deploy: Status inside cart sheet v418 + MCP PASS
- Push `876b5432` · `fly deploy` → **v418**
- MCP: status DOM внутри `shop-cart-sheet`, `embedded=true`, CSS `relative` (не overlay)
- Evidence: `artifacts/status_inside_cart_sheet/mcp/fly_v418/`

## 2026-07-31 — feat: OrderStatusSheet inside CartSheet (not overlay)
- Статус активных заказов — секция внутри `CartSheet` (`embedded`), не sibling fixed z-60 в `App`
- CSS: relative flow, без отдельной «второй шторки»; modes/accordion/cable сохранены
- Mount tests 5/5; JS order_status + terminal refresh PASS; `CART_SHEET_BUILD=prog36`
- ТЗ: `customer_tasks/Статус заказа внутри шторки корзины не слой поверх.md`

## 2026-07-31 — deploy: Quick Repeat v417 + Fly MCP re-verify PASS
- Push `develop` `6fa90731` · `fly deploy --remote-only` → **v417**
- MCP Point A: full-width `390/390`; Quick Repeat hidden; peek/expanded; one-open
- Evidence: `artifacts/quick_repeat_bottom_sheet/mcp/fly_v417/`
- ISSUES QR/width остаётся **resolved** (закрыт на v416; v417 re-verify)

## 2026-07-31 — deploy: Quick Repeat v416 + Fly MCP PASS
- Push `develop` `0b71d5f9` · `fly deploy --remote-only --depot=false` → **v416**
- MCP Point A: API `has_active_order:true` + `frequent_items:[]`; UI без «повторить»
- OrderStatusSheet full-width: `left/right=0`, `width=390=vw`, `z=60`
- Evidence: `artifacts/quick_repeat_bottom_sheet/mcp/fly_v416_2026-07-31/`
- ISSUES QR/width → **resolved**

## 2026-07-31 — MCP local: Quick Repeat feedback 07
- Mobile viewport 390px: status sheet width 390px, Quick Repeat hidden при active
- `peek` / `expanded` / `hidden` подтверждены; при переключении заказов открыт ровно один receipt
- Evidence: `artifacts/quick_repeat_bottom_sheet/mcp/local_feedback_07/`

## 2026-07-31 — review: Quick Repeat hide on active order + full-width status
- BE: `HIDE_REPEAT_STATUSES`, `has_active_order`, cache `shop/freq/v3`, barista bust
- FE: `hasActiveOrder` / CartSheet `showRepeat`; Cable terminal → refresh frequent
- OrderStatusSheet full viewport width (`left/right:0`, z60)
- Suite 89 Rails + 18 JS PASS; rubocop clean; ISSUES Fly QR/width → code done (MCP after deploy)

## 2026-07-31 — docs: Quick Repeat — PHASE 1 SPEC (active order hide)
- `todo.md`: reuse service/API/CartSheet; gaps B1–B4 + F1–F3
- Hide-статусы = `Order.active` (`accepted/preparing/ready`); cache v3; bust barista
- `pending_payment` не скрывает повтор; CBR → SPEC `[x]` · RED ждёт go

## 2026-07-31 — docs: Quick Repeat Bottom Sheet — ревизия интейка (active order hide)
- ТЗ обновлён 1:1: **NEW** hide «повторить» при `created`/`accepted`/`cooking`/`ready` + `has_active_order`
- Скрины канона UI заменены (6 PNG `*_2026-07-31.png`); старые → `_archive_2026-07-21/`
- CBR / customer_tasks README: **ревизия интейк `[x]`** · SPEC ждёт go · код не трогали

## 2026-07-31 — deploy(#36): Fly v415 + MCP PASS accordion receipt
- Push develop + `fly deploy` → **v415**
- MCP: one-open accordion + text receipt vs screens 01/02 PASS
- Evidence: `artifacts/active_orders_accordion_receipt/mcp/`

## 2026-07-31 — review(#36): Active orders accordion + text receipt
- Suite 11 Rails + 27 JS PASS; rubocop presenter clean
- Sanity: N+1/RLS/text-only receipt/one-expanded/#35 peek PASS
- PRACTICES: accordion split, stub CTA copy
- MCP Fly — после deploy-апрува

## 2026-07-31 — feat(#36): active orders accordion with text receipt [GREEN]
- `Shop::ActiveOrdersPresenter` expands `/orders/active` (items/mods/totals/sales_point)
- FE accordion: one-open + scrollable text receipt in OrderStatusSheet
- Focused shop tests + vite build PASS

## 2026-07-31 — docs(#36): revise TZ to receipt-only accordion
- Scope: убран repeat/«Повторить»; чек только текст (items/mods/totals)
- ТЗ: `…с просмотром состава чека.md`; артефакты `active_orders_accordion_receipt/`
- Скрины заменены (1 / 2 заказа); SPEC/todo/CBR синхронизированы; RED не начат

## 2026-07-31 — docs(#36): SPEC Active orders accordion + repeat
- `todo.md` — reuse #35 active/sheet/CartService; gaps A1–B6; 404≠403; per-line product_id
- Код не менялся; RED ждёт намерения

## 2026-07-31 — docs(#36): intake Active orders accordion + repeat
- ТЗ: `customer_tasks/Мульти-статусная шторка активных заказов с повторной покупкой.md`
- Артефакты: `artifacts/active_orders_accordion_repeat/` — 2 скрина (1 / 2+ заказов expanded)
- CBR backlog + индекс #36 · статус интейк; SPEC ждёт go

## 2026-07-31 — deploy(#35): Fly v414 + MCP PASS sticky status
- Push develop + `fly deploy` → **v414**
- UI: labeled progress (Принят→Готов) + track/fill на sticky sheet
- MCP: z60/cart coexistence PASS; evidence `artifacts/…/mcp/`
- ISSUES #35 layering — resolved

## 2026-07-31 — fix(#35): MCP status/cart layering and cable reconnect
- Fly MCP выявил: status sheet скрыта под CartSheet (`z40<z50`)
- Fix: status `z60`, справа 7.5rem под cart actions, orange divider
- Fix: active GET только после реального Cable disconnect, без initial resubscribe loop
- Tests: mount 5/5, JS 14/14, Vite build PASS
- Full shop regression: 460 runs, 24 unrelated legacy failures → ISSUES

## 2026-07-31 — review(#35): Order status sheet + Push REVIEW
- Suite 34 Rails + 14 JS PASS; rubocop Wallet/job clean
- Fix: sticky sheet drops terminal Cable statuses (issued/cancelled/closed)
- PRACTICES: Wallet PKCS7, push reliability, orders_controller split
- MCP Fly — после deploy-апрува

## 2026-07-31 — feat(#35): ReadyPushJob + Apple Wallet stub [GREEN B3]
- `ReadyPushJob`: Wallet update → FCM; unavailable → FCM-only; gen error → retry
- DDL `order_wallet_passes`; `Shop::AppleWallet::*` (WALLET_SIMULATE)
- Notifier ready → ReadyPushJob after claim; runbook APPLE_WALLET_ORDER_PASS
- Тесты 17/17 PASS; PKCS7/device register — backlog

## 2026-07-31 — feat(#35): OrderStatusSheet sticky + orders/active [GREEN A1–A3]
- Cable payload: `order_number`; FE cable forwards order_id/number
- `GET /shop/api/orders/active` (accepted/preparing/ready)
- `orderStatusSheet.js` + sticky `OrderStatusSheet` (peek, scroll >2, reconnect)
- App mount; tests JS 13 + Rails A1/A3/mount PASS

## 2026-07-31 — feat(#35): ready_notified_at + ReadyPushClaim [GREEN C1]
- DDL: `orders.ready_notified_at` (nullable timestamptz)
- `Shop::ReadyPushClaim` — atomic first-ready claim
- `OrderStatusPushNotifier` — skip duplicate ready-push
- Тесты: ready_push_claim + notifier PASS

## 2026-07-31 — docs: SPEC #35 Order status compact sheet + Push
- `todo.md` — EXISTING/Gaps, маппинг GuestOrderChannel/FCM/Solid Queue, блоки A/B/C
- Sticky sheet + multi>2 + ready_notified_at (Migration Gate); Wallet backlog
- Код не менялся; RED ждёт go

## 2026-07-31 — docs: intake #35 Order status compact sheet + Push
- ТЗ: `customer_tasks/Интеграция статусной модели в компактную шторку PWA и Push.md`
- Артефакты: `artifacts/order_status_compact_sheet_push/` — 5 скринов заказчика (канон UI)
- CBR: backlog + индекс #35 · интейк `[x]` · SPEC ждёт go

## 2026-07-30 — MCP #34 Fly: UI OK, T-Bank Recurrent/Charge blocked
- Чекбокс bind + `save_sbp_account` → 422 **3013** Recurrent недоступны
- Ручной СБП → NSPK QR PASS; карта Charge → 422 **10**
- Zero-Click SUCCESS NO-GO до ЛК T-Bank
- Артефакт: `mcp_fly_sbp_autopay_2026-07-30.json`

## 2026-07-30 — feat(#34): Checkout UI SBP account + bind checkbox
- GET `/user/cards` → `sbp_accounts` / `has_sbp_account`
- PaymentMethodsSheet: «Ваш счет СБП» (default) + чекбокс привязки
- Checkout: Zero-Click `sbp/charge` + fallback CHARGE_DECLINED → manual SBP
- `api.js`: `err.body` для error_code; тесты UI PASS

## 2026-07-30 — review(#34): SBP Autopay ownership + settle after ChargeQr
- `SbpAutopayChargeService`: сессия ≠ владелец заказа → 404; токен только от order.customer
- После успешного ChargeQr — `PaymentStatusUpdater` (не оставлять pending при ответе CONFIRMED)
- `order.with_lock` перед Init/Charge; тест mismatch customer
- PHASE 3 REVIEW ops

## 2026-07-30 — feat(#34): SBP Autopay AccountToken ChargeQr [GREEN]
- BE: TbankSbpAutopay, SbpAccountTokenStore, FromWebhook, SbpAutopayChargeService
- API: save_sbp_account на sbp/init; POST sbp/charge
- FE: shopSbpAutopay.js FSM/toasts
- Тесты 21+10 PASS; регрессия оплаты PASS

## 2026-07-30 — docs: SPEC #34 T-Kassa SBP Autopay AccountToken
- `todo.md` — PHASE 1: gaps, маппинг CoffeeOS, 4 шага, Migration Gate (reuse MPM sbp)
- CBR/README: статус SPEC `[x]` · RED ждёт go
- Код не менялся; live MCP blocked терминалом (#32 Charge)

## 2026-07-30 — docs: intake #34 T-Kassa SBP Autopay AccountToken
- ТЗ: `customer_tasks/Интеграция Автоплатежей СБП Т-Касса в PWA.md` (текст заказчика 1:1)
- Артефакты: `artifacts/tbank_sbp_autopayments_account_token/`
- CBR индекс #34 + backlog · README customer_tasks
- Код не менялся; SPEC ждёт go

## 2026-07-30 — MCP #32 SUCCESS blocked: T-Bank Charge disabled
- Deploy `c9e68271` на Fly OK; one-click создаёт pending order + primary card
- `widget_init` 422 `error_code=10`: «Метод Charge заблокирован для данного терминала»
- Артефакт: `mcp_fly_inline_pay_2026-07-30_charge_blocked.json`
- Нужно: включить Charge/Recurrent в ЛК T-Bank на TerminalKey стенда

## 2026-07-30 — fix(#32): defer Init + widget Charge by RebillId
- BE: `defer_payment_init` в OrderCreator — без двойного Init (причина 422)
- BE: `Shop::WidgetPaymentInitiator` — RebillId primary card → Init+Charge, sync GetState
- FE: `createRepeatInlineOrder` шлёт `defer_payment_init: true`
- Тесты: widget_initiator + widget_init API PASS

## 2026-07-30 — MCP Fly #32 PASS (PROCESSING/ERROR/SBP/SMS)
- Point A / Aram: one-click → inline PROCESSING → ERROR + СБП/карта+ → SMS pinpad
- Не уходит в checkout; fallback не сбрасывается через 3 с
- SUCCESS blocked: `widget_init` 422 на стенде
- Артефакт: `mcp_fly_inline_pay_2026-07-30_pass.json`

## 2026-07-30 — fix(#32): inline pay UI store + clear cart before order
- FE: `repeatInlinePayUiStore` — статусы переживают remount RepeatSection (empty→peek)
- FE: `createRepeatInlineOrder` — DELETE `/cart` перед add (только позиция повтора)
- Deploy + MCP повтор

## 2026-07-30 — fix(#32): one-click создаёт pending order + last_order_id v2
- BE: `frequent_items[].last_order_id` + cache key `shop/freq/v2/…`
- FE: `createRepeatInlineOrder` → корзина + POST `/orders` (не checkout fallback)
- FE: PROCESSING UI сразу при клике; `runRepeatWidgetPayFlow` принимает готовый `fsm`
- Тесты: frequent + JS create/inline/sms PASS

## 2026-07-30 — MCP Fly #32 inline pay: FAIL (last_order_id null)
- Прогон Point A / Aram: бандл #32 на Fly есть, но «оплатить в клик» → checkout
- Причина: `frequent_items[].last_order_id = null` → не вызывается widget/inline FSM
- Артефакт: `mcp_fly_inline_pay_2026-07-30.json` · вердикт **NOT READY** для заказчика

## 2026-07-30 — feat(#32): SMS pinpad + ERROR/SUCCESS UI + poll HTTP edge [GREEN]
- FE: `shopSmsPinPad.js` + `SmsPinPad.svelte` — смс код, таймер 00:59, numpad
- FE: `NewCardForm` — `showSmsPinPad` (inline); checkout без пинпада
- FE: SUCCESS ✔ зелёная / ERROR красная / reset IDLE 3 с (`TBANK_INLINE_ERROR_RESET_MS`)
- FE: poll HTTP 400/500 → `http_error` + generic label
- Тесты: JS inline+sms+widget PASS · NewCardForm step1 UI PASS

## 2026-07-30 — feat(#32): inline pay FSM + UI по скрину заказчика [GREEN]
- Артефакт скрина: `tbank_inline_payment_button_statuses/screenshots/01_full_flow_schema_status_sbp_cards_form.png`
- FE: `shopInlinePayFsm.js` — poll 1500ms / ротация 1800ms / timeout 15s / 1051
- FE: `widgetRepeatPayFlow.js` + wiring `RepeatSection` / `InlinePayFallback` (белые СБП·карта+, expanded, NewCardForm)
- Тесты: `shop_inline_pay_button_fsm_test` + widget — 23/23 PASS
- Backlog: SMS-пинпад 00:59 в NewCardForm

## 2026-07-29 — T-Kassa Widget One-Click + Fallback (#33) — Шаги 4–7 GREEN
- FE: `widgetInlinePay.js` — init/poll/isCardRelatedError для inline widget pay
- FE: `InlinePayFallback.svelte` — inline fallback UI (статус-плашка, СБП, карта+, expanded cards)
- FE: `RepeatSection.svelte` — inline widget pay flow (init→poll→confirm/reject→fallback→SBP/cards)
- Тесты FE: 17/17 PASS · BE регрессия PASS

## 2026-07-29 — PHASE 3 REVIEW: T-Kassa Widget #33 (Шаги 4–7)
- Регрессия shop/payments + tbank: PASS
- RLS/tenant isolation: PASS
- `bin/rubocop`: PASS

## 2026-07-29 — T-Kassa Widget One-Click + Fallback (#33) — Шаги 1–3 GREEN
- BE: `connection_type: "Widget"` в Init DATA (`TbankInlineInit` + `TbankAdapter`)
- BE: `POST /shop/api/payments/widget_init` — сумма из БД, 404, стандартизированные ошибки
- FE: `shopWidgetPayFsm.js` — FSM IDLE→PROCESSING→SUCCESS/ERROR/FALLBACK (карточные ошибки)
- Тесты: 17/17 PASS · регрессия оплаты 64/0

## 2026-07-29 — Deploy: Auth funnel Flash×2→SMS → Fly
- `git push origin develop` + `fly deploy` — `cd26cb1b`
- Fly machines healthy, витрина + API 200, Rack::Attack 429 OK, логи без 500

## 2026-07-29 — PHASE 3 REVIEW: Auth funnel Flash×2→SMS
- REVIEW cleanup: убран мёртвый код MessengerDeliveryError, generate_sms_code, rescue SmsClient/FlashCallClient
- rubocop 0 offenses на новых файлах
- N+1 check: все запросы одиночные, без циклов
- RLS check: MobileOtpCode по phone, без tenant_id — корректно
- 38 runs (BE 23 + FE 15), 0F, 0E — PASS

## 2026-07-29 — feat: SmsRuClient + PhoneOtp cascade Flash×2→SMS [GREEN]
- `app/services/shop/sms_ru_client.rb` — единый клиент SMS.ru (flash_call /code/call + sms /sms/send)
- `app/services/shop/phone_otp.rb` — убран messenger, flash_call через SmsRuClient, sms переиспользует код
- `app/frontend/lib/phoneAuthCascade.js` — убрана фаза MESSENGER, каскад Flash×2→SMS за 40с
- `app/controllers/shop/api/phone_otp_controller.rb` — ip passthrough, убран messenger rescue
- `config/initializers/rack_attack.rb` — убран messenger throttle
- `app/frontend/components/PhoneAuthCodeStep.svelte` — убрана messenger кнопка/fallback
- Тесты: 38 runs total, 0F, 0E. Регрессия shop integration PASS.

## 2026-07-29 — docs: intake T-Bank inline payment button statuses

- PHASE 0: ТЗ заказчика дословно → `customer_tasks/Интеграция inline-оплаты Т-Банка с динамическими статусами внутри кнопки.md`
- Артефакты: `artifacts/tbank_inline_payment_button_statuses/`
- Индекс CBR + `customer_tasks/README` · статус **интейк `[x]`** · SPEC ждёт go

## 2026-07-29 — docs: intake customer task Flash Call×2 → SMS
- PHASE 0: ТЗ заказчика дословно → `customer_tasks/Рефакторинг воронки авторизации PWA Каскад Flash Call x2 SMS.md`
- Артефакты: `artifacts/auth_funnel_flash_call_x2_sms_ru/`
- Индекс CBR + `customer_tasks/README` · статус **интейк `[x]`** · SPEC ждёт go

## 2026-07-29 — docs: PHASE 1 SPEC Flash Call×2 → SMS
- Обновлён `docs/operations/session/todo.md` (блок под задачу)
- Синхронизированы `SESSION_STATE.md` и `HANDOFF.md` (SPEC стартовал)

## 2026-07-29 — feat(payments): PayType O Init + Charge by RebillId (T-Bank inline step 1)

- `Payments::TbankAdapter#init_payment` получил опциональный `pay_type` и прокидывает `PayType` в payload
- Добавлен `Payments::TbankInlineInit` для шага 1 ТЗ (Init PayType O или Init→Charge при наличии `rebill_id`)
- Тесты: `test/services/payments/tbank_adapter_test.rb`, `test/services/payments/tbank_inline_init_test.rb` (PASS)
- Регрессия зоны оплаты: `test/integration/shop/api/qa_section_2_3_payment_cart_test.rb` + `qa_section_2_3_stage5_e2e_test.rb` + `test/services/shop/order_creator_test.rb`

## 2026-07-28 — fix(shop): bounce inactive last_ordered (Fly Test sticky)

- Root cause: у Арама `last_ordered` = inactive Fly Overnight (7 заказов свежее Point A) → шапка «ул. Fly Test»
- FE: `resolvePreferredTenantId` только active ids; bootstrap всегда уводит с !currentAllowed
- BE: `last_ordered_tenant_id` пропускает inactive
- Тесты: JS preferred 5/0 · history 5/0 · B114 2/0

## 2026-07-28 — ops: MCP Aram phone after Fly v400

- MCP PASS: Point A Ленин + «повторить»; профиль `+79639124847` Подтвержден
- Скрины `03_fly_v400_point_a_…` / `04_fly_v400_profile_phone_…`
- Артефакт `fly_mcp_aram_phone_v400_2026-07-28.json`

## 2026-07-28 — ops: link Aram real phone +79639124847 (no deploy)

- Владелец: настоящий `+7 963 912 4847` (тестовые 900… — не его)
- `CustomerProfileMerger.link_phone!` на `2bc37279-…` + merge donor `e01d7bd4-…`
- AFTER: phone=+79639124847 verified · orders/payments 75 · cards 2 · Point A succeeded 13
- Артефакт `fly_aram_real_phone_link_2026-07-28.json`

## 2026-07-28 — ops: restore Aram phone +79001119877 on Fly

- MCP auth funnel перезаписал профиль Арама тестовым `+79001119932`
- Prod: `MobileCustomer` aramfifa100 → `phone=+79001119877`, `phone_verified=true` (позже заменён на настоящий)
- Артефакт `artifacts/aram_phone_restore/` · ISSUES resolved

## 2026-07-28 — deploy: repeat recommendations restored Fly v399 + MCP PASS

- Push `80e0f3a`; Fly **v399**
- MCP Арам Point A: адрес Ленин, профиль 2bc3…4c, секция «повторить» PASS
- Артефакт `fly_mcp_repeat_restored_2026-07-28.json` + скрин `02_…`

## 2026-07-28 — fix(shop): restore «повторить» + SBP 3001 friendly UX

- Root cause «пропали рекомендации»: залипание на `Fly Overnight` (ул. Fly Test, 0 заказов); на Point A freq=3
- `App.svelte`: Silent Refresh → затем `bootstrapShopTenant` (есть `last_ordered_tenant_id`)
- `resolvePreferredTenantId`: sticky invalid → fallback на last_ordered
- Prod: `Fly Overnight` (`af4f78d6…`) → `inactive` (убран из дропдауна)
- SBP: bank `3001` → понятное сообщение «СБП сейчас недоступна… картой / позже» (BE+FE)
- Тесты: preferred 4/0 · B114 2/0 · SBP initiator+API+JS green

## 2026-07-28 — deploy: auth funnel cascade to Fly v397 + MCP PASS

- Push `develop` → `22d136b`; Fly **v397**
- MCP: flash/messenger/sms send+verify; Rack::Attack `retry_after` 20/30/60
- Checkout wizard Screen1→Screen2 на Fly; артефакт `fly_mcp_auth_funnel_2026-07-28.json`

## 2026-07-28 — feat(shop): auth funnel channel cooldowns + Rack::Attack [GREEN]

- `Shop::PhoneOtp`: cooldowns по каналам `flash_call=20s`, `messenger=30s`, `sms=60s`
- `Rack::Attack`: throttles `/shop/api/phone_otp/send` по `phone+channel`, ответ `429` с channel-specific `Retry-After`
- Попутно исправлен responder/logging `rack.attack` для `Rack::Attack::Request`
- Тесты: Ruby cooldown+throttle 19/0

## 2026-07-28 — feat(shop): auth funnel Messenger + SMS cascade [GREEN]

- Фазы messenger (30с) / sms (60с); кнопки WA/TG и SMS; ошибка messenger → SMS
- `buildOtpSendBody`; `PhoneAuthPinInputs.svelte`
- Backend: `Shop::MessengerClient` + `Shop::PhoneOtp` принимает `channel=messenger`; delivery error возвращает `messenger_delivery_error`
- OTP sms/messenger коды: 4 цифры (совместимость с PIN auto-verify)
- Тесты: Node 22/0 · Ruby wizard 9/0 · Ruby phone_otp messenger 14/0

## 2026-07-28 — feat(shop): auth funnel Flash cascade #1/#2 [GREEN]

- Таймер «Ждем звонок... 00:20»; авто `flash_call` #2; кнопка «Запросить звонок еще раз»
- `phoneAuthCascade.js` + `PhoneAuthCodeStep.svelte` (вынос Экрана 2)
- Тесты: Node 16/0 · Ruby wizard UI 8/0

## 2026-07-28 — feat(shop): auth funnel Screen 2 PIN auto-verify [GREEN]

- 4 PIN-ячейки + авто-сабмит `POST phone_otp/verify` на 4-й цифре
- «Изменить номер» → Экран 1; без кнопки подтверждения кода
- `phoneAuthWizard.js`: `applyPinDigit`, `shouldAutoSubmitPin`, `buildVerifyBody`
- Тесты: Node 10/0 · Ruby wizard+phone_otp 12/0

## 2026-07-28 — feat(shop): auth funnel wizard Screen 1 flash_call [GREEN]

- Intake ТЗ Auth funnel cascade + CBR #29 + artifacts
- `PhoneAuthWizard` Экран 1: маска `+7`, autofocus, «Продолжить» → `POST phone_otp/send` `flash_call` → Экран 2 stub
- Checkout: без Email OTP UI / radio channel; identityReady = phone \| email
- Тесты: Node 5/0 · Ruby 13/0 (wizard UI, cbr_01, cleanup, cart UX, phone_otp)
- ISSUES: checkout_ui_cleanup stale resolved

## 2026-07-27 — deploy: Receipt.Email fix v396; Aram E2E 3001

- Fly **v396**; повтор Aram SBP → банк `3001 СБП недоступна` (терминал)
- Скрины 01–07 обновлены; ISSUES: 329 закрыт кодом, 3001 — кабинет Т-Кассы

## 2026-07-27 — fix(shop): SBP Receipt Email for T-Bank 329 + Aram E2E screenshots

- `SbpPaymentInitiator` передаёт `customer.email` в Receipt 54-ФЗ
- `TbankAdapter` ApiError включает `Details`
- Скрины Aram: `artifacts/codeblack_t_kassa_sbp_tokenization/screenshots/` (01–07)
- ISSUES: SBP 329 на Fly v395

## 2026-07-27 — deploy: CODE:BLACK PWA lifecycle to Fly v395

- Push `develop` → `d4f4369`; Fly **v395**
- MCP: WAITING_FOR_BANK + status + cold start LS — PASS (bank E2E SKIP)
- Артефакт `fly_mcp_pwa_lifecycle_2026-07-27.json`

## 2026-07-27 — feat(shop): CODE:BLACK PWA payment lifecycle [GREEN]

- `codeblack_pending_order` LS (TTL 15м) · visibilitychange / cold start · `checkOrderStatus`
- `GET /shop/api/payments/status/:order_id` · WAITING_FOR_BANK + «Я оплатил»
- Тесты: Node 25/0 · status+UI 23/0 · регрессия §2.3+callback 59/0

## 2026-07-27 — docs: intake CODE:BLACK T-Kassa SBP PWA lifecycle

- ТЗ ревизии + CBR #28 + artifacts `codeblack_t_kassa_sbp_tokenization/`

## 2026-07-27 — deploy: SBP Deep Link epic to Fly v394

- Push `develop` → `6154539` (16 commits эпика)
- Fly `coffeeos` **v394**; MCP artifact `fly_mcp_sbp_epic_2026-07-27.json`

## 2026-07-27 — feat(shop): card mask **** 1234 for 1-tap sheet [GREEN]

- `formatMaskedPan` / `formatCardRowLabel` — маска по ТЗ Шаг 10
- Тесты: Node 17/0 · Ruby step10+repeat 10/0

## 2026-07-27 — test(shop): characterize Recurrent/Charge card tokenization [GREEN]

- `sbp_epic_card_tokenization_char_test.rb` — Шаги 7–8 эпика SBP (без новой прод-логики)
- Fake Tbank stubs: `receipt:` keyword (изоляция с adapter)
- Тесты: 38/0 · Node invalid rebill 14/0

## 2026-07-27 — feat(shop): SBP return polling 60s/2s [GREEN]

- `pollSbpPaymentStatus` — finalize poll 2s×30; timeout/terminal → «Оплата не завершена…»
- `PaymentResult.svelte` — success/ok через shopSbpPay; без infinite Loading
- Тесты: Node 13/0 · return UI 2/0

## 2026-07-27 — feat(shop): SBP UI «Оплатить быстро» deep link [GREEN]

- `shopSbpPay.js` — init `/payments/sbp/init` → redirect `*.nspk.ru`; poll opts 2s×30
- Sheet: SBP enabled + CTA; Checkout: `POST /orders` (sbp) → init → redirect
- OrderCreator: sbp всегда `pending_payment`, без gateway Init (делает initiator)
- Тесты: Node 8/0 · UI+repeat 11/0 · регрессия оплаты 59/0

## 2026-07-27 — feat(shop): SBP payment init Init+GetQr endpoint [GREEN]

- `Shop::SbpPaymentInitiator` — Receipt+Init+GetQr / simulate nspk URL
- `POST /shop/api/payments/sbp/init` → `{ payment_url }`
- Тесты: 10/0 · wave A 19/0 · регрессия tbank+order_creator 56/0
- Runbook `PAYMENT.md` — SBP init

## 2026-07-27 — feat(payments): T-Kassa GetQr PAYMENT_LINK for SBP [GREEN]

- `Payments::TbankQrFetcher` — `/v2/GetQr` → `qr.nspk.ru` deep link
- Тесты: qr+adapter 28/0
- Runbook `PAYMENT.md` — GetQr

## 2026-07-27 — feat(payments): T-Kassa Receipt 54-FZ for Init [GREEN]

- `Payments::TbankReceiptBuilder` — чек Items/Taxation (`TBANK_TAXATION`, `TBANK_TAX`)
- `TbankAdapter#init_payment(receipt:)` — Receipt в Init; Token без nested объектов
- Тесты: 27/0 · регрессия tbank+order_creator 56/0
- Runbook `PAYMENT.md` — ENV чека

## 2026-07-27 — docs: SPEC SBP Deep Link + card tokenization

- `todo.md`: as-is/gap, маппинг `/shop/api` + `/callbacks/tbank`, волны A–D (11 шагов)
- Решения: ReceiptBuilder + QrFetcher + SbpPaymentInitiator; UI `shopSbpPay.js`; poll SBP 60s/2s
- CBR / customer_tasks: статус **SPEC `[x]`**

## 2026-07-27 — docs: intake SBP Deep Link + card tokenization (Т-Касса v2)

- ТЗ: `customer_tasks/Интеграция оплаты СБП Deep Link и токенизации карт Т-Касса v2.md`
- Артефакты: `artifacts/sbp_deep_link_card_tokenization/`
- CBR индекс + customer_tasks README — строка **интейк `[x]`**, SPEC ждёт go

## 2026-07-27 — deploy+MCP: Repeat invalid token payment sheet (Fly v393)

- Push `f0877ac`; Fly **v393**; `/up` 200
- MCP: peek CTA «Добавить карту», PaymentMethodsSheet i18n labels, NewCardForm, selection persist
- Артефакт: `artifacts/repeat_order_invalid_token_payment_sheet/fly_mcp_repeat_invalid_token_2026-07-27.json`

## 2026-07-27 — feat(shop): repeat invalid token payment sheet [GREEN]

- `paymentMethodI18n.js` — подписи «Картой *XXXX», «Картой +», СБП, CTA
- `repeatInvalidTokenStore.js` — invalid RebillId flag, persist selection, open-sheet marker
- `CartSheet`: CTA «Добавить карту» при invalid token в repeat context
- `PaymentMethodsSheet`: inline/load error UI, i18n, SBP unavailable toast
- `Checkout.svelte`: preload cards fail → toast; pay fail → inline + setTokenInvalid
- Тесты: Node 14/0 · Ruby repeat+payment mirror 27/0

## 2026-07-27 — deploy+MCP: Profile Email↔Phone merge (Fly v392)

- Push `9184cde`; Fly **v392** (retry после ConcurrentMigrationError на release; DDL уже применён)
- MCP: profile GET/PATCH/401, UI контакты, checkout autofill, link_* 400
- Артефакт: `artifacts/profile_email_phone_merge/fly_mcp_profile_merge_2026-07-27.json`

## 2026-07-27 — feat(shop): Profile Email↔Phone merge [GREEN]

- DDL: `email_verified` / `phone_verified` на `mobile_customers` (+ backfill)
- `Shop::CustomerProfileMerger` — soft-merge без destroy; освобождение unique contacts
- API: GET/PATCH `/shop/api/profile`, POST `link_email` / `link_phone` (OTP)
- Phone/Email linkers: конфликт → merge (не raise)
- `OrderCreator`: autofill verified contacts из сессионного профиля
- PWA Profile: контакты, verified, OTP-допривязка, toast; Checkout autofill + «Сохранить в профиль»
- Тесты: 47/0 (profile/merge/OTP) · регрессия оплаты/refresh 30/0

## 2026-07-27 — docs: intake+SPEC Profile Email↔Phone merge

- ТЗ: `customer_tasks/Связка профилей Email Phone и управление данными пользователя в PWA.md`
- Артефакты: `artifacts/profile_email_phone_merge/`
- CBR + customer_tasks README; `todo.md` as-is/gap шаги 0–9
- Ключевые gap: нет verified-колонок; `PhoneVerifiedCustomerLinker` запрещает merge; GET profile — другой контракт
- Код не меняли; RED + DDL ждут go

## 2026-07-24 — deploy+MCP: Phone OTP SMS/Flash Call (Fly v390)

- Push `32fe23a`; Fly **v390**; secret `SHOP_OTP_LOG_FALLBACK=true`
- MCP: SMS send/verify + token; cooldown 422; Flash Call verify; checkout UI блок
- Артефакт: `artifacts/phone_otp_sms_flash_call/fly_mcp_phone_otp_2026-07-24.json`

## 2026-07-24 — feat(shop): Phone OTP SMS / Flash Call [GREEN]

- Нормализация `+79…`; `Shop::PhoneOtp` send/verify; SMS.ru + Flash Call клиенты (ENV / log-fallback)
- Cooldown 60с для phone и email OTP; rack_attack `shop/phone_otp`
- Linker phone↔email без silent merge; `refresh_token` через MobileSessionIssuer
- Checkout UI: маска, SMS/Flash Call, timer, LS token
- Тесты: 41/0 (OTP зона) + JS 5/0

## 2026-07-24 — docs: SPEC Phone OTP SMS / Flash Call

- `todo.md`: as-is/gap, шаги 1–8, решения (без DDL, SMS.ru+FlashCall ENV, cooldown email+phone, linker без silent merge)
- Тесты: Minitest + `test/javascript/` (адаптация от RSpec/Vitest в ТЗ)
- CBR / HANDOFF / SESSION_STATE — статус SPEC `[x]`, RED ждёт

## 2026-07-24 — docs: intake Phone OTP SMS / Flash Call

- ТЗ: `customer_tasks/Вход и регистрация по номеру телефона SMS Flash Call.md`
- Артефакты: `artifacts/phone_otp_sms_flash_call/`
- CBR / customer_tasks README — строка индекса; код / SPEC не трогали

## 2026-07-24 — fix+MCP: PWA silent refresh CSRF/API key (Fly v389)

- Hotfix: `silentRefreshSession` шлёт CSRF + `X-Shop-Api-Key` (иначе Fly Auth 401)
- MCP Aram: OTP → refresh_token; rotate 200/401; isolated context restore → профиль Aram
- Артефакт: `artifacts/pwa_durable_sessions_silent_refresh/fly_mcp_aram_silent_refresh_2026-07-24.json`

## 2026-07-24 — feat(shop): PWA durable sessions + Silent Refresh

- Cookie: `_coffeeos_session`, TTL 90 дней, `same_site: :lax`
- OTP verify → `MobileSession` + `refresh_token` в ответе
- `POST /shop/api/session/refresh` — ротация токена, restore customer_id, продление email verification
- Фронт: `shop_refresh_token` без 24h burn; `silentRefreshSession` при старте PWA
- Тесты: 13/0 (suite) + JS PASS; регрессия OTP/guest 18/0

## 2026-07-24 — docs: SPEC PWA durable sessions + Silent Refresh

- `todo.md`: as-is/gap, шаги 1–5, решения (issuer после linker, refresh TTL 90d, убрать 24h LS burn)
- Тесты: Minitest + `test/javascript/` (адаптация от RSpec/Jest в ТЗ)
- CBR / HANDOFF / SESSION_STATE — статус SPEC `[x]`, RED ждёт

## 2026-07-24 — docs: intake PWA durable sessions + Silent Refresh

- ТЗ: `customer_tasks/Долговечные сессии PWA и фикс авто-разлогина.md`
- Артефакты: `artifacts/pwa_durable_sessions_silent_refresh/`
- CBR / customer_tasks README — строка индекса; код не менялся

## 2026-07-24 — docs: intake + анализ статусной модели Т-Банк

- ТЗ: `customer_tasks/Анализ статусной модели платежей и заказов Т-Банк.md`
- Вывод: одностадийная оплата (Init без PayType); заказ `accepted` только на CONFIRMED; webhook + GetState; Cancel/Refund API банка нет.
- Артефакты: `artifacts/payment_status_model_analysis/`.

## 2026-07-24 — fix(shop): peek repeat «+» adds to cart (prog35)

- **Баг:** в peek `+` на карточке «повторить» крутил только локальный qty, позиция не попадала в заказ.
- **Fix:** `repeatEmbeddedCart.js` — embedded `+` → `addToCart`, `−` → `bumpCartLine`; wire в `RepeatSection`; `CART_SHEET_BUILD=prog35`.
- Тесты: `peek_repeat_plus_adds_to_cart_test` + sheet zone 52/0.

## 2026-07-24 — fix(shop): empty cart sheet defaults to peek (prog34)

- Пустая корзина: режим **peek** (не hidden/empty 12vh); высота `empty` = 34 (= peekSingle).
- Без истории — «тут будут твои заказы»; с историей — «повторить» как раньше.
- `CART_SHEET_BUILD=prog34` · tests 23/0.

## 2026-07-24 — ops: MCP Арам — cart sheet fixes prog33 на Fly PASS

- Fly v384 · OTP Aram на Demo Point A.
- PASS: placeholder скрыт при истории; нет глобальной pay/«+ещё»; 3× «оплатить в 1 клик»; undo баннер нет.
- [`fly_mcp_aram_fixes_2026-07-24.json`](../../milestones/veha_2/artifacts/cart_sheet_fixes_mcp_2026-07-24/fly_mcp_aram_fixes_2026-07-24.json) + screenshots/.

## 2026-07-24 — fix(shop): remove global repeat pay and +ещё (prog33)

- Убраны нижние «повторить в 1 клик» и «+ещё» из `RepeatSection.svelte`.
- Остаются карточки с «оплатить в 1 клик». `CART_SHEET_BUILD=prog33`.
- ТЗ: `repeat_remove_global_pay_button/`. Rails test: local PG unavailable — structural assert PASS.

## 2026-07-24 — fix(shop): empty cart placeholder only without order history (prog32)

- «тут будут твои заказы» только при `frequentCount === 0`; при истории — только «повторить».
- `CART_SHEET_BUILD=prog32` · sheet zone 52/0.
- ТЗ: `cart_sheet_empty_orders_placeholder/`.

## 2026-07-24 — fix(shop): remove cart sheet undo «Отменить» button (prog31)

- Убрана полоска «Удаление можно отменить» + кнопка «Отменить» из `CartSheet.svelte` (ТЗ заказчика).
- `CART_SHEET_BUILD=prog31` · sheet zone tests 43/0.
- ТЗ + артефакты: `cart_sheet_remove_undo_button/`.

## 2026-07-23 — ops: MCP UI Арама — PNG в артефактах

- Повторный прогон Demo Point A: OTP → Aram verified → шторка **\*5953 + \*8782** → «повторить» → профиль → заказы сегодня.
- PNG: [`screenshots/aramfifa_mcp_2026-07-23/`](../../milestones/veha_2/artifacts/usercards_save_card/screenshots/aramfifa_mcp_2026-07-23/) (01…07).
- JSON: [`aramfifa_mcp_ui_2026-07-23.json`](../../milestones/veha_2/artifacts/usercards_save_card/aramfifa_mcp_ui_2026-07-23.json).

## 2026-07-23 — ops: MCP UI Арама на Demo Point A

- OTP `aramfifa100@gmail.com` → payment sheet **\*5953 + \*8782**; каталог — **«повторить»** ×3 + «в 1 клик».
- «Заказы за сегодня» пусто (только сегодняшний день). Артефакт [`aramfifa_mcp_ui_2026-07-23.json`](../../milestones/veha_2/artifacts/usercards_save_card/aramfifa_mcp_ui_2026-07-23.json).

## 2026-07-23 — fix(shop): restore guest session after F5 without re-OTP + worker up

- **Worker Fly:** machine `48ee61ea…` started (SolidQueue); restart policy always; после deploy проверять `worker=started`.
- **OTP/F5:** `email_otp/status` при verified email снова вызывает `EmailVerifiedCustomerLinker` (customer_id в сессию).
- `Shop::GuestCustomerResolver` — session или verified email → customer; используют frequent_products и user/cards.
- Фронт: `restoreGuestSession` на CartSheet + Checkout (status → profile emailVerified → refresh frequent).
- Тесты: `guest_session_restore_test` + `guest_customer_resolver_test` · регрессия OTP/cards **26/0**.

## 2026-07-23 — ops: diag Fly — aramfifa UserCards (read-only)

- Prod Neon: `aramfifa100@gmail.com` — **2 карты** (*5953 default, *8782), 53 заказа / 10 succeeded, всё на **Demo Coffee Point A** (`2fdee1ac…`); на Fly Test — 0.
- Worker Fly **stopped** (на момент diag). Артефакт [`aramfifa_full_diag_2026-07-23.json`](../../milestones/veha_2/artifacts/usercards_save_card/aramfifa_full_diag_2026-07-23.json). Код не менялся.

## 2026-07-23 — fix(shop): expanded cart sheet — remove catalog grid (prog30)

- Expanded: убрана сетка `FrequentSheetCategories` (выглядела как «пропал expanded»).
- Остался только список позиций заказа (`shop-cart-expanded-card`) как был.
- `CART_SHEET_BUILD=prog30` · тесты sheet zone 51/0.

## 2026-07-23 — docs(ops): cart sheet gesture hit area — MCP на Fly PASS (prog29)

- Owner deploy `01KY7BWBJW2NQPAY336P1STVJJ` (v380). MCP: зона **80×414** full-strip; свайпы left/center/right → hidden↔peek↔expanded **7/7 PASS**.
- Артефакт [`fly_gesture_hit_area_mcp_2026-07-23.json`](../../milestones/veha_2/artifacts/cart_sheet_gesture_hit_area/fly_gesture_hit_area_mcp_2026-07-23.json) + 6 скринов. До/после: 56px/32px → 80px/20px.

## 2026-07-23 — fix(shop): cart sheet gesture — taller hit-area + sensitive swipe (prog29)

- Полоса свайпа: `min-h-14`→`min-h-20`, `data-gesture-hit-area=full-strip` (весь прямоугольник, не только крючок).
- Порог: `SWIPE_UP_PX` 32→20; `CART_SHEET_BUILD=prog29`.
- ТЗ заказчика + тесты `cart_sheet_gesture_hit_area_test` · регрессия sheet zone 45/0.

## 2026-07-23 — docs(ops): Quick Repeat layout prog28 — MCP на Fly PASS

- Owner deploy `01KY5BN0JKEW31V9GHAKSX6YXF` (v378). MCP DevTools: **6/6 PASS** (guest / empty 46vh full / peek embedded / hidden / repeat→4 chips / checkout без повтора).
- Артефакт [`fly_layout_prog28_mcp_2026-07-23.json`](../../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/fly_layout_prog28_mcp_2026-07-23.json) + 6 скринов `fly_layout_prog28_2026-07-23/`.

## 2026-07-22 — fix(shop): Quick Repeat layout — одна шторка peek, hidden без повтора (prog28)

- **Hidden:** только чипы заказа + «+цена» (скрины 04–05), секции «повторить» нет.
- **Peek/single:** одна сущность — заказ → checkout (+цена) → компактный `RepeatSection layout=embedded` (thumb+qty, скрины 01–02).
- **Empty:** `layout=full` с per-card «оплатить в 1 клик» (скрин 06).
- Высоты: `peekSingleWithRepeat=46` / `peekMultiWithRepeat=50` при `frequentCount>0`; `CART_SHEET_BUILD=prog28`.
- Тесты: layout canon 6 + регрессия quick_repeat 57/0 · sheet/heights/b113 48/0.

## 2026-07-22 — docs(rules): апрув шага = намерение из текста, не культ `go`

- `coffeeos-task-workflow.mdc`: таблица намерений («ебашь/сделай» = работа; «что думаешь» = без кода).
- `spec-build-review.mdc` / agent / commit-ops / RULES_INDEX: SBR — порядок фаз; gate по смыслу; push/deploy по-прежнему явные.

## 2026-07-22 — docs(ops): Quick Repeat FIX-A…F — MCP на Fly PASS после redeploy

- Owner deploy `01KY4MHZPD7YS2D9NS4NP54B09` (v377). MCP DevTools: **9/9 PASS** (OTP→frequent_items без нового заказа, UX-1 34vh, per-card pay, expanded categories, checkout без повтора).
- Артефакт [`fly_fix_af_mcp_2026-07-22.json`](../../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/fly_fix_af_mcp_2026-07-22.json) + 6 скринов; DEMO_FEEDBACK жалоба → done *(MCP PASS)*; чеклист заказчику в JSON.

## 2026-07-22 — fix(shop): Quick Repeat — жалоба заказчика «зарегался — повторов нет» (FIX-A…F)

- **FIX-A:** после `email_otp/verify` — `EmailVerifiedCustomerLinker` привязывает `MobileCustomer` к сессии (`CustomerSession.set_customer_id!`); `frequent_products` видит историю без нового заказа.
- **FIX-B:** нормализация `modifier_options` в `CustomerFrequentProductsService` — `{}` и `{"selected_modifiers":[]}` склеиваются; legacy-плоский jsonb сохранён.
- **FIX-C…F (frontend):** секция «повторить» в ветке 1 товара; empty-шторка растёт до peek-высоты при наличии frequent_items (UX-1); категории в expanded (`FrequentSheetCategories`); «оплатить в 1 клик» под каждой карточкой (скрин 06); секция скрыта на `#/checkout` (UX-3); `refreshFrequentProducts` после OTP verify на Checkout.
- Тесты: FIX-A 2/0 · сервис +1 (нормализация) · `quick_repeat_customer_fixes_test` 6/0 · регрессия quick_repeat 54/0.

## 2026-07-21 — fix(shop): Quick Repeat — фиксы код-ревью (ключ счётчика, честный тост, hot-path rescue)

- Код-ревью диффа фичи (`coffeeos-code-review.mdc`): блокеров нет, 3 замечания → исправлены парой RED (`397dd5c`) / GREEN (`9afdff7`).
- **Ключ счётчика** — был `product_id-индекс` (qty «переезжал» на чужую карточку при смене порядка топ-3 после refresh) → стабильный `product_id:JSON(modifier_options)`; компонент использует общий `frequentCardKey` из store (дубль `keyOf` удалён).
- **Частичное добавление** — `repeatAllToCart` при падении на середине теперь показывает «Добавлено N из M — проверьте корзину» вместо общего «не удалось» (повторный клик давал бы дубли).
- **`bust_cache!`** — rescue + warn-лог внутри сервиса: деградация кэш-хранилища больше не роняет создание заказа/callback оплаты (hot-path), худший случай — устаревший топ-3 до TTL.
- Тесты: 3 файла фиксов 20/0 · остальная фича 29/0 · оплата §2.3 24/0 (2 pre-existing skips) · T-Bank callback 31/0 · svelte compile + compileModule OK · rubocop 0 offenses.

## 2026-07-21 — docs(ops): Quick Repeat — реальный MCP-прогон на Fly без стабов + чеклист заказчику

- Демо-стенд: посеян клиент `mcp-quickrepeat@example.com` с 4 mobile-заказами (Neon, через локальный `pg`: `fly ssh console -C` теряет аргументы команды); вход в витрину штатным email-OTP (код из `shop_email_otp_codes`).
- Реальный E2E 8/8 PASS: гость без секции → OTP-вход → `frequent_products` из реальной истории (сортировка частота/свежесть подтверждена) → счётчики с localStorage → «+ещё» expanded → «повторить в 1 клик» +1 440₽ (qty учтён) → «оплатить в 1 клик» → checkout + guard «Укажите email». Живое списание SKIP (точка закрыта, прод T-Bank).
- Артефакт `fly_real_run_mcp_2026-07-21.json` + 5 скринов + `customer_checklist` (что проверять заказчику); DEMO_FEEDBACK: **UX-3** — секция повтора перекрывает форму email на Оформлении (open, решение владельца).

## 2026-07-21 — feat(shop): Quick Repeat Bottom Sheet — быстрый повтор частых покупок (B1–B4, F1–F5)

- **Backend:** `Shop::CustomerFrequentProductsService` (окно 45 дней, топ-3 по частоте/свежести, группировка `[product_id, modifier_options]`, 4 плоских запроса без JOIN) · кэш `shop/freq/{tenant}/{customer}` TTL 30 мин + bust в `OrderCreator` и `PaymentStatusUpdater` · `GET /shop/api/frequent_products` (гость → пустой список, категории из существующего пути).
- **Frontend:** `shopFrequentCache.js` (localStorage, отдельный ключ счётчиков) · `frequentRepeatStore.js` (init < 50 мс из кэша + фоновый refresh, счётчики −1+ с персистом, `repeatAllToCart`, `repeatMore`, `repeatPayOneClick`) · `RepeatSection.svelte` в шторке (empty/peek/expanded, не hidden) с кнопками «повторить в 1 клик» / «оплатить в 1 клик» / «+ещё» и тостами · `Checkout.svelte` — autopay-флаг открывает шит оплаты (списание — канон one_click с подтверждением).
- **Тесты:** 10 пар RED/GREEN; фича 38 runs (сервис 12 + кэш 6 + API 5 + фронт F1–F5 21) / 0 fail · регрессия: оплата §2.3 + one_click 29/0 (2 pre-existing skips) · services+API+RLS 123/0 · шторка+каталог 27/0 · rubocop 0 offenses.
- **ISSUES 🟡:** pre-existing конфликт `checkout_ui_cleanup_test.rb` с каноном «оплата через шторку» (падает и на чистом HEAD).

## 2026-07-21 — test(shop): закрытие «Bottom sheet expanded grid» — канон зафиксирован тестами

- Владелец принял текущий UX как канон (expanded — 1-й ряд сетки, peek — 2-й ряд, hidden — половина); код приложения не менялся.
- Новый `bottom_sheet_heights_canon_test.rb`: высоты vh + prog26, шторка без grid внутри, каталог 8.5rem. Регрессия cart sheet 59/0.
- ТЗ поправлено владельцем («внутри сетки»); упоминания правок шторки удалены. Deploy — по апруву.

## 2026-07-21 — revert(shop): откат grid 4-в-ряд из expanded-шторки (RESTART задачи)

- Владелец уточнил ТЗ: «сетка 4 в ряд» = каталог на главной, **не** содержимое корзины; expanded-корзина остаётся горизонтальными строками (канон S2).
- Откат `7683dee`+`273a43c`: `CartSheet.svelte`, `cartSheetThresholds.js` (prog26), 5 тестов восстановлены, новый тест удалён. Регрессия cart sheet 56/0.
- Задача в статусе RESTART — новое SPEC после уточнённого ТЗ.

## 2026-07-21 — feat(shop): bottom sheet expanded — сетка товаров 4 в ряд (prog27)

- `CartSheet.svelte` expanded 2+: вертикальный список → `grid-cols-4` с внутренним `overflow-y-auto`; карточки по канону peek (фото → openEditCard, line-clamp-1, цена × кол-во, −/+); «Удалить» из карточек убран («−» при 1 удаляет, undo остаётся) — финальное слово заказчика.
- Высоты expanded 52/56 без изменений (Шаг 1 ТЗ подтверждён скрином заказчика). `CART_SHEET_BUILD` → prog27.
- Тесты: новый `bottom_sheet_expanded_grid_test.rb` (RED `273a43c` → GREEN `7683dee`); регрессия cart sheet 59/0.
- ISSUES 🟡: полный локальный прогон `test/integration/shop/` зависает (env Windows) — таргетные списки как обход.

## 2026-07-21 — docs(rules): customer intake PHASE 0 (доки до SPEC)

- Новое правило `coffeeos-customer-intake.mdc`: текст заказчика 1:1 → `customer_tasks/<Название>.md`, артефакты → `artifacts/<slug>/` (slug латиницей, понятные слова), строка в CBR, коммит intake, стоп до `go` → PHASE 1: SPEC.
- `RULES_INDEX.md` обновлён.

## 2026-07-20 — ops: CHECKPOINT Hidden/cart chips accepted on Fly

- Docs only: `CHECKPOINT.md` + скрин `04_fly_accepted_…` · UI-код отката **`a1abfa0`**.
- ТЗ Hidden: принято положение. Код приложения не меняли.

## 2026-07-20 — feat(shop): catalog cards −15%, sheet heights, hidden image chips

- Каталог: карточки `w-[8.5rem]` (~−15% от w-40).
- Шторка vh: expanded 52/56 · peek 34/38 · hidden 24 (build `prog26`).
- Hidden: ряд миниатюр + «+цена» (канон B1.13-S2 обновлён; не «только сумма»).
- Peek: компактнее, ± крупнее. Тесты B1.13/S2a/layout обновлены.

## 2026-07-20 — fix(fly): release ConcurrentMigrationError on solid migrate

- `fly:release`: skip empty `db:migrate:queue/cable`; named `SolidSchemaConnection` (Rails 8); lock busy + marker table → WARN skip (Neon shared URL).
- Test: `test/lib/fly_release_test.rb`. Runbook: FLY_DEMO_STAND §5.

## 2026-07-20 — fix(shop): CartSheet thumb onerror + demo:catalog_images

- `CartSheet` lineThumb: 404 → placeholder «нет» (не broken-icon); object-top.
- `bin/rails demo:catalog_images` — первые 5 товаров demo-point-a → HTTPS Unsplash (локально и на Fly после деплоя).
- Урок: local MCP с `public/uploads` ≠ Fly; приёмка Hidden должна включать prod assets / HTTPS URL.

## 2026-07-20 — deploy: Fly coffeeos v368 (Hidden crop)

- Push `develop` `7505912` · `fly deploy` → **v368** (retry после ConcurrentMigrationError solid cache).
- Hidden `CategorySection` crop на prod; локальные Unsplash-файлы на Fly **не** уезжают (uploads gitignored).

## 2026-07-20 — ops: Hidden local MCP mobile proof

- 5 Unsplash фото → первые товары demo-point-a (`public/uploads`, gitignored).
- MCP Chrome: viewport `390×844 mobile+touch` · скрин `03_local_mcp_mobile_hidden_crop_2026-07-20.png` · JSON `local_mcp_mobile_2026-07-20.json` — PASS (media 119×158, hasImg×5).

## 2026-07-20 — feat(shop): Hidden catalog cards crop [SBR REVIEW]

- `CategorySection.svelte`: фиксированный media-box (aspect-[4/3]), `object-cover object-top`, placeholder «Нет фото», onerror fallback, truncate имени, `data-catalog-card-mode` от `cartSheetMode`.
- Тесты: `catalog_hidden_card_test` 7/0. CartSheet peek/expanded не меняли.
- SBR: SPEC → RED `986c304` → GREEN `71d6eb6` → REVIEW.

## 2026-07-20 — SBR SPEC: Hidden mode cards (Phase 1)

- Импорт ТЗ в `todo.md` (S1–S4 + edge); SESSION_STATE / HANDOFF — Gate 1.
- Анализ: UI-only, RLS не трогаем; зона shop; peek/expanded вне scope поломки.
- Ждём **go** → PHASE 2 RED.

## 2026-07-20 — docs: ТЗ Hidden mode карточек товаров + скрины

- ТЗ: `customer_tasks/Исправление режима отображения Hidden для карточек товаров.md` (полный текст заказчика).
- Артефакты: `artifacts/product_card_hidden_mode/` — эталон crop + «как сейчас»; README папки и screenshots.
- Индекс: `customer_tasks/README.md` · CBR backlog. Код не меняли.

## 2026-07-18 — ops: UserCards MCP live attempt + скрин 8925 для апрува 3.5

- Fly **v366** verified (fix 3.3 уже на prod).
- MCP PaymentMethodsSheet *5953 + *8782 — скрин `usercards_phase34_live_2026-07-18_payment_sheet_two_cards.png`.
- Живая «Новая карта» 4300*0777 → payment `8878842078` failed (prod test PAN).
- `usercards_fly_payment_investigate_2026-07-18.json` обновлён.

## 2026-07-18 — deploy + ops: UserCards Fly v366, MCP 3.4 две карты в 8925

- Deploy **v366** (3.3 retry GetState + fly_release migration retry 3e9c0c3).
- MCP PaymentMethodsSheet *5953 + *8782; `usercards_phase34_mcp_2026-07-18.json` + screenshot.
- Живая «Новая карта» сегодня NOT_RUN (экономия).

## 2026-07-18 — rules: SBR spec-build-review + todo.md + RED/GREEN substep

- Новый `.cursor/rules/workflow/spec-build-review.mdc` — TDD-цикл SPEC→RED→GREEN→REVIEW.
- `docs/operations/session/todo.md` — живой чеклист (не CHECKLIST вехи).
- `coffeeos-commit-ops` / `coffeeos-task-workflow` — RED-substep (коммит без CHANGELOG/HANDOFF), GREEN + регрессия, TDD-RED ≠ ISSUES.

## 2026-07-18 — fix(payments): UserCards Фаза 3.3 retry GetState для RebillId

- `TbankPaymentSync#sync_for_rebill!` — до 5× GetState с паузой после FA/webhook CONFIRMED без RebillId.
- `NewCardPaymentService`, `TbankCallbackJob`, `orders#finalize` — вызов retry sync.
- Log `[UserCards] missing RebillId payment_id=…` если RebillId так и не пришёл.
- Тесты: `tbank_payment_sync_test`, `shop_usercards_phase1_persist_test` P1 FA retry.

## 2026-07-18 — ops: UserCards Фаза 3.2 root cause платёж 8866531465 (Fly)

- `bin/fly-tools/usercards_fly_payment_root_cause.rb` + [`usercards_fly_payment_root_cause_2026-07-18.json`](milestones/veha_2/artifacts/usercards_save_card/usercards_fly_payment_root_cause_2026-07-18.json).
- FA 09:56 без RebillId; delayed webhook *8782 на следующий день; вердict **наш баг** (нет retry GetState).
- ISSUES/CHECKLIST/HANDOFF/TZ — сняты противоречия «backend resolved» vs 🔴 открыт.

## 2026-07-18 — docs: UserCards runbook привязки карты (Фаза 3.1)

- Runbook [`USERCARDS_SAVE_CARD_FLOW.md`](milestones/veha_2/runbooks/USERCARDS_SAVE_CARD_FLOW.md): цепочка Init→RebillId→список 8925; оплата vs привязка.
- ТЗ § Фаза 3 · runbooks/README · HANDOFF/SESSION_STATE.

## 2026-07-16 — ops: UserCards расследование 2-й оплаты aramfifa (Fly prod)

- `bin/fly-tools/usercards_fly_payment_investigate.rb` + `usercards_fly_payment_investigate_2026-07-16.json`.
- 2× succeeded сегодня: 08:42 *5953 с RebillId; 09:56 save_card=true **без Pan/RebillId** (GetState пустой).
- ISSUES/SESSION_STATE обновлены.

## 2026-07-16 — fix(shop): UserCards Фаза 2 — stacked checkout pay UX

- **Docs:** ISSUES/HANDOFF/SESSION_STATE/TZ — сняты ложные `[x]` по канону UX; Фаза 2 в ТЗ.
- **Код:** `openCheckoutPayStack` / `checkoutPayOpen`; CartSheet peek strip z-52; `PaymentMethodsSheet stacked` без backdrop; `prog25`.
- **Тесты:** `shop_checkout_cart_sheet_ux_test` — 5 runs PASS.
- **MCP Fly / deploy / апрув:** pending.

## 2026-07-16 — ops: UserCards Фаза 1 Fly приёмка (replay 0₽ + MCP)

- Deploy **v362** (заказчик).
- Replay webhook CONFIRMED+RebillId для order `fc18c88e…` — aramfifa **MIR *5953** (без нового списания).
- MCP Fly: корзина 2+3₽, PaymentMethodsSheet «МИР Карта *5953» — PASS.
- Артефакты: `usercards_fly_phase1_verify_2026-07-16.json`, `usercards_phase1_mcp_2026-07-16.json` + 2 PNG.
- **Апрув заказчика:** pending.

## 2026-07-16 — fix(shop): UserCards Фаза 1 — persist RebillId без worker

- **Root cause:** TbankCallbackJob enqueue при stopped worker; GetState finalize без RebillId.
- `TbankController`: `perform_now` webhook (fallback perform_later).
- `fly.toml`: `SOLID_QUEUE_IN_PUMA=true` на web.
- `OrderCreator#init_gateway_payment!`: `recurrent: save_card` + intent provider_data.
- Тесты: `shop_usercards_phase1_persist_test` 3 PASS; callback/sync 22 PASS.
- **Deploy:** не делали — ждать go.

## 2026-07-16 — ops: UserCards Фаза 0 Fly diagnose (read-only)

- `bin/fly-tools/usercards_fly_diagnose.rb` — prod Neon stats via `fly machine exec`.
- Артефакт: `usercards_fly_diagnose_2026-07-16.json`.
- **Факты:** 14 cards global; aramfifa100@gmail.com 0 cards; payment save_card=true 2026-07-15 без row; worker stopped; v361.
- **ISSUES:** 🔴 UserCards bug_13-23.
- **Следующий шаг:** Фаза 1 fix persist.

## 2026-07-16 — ops: MCP Fly checkout UX (peek, без inline pay)

- Fly `#/checkout` 390×844: peek 2 позиции · нет «Способ оплаты»/«Оплатить →».
- `+5₽` → валидация email, не форма карты сразу.
- Бандл `application-D1E05YN_.js`: `shop:checkout-pay`, `prog24`.
- Артефакт: `usercards_checkout_mcp_2026-07-16.json` + 2 скрина.
- **Апрув заказчика:** pending.

## 2026-07-16 — fix(shop): checkout UX — канон заказчика (peek + оплата из шторки)

- **ТЗ UserCards:** § **Канон UX checkout** — скрины заказчика > B1.13 «только каталог» > ops resolved.
- **Код:** `onCartSheetRouteChange` → `ensureCheckoutCartPeek` на `#/checkout`; убран inline «Оплатить →» / «Способ оплаты» из Checkout; `openPaymentSheet` + hint; `CART_SHEET_BUILD=prog24`.
- **ISSUES:** 🔴 reopen checkout sheet; ложная resolved 2026-07-15 → superseded.
- **Тест:** `shop_checkout_cart_sheet_ux_test` — refute «Оплатить →», assert peek canon.
- **Deploy:** не делали — ждать go.

## 2026-07-15 — ops: push+deploy Fly v359 (шторка checkout + UserCards)

- Причина «нет шторки на Fly»: local `develop` was **ahead 4**, прод **v358** без peek/UserCards review.
- Push `511d79c..671ba86`; deploy image `deployment-01KXK3MZJS8KQWW29R6SPV6J7V` → **v359**.
- Smoke `/up` `/shop` 200; бандл: `shop:checkout-pay`, peek testid, Checkout `pb-[32vh]` + `payments/new_card`.

## 2026-07-15 — fix(shop): UserCards review БАГ-1/2/3 (save_card gate + 3DS list)

- `SavedCardStore.allowed_for?` + intent `provider_data["save_card"]` (NewCardPaymentService).
- Webhook / GetState не пишут карту при `save_card=false` (Шаг 6).
- Checkout: `loadSavedCardsWithRetry` после 3DS; тумблер OFF только если список пуст.
- Brand: last4-only без CardType → `CARD` (не MASTERCARD).
- Тесты: S6-webhook + `shop_usercards_review_fixes` + step1–6 — **50 PASS**.

## 2026-07-15 — fix(shop): шторка+заказ на checkout по эталону заказчика

- `ensureCheckoutCartPeek` + `requestCheckoutPay` / `CHECKOUT_PAY_EVENT`.
- CartSheet на checkout открывает оплату (не повторный `push /checkout`).
- Checkout: нижний pad `pb-[32vh]`; ISSUES 🔴 resolved (код).
- Тест: `shop_checkout_cart_sheet_ux_test` + B1.13 S2/S2b/S3 PASS.
- **Deploy не делали** — ждать явный go.

## 2026-07-15 — fix(shop): снят B1.13 catalog-only gate для CartSheet на checkout

- `isCartSheetRoute`: каталог + `#/checkout` (эталон UserCards / шторка с заказами).
- PaymentMethodsSheet z-index выше CartSheet.
- Тесты B1.13-S2/S2b обновлены. **Стоп** до `go` на полный UX-restore.
- ISSUES 🔴 in_progress.

## 2026-07-15 — docs: скрины UserCards save_card → artifacts

- Папка `artifacts/usercards_save_card/screenshots/` (макеты 8924/8925 + баг 13:19/13:23).
- Ссылки из ТЗ customer_tasks. Дубликатов вне папки не найдено.

## 2026-07-15 — feat(shop): Pay FSM 0–7 + 3DS overlay (Client Error)

- `shopPayFsm.js` + `CheckoutPayButton` + `ThreeDsOverlay` + settle poll.
- Checkout/sheet: Connecting→Processing→3DS→Success; close 3DS → «Отказ: смените карту»; Net Error State 7.
- Тесты: `shop_pay_fsm_3ds_test` + extremes **30 runs PASS**. Vite PASS.
- Deploy Fly `25b1c6a` OK; MCP sheet/NewCard/FSM Default verified; bundle has Client/Net/3DS labels.

## 2026-07-15 — feat(shop): UserCards extremes (webhook upsert, soft DB fail, Net Error)

- `TbankCallbackJob`: CONFIRMED+RebillId → `SavedCardStore` (soft-fail).
- `NewCardPaymentService`: persist failure не валит Success.
- Checkout: нет `saved_card` → тумблер OFF; `isOfflineError` → «Нет сети: повторить».
- Тест: `shop_user_cards_extremes_test` **7 PASS**; step6+callback **21 PASS**.
- Deploy Fly `29fbe63` OK; MCP browser n/a → HTTP/asset smoke.
- Backlog: UI Client Error / 3DS overlay FSM без go.

## 2026-07-15 — test(shop): Шаг 6 — save_card=false не пишет UserCards

- Тест: `shop_save_card_false_step6_test` — CONFIRMED без записи; Init `recurrent:false`; GET без новой карты.
- Checkout/toggle уже передавали `save_card`; комментарий в `NewCardPaymentService`.
- Gherkin S1–S6 `[x]`. Регрессия step1–6 + CBR: **47 runs, 0 fail**. Vite PASS.

## 2026-07-15 — feat(shop): Шаг 5 — вторая карта (RSA new_card, без дублей)

- Checkout: «Новая карта» → `card_config` + `encryptCardPayload` → `POST payments/new_card` + reload list.
- `SavedCardStore`: upsert по rebill и pan+exp (без дублей); новые сверху.
- Тесты step1–5 + CBR: **44 runs, 0 fail**. Vite PASS. Дальше: Шаг 6.

## 2026-07-15 — feat(shop): Шаг 4 — оплата в 1 клик (Init→Charge)

- `TbankAdapter#charge` + `charge_recurrent`.
- `OneClickPaymentService` + `RecurrentOrderCreator` + `POST /shop/api/payments/one_click`.
- Checkout: saved card → `{ card_id }` one_click; NewCardForm только на пути new_card.
- Тесты step1–4 + adapter + CBR: **60 runs, 0 fail**. Vite PASS. Дальше: Шаг 5.

## 2026-07-14 — feat(shop): Шаг 3 — список сохранённых карт (1000008925)

- API: `GET /shop/api/user/cards` (+ filter expired by exp_date).
- UI: `PaymentMethodsSheet.svelte` + `paymentMethodLabels.js` («МИР Карта *XXXX»).
- Checkout: открывает sheet, грузит cards, «Новая карта» → NewCardForm, Pay при выборе.
- Тесты step1–3 + CBR: **35 runs, 0 fail**. Vite build PASS. Дальше: Шаг 4 Charge.

## 2026-07-14 — feat(shop): Шаг 2 — Init→FinishAuthorize→UserCards (save_card)

- `TbankAdapter#finish_authorize` → `/FinishAuthorize` с CardData.
- `SavedCardStore` + `MobilePaymentMethod` → `mobile_payment_methods` (*5953, 09/27, MIR).
- `NewCardPaymentService` + `POST /shop/api/payments/new_card` + `GET …/card_config`.
- Frontend RSA: `tbankCardFormat.js` + `tbankCardEncrypt.js` (jsencrypt).
- Тесты step2+adapter+sync+step1: **39 runs, 0 fail**. Vite build PASS.
- Checkout UI wiring / список карт — Шаг 3.

## 2026-07-14 — feat(shop): Шаг 1 — форма новой карты (маска, Луна, save_card)

- Lib: `app/frontend/lib/shopNewCardForm.js` — PAN маска/Luhn, ММ/ГГ автослэш, CVV, `save_card: true`, `isPayEnabled`, `formNetworkSnapshot` без открытого PAN/CVV.
- UI: `app/frontend/components/NewCardForm.svelte` (макет 1000008924).
- Тест: `shop_new_card_form_step1_test.rb` — **12 runs, 99 assertions, 0 fail** (Node ESM unit + File.read UI).
- Vite build PASS. ТЗ Шаг 1 `[x]`. Дальше: Шаг 2 по `go`.

## 2026-07-14 — test(wipe): регрессия после сноса — PASS

- Boot не зависал: `initialize` ~26 с (локально медленно, не hang).
- `tbank_adapter` + `tbank_payment_sync` + checkout UI/CBR + `tbank_controller`: **44 runs, 0 failures**.
- `order_creator` + `test/integration/shop/api/`: **105 runs, 0 failures, 3 skips**.

## 2026-07-14 — chore(wipe): снос старой реализации сохранения карты / checkout card UX

- Удалены старые ТЗ, артефакты, dedicated код/тесты/роуты по теме.
- Checkout: базовый OTP + redirect на банк (payment_url).
- Канон для новой работы: customer_tasks/Исправление сохранения карты в UserCards после успешной оплаты.md.
- Дальше: только реализация по новому ТЗ после go (не восстанавливать снесённое из git).

## 2026-07-13 — fix(b1.13): pin cart sheet to bottom (no float gap)

- `CART_SHEET_BOTTOM_REM` 3.5 → **0** (бар навигации уже убран; 3.5rem давал «воздух»).
- Build marker `prog21`. Тест S2a 10 PASS.
- DEMO_FEEDBACK + B1_13: жалоба заказчика закрыта в коде (deploy ждёт go).


- Тесты: settle unit 2 PASS · sheet **29 PASS**.


- Compact thumbs (h-16) — методы не уезжают за Pay.
- Тесты sheet **28 PASS**. MCP layout PASS; multi-card s07 runtime без saved cards.


- `formatCardMethodLabel` → «Картой *XXXX».
- Тесты: sheet real_b112 **24 PASS**.
- MCP Fly v346 verified email → expanded: layout PASS; *XXXX/Pay active — нет saved cards.


- Deploy: `fly deploy -a coffeeos --remote-only --depot=false` → **v344** · `/up` 200.
- s01 ≥3 thumbs + OTP кликабелен + footer disabled; s02 1 full card; s03 2 full cards (не thumbs).


- MCP: `cursor-ide-browser` на Fly v341 vs s01–s07.
- Следующий: **`go` deploy** (фиксы уже в develop) → повтор MCP.


- Следующий: **апрув → `go` deploy** (без go не деплоить).


- СБП / оплатить: rounded-2xl, py-2.5; disabled через цвет, не opacity.


- Cart JSON: `description`; Checkout: padding-bottom под sheet.






- Лимит 10: `assertCanAddCard`; fake «Удалить карту» убрана (нет API).
- Регрессия: `test/integration/shop/` — **293 runs, 0 failures, 3 skips**.
- Следующий шаг: deploy (`go`) → живая оплата заказчиком.


- В ТЗ отмечены все сценарии реализации и экстремалы.
- Следующий шаг: `/review` после апрува.


- Отчёт Было/Стало + таблица статуса в customer_tasks (галочки Gherkin ждут апрува).
- Следующий шаг: `/review` после апрува.


- `bin/rails test test/integration/shop/` — **304 runs, 2019 assertions, 0 failures, 0 errors, 3 skips**.


- `Checkout.svelte`: mount sheet + `onPay={handlePayFromSheet}`


- Прогон: **23 runs, 23 failures** (красная зона). Код UI не меняли.


- Код UI не меняли.


- **Git:** `rebase --onto` — вырезан сплошной блок старых checkout-sheet коммитов; `develop` force-push (`9db1406`).
- **Deploy:** Fly `coffeeos` **v340** · image `deployment-01KX66W1GSN3SP6N4SDG1QY345` · `/up` **200**.
- **Не опираться** на старые sheet-коммиты в reflog — NON-CANON.




- Код не трогали — только подготовка.


- `cartSheetStore`: bump catch → refresh + `cartSheetError`.




- ТЗ: закрыты критерии S1+S2; статус-таблица, Было/Стало, список недоделок (S3–S7).
- Волна: `a1c9aa3` (код) · `5188b74` (suite 313 PASS).


- Регрессия: `bin/rails test test/integration/shop/` — **313 runs, 0 failures**.
- `b113_s4_cart_modifiers_test.rb`: копирайт кнопки «добавить к заказу».


- Тесты S1+S2 PASS; b113_s4_b2 — копирайт кнопки обновлён под ТЗ.


- Код UI не менялся; прогон: 4 failures (красная зона).


- Новый: `test/integration/shop/product_card_s1_in_order_indicator_test.rb` — Gherkin Сценария 1 (DOM testid + qty из cartItems + реактивность).
- Код `Product.svelte` не менялся; прогон: 4 failures (красная зона).



## 2026-07-09 — fix(b1.13): сумма только внутри кнопки checkout

- `CartSheet.svelte`: убран дубль цены рядом с кнопкой в `checkoutBar`; `+X₽` только внутри `shop-cart-sheet-checkout`.
- Тесты: `cart_checkout_button_total_dynamic_test.rb` + b113_s2* — PASS.

## 2026-07-08 — feat(b1.13): openEditCard from cart expanded image

- **Код:** `CartSheet.svelte` — отдельный кликабельный target картинки в `MODE_EXPANDED` (`data-testid="shop-cart-expanded-product-image"`) → `openEditCard`.
- **Store:** `cartSheetStore.js` — добавлен экспорт `openEditCard(line)` для перехода с query `cart_line`.
- **Тест:** `cart_expanded_image_open_edit_card_test.rb` — PASS.
- **Коммит:** `ae0fd0e`

## 2026-07-07 — deploy(b1.13): CR-BOTTOM-NAV on Fly

## 2026-07-08 — feat(b1.13): dynamic +X₽ label on cart checkout button

- `CartSheet.svelte`: checkout button now renders `+X₽` from `cartTotal`, with `disabled` when total is `0` (+ removed `Оформить`/`+цена`).
- `cartSheetStore.js`: added `cartUndoLine` / `cartSheetError` and `undoRemoveCartLine()`; `refreshCartSheet()` sets error message on API failures.

## 2026-07-08 — feat(b1.13): cart button overflow + unavailable cart UX

- `CartSheet.svelte`: auto font shrinking helper `checkoutButtonFontSizePx(total)` для больших сумм.
- `cartSheetStore.js`: при ошибке `Товар недоступен` корзина очищается (не используется кэш) и `shop-cart-error` показывает нормализованное сообщение.
- **Коммит:** `ff0a42c`

- **Push:** `develop` → `4e1d923`
- **Fly:** `coffeeos` · image `deployment-01KWXSGYSBZDNGSC6ABJAATFX6` · https://coffeeos.fly.dev
- **Проверка:** shop 200 · `application-*.js` без BottomNav/Каталог/Избранное

## 2026-07-07 — docs(b1.13): O2 gate closed CR-BOTTOM-NAV

- Gate closed; код ждёт `go` владельца.

## 2026-07-07 — docs(b1.13): O1 O3 answers CR-BOTTOM-NAV

- **O1:** «Да» — свайп подтверждён.
- **O3:** «Да, удаляем» — `#/favorites` удаляем.

## 2026-07-07 — docs(b1.13): ответы заказчика CR-BOTTOM-NAV rev3

- КАРТА ФАЙЛА в B1_13 (стр. ~14) — куда смотреть без листания 1300 строк.
- JSON: `b113_cr_bottom_nav_answers_2026-07-07.json`.

## 2026-07-06 — docs(b1.13): B1.13-CR-BOTTOM-NAV customer bug report

- **Заказчик:** убрать «Каталог» и «Избранное» из нижнего бара.
- **Конфликт:** канон S1-R1 = ровно 2 вкладки (апрув 2026-07-01); код соответствует.
- **Docs:** § B1.13-CR-BOTTOM-NAV · JSON · DEMO_FEEDBACK · CHECKLIST.
- **Код:** не трогали — ждём ответы + `go`.

## 2026-07-05 — ops: batch апрув задач трекера «проверено»

- **Закрыто апрувом:** B1.4 PWA · B2-S1 звук · B1.11 (+ overnight) · B1.14 client · B1.13-S1.
- **ISSUES:** B1.11-BUG-OVERNIGHT → resolved.
- **Артефакты:** `customer_verified_batch_2026-07-05.json` + 5 `*_customer_approval_2026-07-05.json`.

## 2026-07-05 — ops(b1.11): Fly post-deploy MCP — overnight shift PASS

- **Fly MCP Chrome DevTools:** `coffeeos.fly.dev` · login УК → create пн 09:23–01:24 → «Точка создана».
- Tenant `af4f78d6-c66b-428e-8ee4-5a609c5c9131` · edit: opens/closes сохранены.
- **Артефакт:** `b111_bug_overnight_fly_post_deploy_2026-07-05.json` · 3 скрина Fly.
- **A1:** deploy `[x]` · апрув заказчика pending.

## 2026-07-05 — fix(b1.11): B1.11-BUG-OVERNIGHT ночная смена · MCP PASS

- **F1–F4:** `TenantWeekdaySchedule#overnight?` · `opens_and_closes_distinct` (убран `closes_after_opens`) · `TenantOperatingHours` overnight `open_now?` · тесты 36 runs PASS.
- **MCP Chrome DevTools:** УК `/admin/tenants/new` · пн 09:23–01:24 → «Точка создана» · DB `overnight: true`.
- **Артефакты:** `b111_bug_overnight_mcp_2026-07-05.json` · 3 скрина в `screenshots/`.
- **A1 pending:** deploy Fly + апрув заказчика.

## 2026-07-04 — docs(b1.11): B1.11-BUG-OVERNIGHT канон · ночная смена в scope

- Баг заказчика: УК create точки, пн `09:23`–`01:24` → `must be after opens_at`.
- **Канон:** ночная смена **в scope**; старый Q2/R2-2 «полночь не MVP» — **архив**.
- Статус B1.11 везде выровнен: код MVP `[x]`, не «готовность к коду».
- Текст бага + root cause + чеклист F1–A1 в `B1_11_tenant_operating_hours.md`.
- ISSUES 🔴 · DEMO_FEEDBACK · CBR · CHECKLIST · README · SESSION_STATE · HANDOFF.
- Артефакт: `b111_bug_overnight_customer_2026-07-04.json`.
- **Код не трогали** — стоп до `go` на F1–F4.



**MCP browser flow (Puppeteer + Neon psql OTP):**
- Каталог → добавить товар → checkout → email OTP через Neon psql `[x]`
- Карта `4300 0000 0000 0777` / 12/26 / 111 заполнена `[x]`
- `POST /shop/api/payments/new_card` дошёл до T-Bank (2044ms, 35 queries) `[x]`
- T-Bank вернул **CLIENT_ERROR** (sandbox ограничение, не наш код)



**A1 статус:** фикс задеплоен · unit tests PASS · MCP браузерный flow PASS · нужен CONFIRMED от заказчика.



**Фикс:** `new_card_payment_service.rb` `settle_confirmed!`:
- если пусто → `TbankPaymentSync.sync_order!(order:)` (GetState → `persist_card_if_needed!`)

7 runs 41 assertions 0 failures · регрессия 14 runs 70 assertions 0 failures.

**Дальше:** деплой на стенд → A1 апрув заказчика.




- Чеклист работ D1–A1; ISSUES 🔴 open.
- Код не трогали.


- **Канон:** rev2 код R1–R3 `[x]` · Q-R2 `[x]` · открыто только приёмка «карта не сохраняется».
- **Не трогали:** код app/, баг-фикс карты.

## 2026-07-03 — docs: V2-SEC-08 bundler-audit (обязательный техдолг)

- **PRACTICES.md:** строка V2-SEC-08 + § с приоритетом rails 8.1.2.1, puma, nokogiri и порядком шага.
- **HANDOFF / SESSION_STATE:** ссылка на V2-SEC-08 как обязательный backlog до deploy.

## 2026-07-03 — Security hygiene: permit! + gem CVEs (rack, view_component)

- **Код:** `Platform::TenantsController#weekday_schedule_params` — явный permit `"0".."6"` → `enabled/opens_at/closes_at` вместо `permit!`.
- **Тест:** `tenants_controller_test.rb` — кейс «unpermitted keys ignored»; 5 runs controller + 3 sync — PASS.
- **Гемы:** `rack` 3.2.5→3.2.6, `rack-session` 2.1.1→2.1.2, `view_component` 3.24.0→3.25.0.
- **Регрессия:** shop integration 249 runs PASS; `b114_tenant_map_test` PASS.
- **Backlog:** bundler-audit остаток → **V2-SEC-08** в `PRACTICES.md` (обязательно).

## 2026-07-03 — Sentry triage + fix RUBY-9 (manager orders show)

- **Sentry (9 issues):** Neon compute quota exceeded (RUBY-Q/M/N/K/P/R) — инфра, квота оплачена; smoke/pg_stat_statements (RUBY-T/S/D) — шум деплоя.
- **Код:** `Manager::OrdersController#show` — убран `includes(:product)` (OrderItem без `belongs_to :product`).
- **Тест:** `manager_orders_show_test.rb` — 1 run, 6 assertions, PASS.
- **ISSUES.md:** запись RUBY-9 resolved + список Archive в Sentry.

## 2026-07-02 — B1.13 S4 MCP browser: финальная браузерная приёмка

- `fly deploy coffeeos` + `git push develop` → `2a34ada` на Fly.
- MCP Puppeteer 12/12 checks PASS: role=button, tap→`#/product/:id?cart_line=N`, editMode кнопка «Сохранить», qty prefilled, dots 4+, S2 gesture zone.
- Артефакт: `b113_s4_post_deploy_2026-07-02.json` обновлён — mcp_browser_checks добавлены.

## 2026-07-02 — B1.13 S4 блок 4: итоговая приёмка

- `b113_s4_cart_modifiers_test.rb`: 24 runs, 92 assertions — tap+edit+dots+price.
- Регрессия B1.13 S2+S3+S4: **114 runs, 695 assertions, 0 failures**.
- Коммиты: `6121f90`, `c059fe4`


- Показываются только при `count >= 4`; `aria-hidden="true"`.
- Тест: 12 runs зелёных; регрессия OK.
- Коммит: `044f460`

## 2026-07-02 — B1.13 S4 блок 2: edit mode Product + CartService replace_line

- `CartService#replace_line!`: замена модификаторов строки, слияние при одинаковой сигнатуре.
- `CartController#update`: ветка `selected_modifiers` → `replace_line!`; delta-ветка без изменений.
- `Product.svelte`: parseCartLine(), editMode, initSelectedFromCartLine(), PATCH в edit, кнопка «Сохранить», возврат на `/` с восстановлением режима поп-апа.
- Тесты: 6 + 15 runs зелёные; регрессия CartService OK.
- Коммит: `e87faeb`

## 2026-07-02 — B1.13 S4 блок 1: tapToProduct в CartSheet

- Кнопки ± не тапают в Product (`e.target.closest("button")`); gestureZone без изменений.
- Тест: `b113_s4_tap_to_product_test.rb` 16 runs зелёных; регрессия S2/S3 9 runs OK.
- Коммит: `8ac3f0b`

## 2026-07-01 — B1.13 docs: S4 rev0b — уточнения владельца

- § S4-канон: edit только через Product (в поп-апе ±qty); зона tap — вся карточка кроме ±; слияние строк; PATCH `selected_modifiers`.
- JSON baseline S4, stage0 `s4_resolved`, README макетов, FLUTTER_API.
- Коммит: `fe20065`

## 2026-07-01 — B1.13 docs: S4 — API gap + индексы CBR/README

- § S4-канон: поток 1+ позиция · таблица API (PATCH сейчас только delta).
- HANDOFF, CBR, README — статус rev2 закрыт · S4 docs `[x]`.
- stage0 JSON: open question S4-block-2 (modifier update API).
- Коммит: `efb69c3`

## 2026-07-01 — B1.13 docs: канон S4 (tap → Product, без long press)

- JSON baseline S4, README макетов, stage0 — выровнены.
- Коммит: `2c940e8`

## 2026-07-01 — B1.13 docs: уточнения канона S2 (без кода)

- **S2a/S2b/S4:** выровнены corner cases, use case, чеклисты; исправлен мусор в S4 checklist.
- **README** макетов S2 — краткая отсылка к уточнениям.
- Коммит: `62dfc3e`

## 2026-07-01 — B1.13 S1-R1: апрув (rev2 полностью закрыт)

- **S1-R1:** 2 вкладки bottom bar, без «Корзина»/«Профиль» — сверка кода + апрув владельца.
- **Q-rev2:** отложено — плейсхолдер пустой корзины до ответа заказчика.
- **Следующий шаг:** **`go` S4**.

## 2026-07-01 — B1.13 rev2 ЗАКРЫТ — апрув заказчика (телефон)

- **Апрув:** S2a + S2b + S3-rev2 + раскладки prog20 — владелец подтвердил на телефоне.
- **MCP:** 22/22 PASS · build=prog20.
- **CHECKLIST:** B1.13 rev2 `[x]` · S4 — следующий шаг.
- Коммит: `1e9c90b`

## 2026-07-01 — B1.13 docs: канон prog20 — убраны хвосты противоречий

- **B1_13 § S2-канон:** build prog20, примечание про исторические testid; MCP-артефакт 2026-07-01 — эталон приёмки.
- **JSON baseline S2/S4:** раскладки и scroll-режимы выровнены с prog20.
- **MCP 2026-06-30:** помечен `SUPERSEDED` → `b113_s2a_s2b_rev2_post_deploy_2026-07-01.json`.
- **HANDOFF / SESSION_STATE:** единая строка S2-канон prog20, без ссылок на prog19 как «текущий код».
- Коммит: `9c147b5`


- **Fly MCP:** 21/21 PASS · build=prog20 · S2b-03: expanded layout=vertical, has_delete=true.
- **Deploy:** `deployment-01KWEC4BRDSEK248M67X13NVKD` · `application-DwJhUPfQ.js`
- Коммит: `66c4352`

## 2026-07-01 — B1.13 prog19: push + Fly deploy


- **Push:** `develop` → `origin/develop` (13 commits, tip `283d12f`).
- **Fly:** `coffeeos` · image `deployment-01KWEABJGANTFHS49XY11EKFBX` · release_command OK · rolling 2/2 ✓
- **MCP:** после апрува владельца (`node bin/acceptance/b113_s2a_s2b_rev2_mcp.mjs`).

## 2026-07-01 — B1.13 prog19: код CartSheet по § S2-канон

> **История (не канон):** описание раскладок ниже отражало промежуточный prog19; **текущий канон — prog20** (§ B1.13-S2-канон).

- **EXPANDED 2+:** горизонтальный ряд карточек 28vw (`shop-cart-expanded-horizontal`, `horizontal`).
- **MCP:** `b113_s2a_s2b_rev2_mcp.mjs` — layout assertions по канону.
- **Тесты:** b113_s2* — 36 runs, 0 failures.
- `CART_SHEET_BUILD=prog19`
- Коммит: `d136f16`

