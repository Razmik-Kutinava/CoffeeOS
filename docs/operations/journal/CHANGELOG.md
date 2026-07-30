# CHANGELOG

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
- [`fly_mcp_aram_fixes_2026-07-24.json`](../milestones/veha_2/artifacts/cart_sheet_fixes_mcp_2026-07-24/fly_mcp_aram_fixes_2026-07-24.json) + screenshots/.

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
- PNG: [`screenshots/aramfifa_mcp_2026-07-23/`](../milestones/veha_2/artifacts/usercards_save_card/screenshots/aramfifa_mcp_2026-07-23/) (01…07).
- JSON: [`aramfifa_mcp_ui_2026-07-23.json`](../milestones/veha_2/artifacts/usercards_save_card/aramfifa_mcp_ui_2026-07-23.json).

## 2026-07-23 — ops: MCP UI Арама на Demo Point A

- OTP `aramfifa100@gmail.com` → payment sheet **\*5953 + \*8782**; каталог — **«повторить»** ×3 + «в 1 клик».
- «Заказы за сегодня» пусто (только сегодняшний день). Артефакт [`aramfifa_mcp_ui_2026-07-23.json`](../milestones/veha_2/artifacts/usercards_save_card/aramfifa_mcp_ui_2026-07-23.json).

## 2026-07-23 — fix(shop): restore guest session after F5 without re-OTP + worker up

- **Worker Fly:** machine `48ee61ea…` started (SolidQueue); restart policy always; после deploy проверять `worker=started`.
- **OTP/F5:** `email_otp/status` при verified email снова вызывает `EmailVerifiedCustomerLinker` (customer_id в сессию).
- `Shop::GuestCustomerResolver` — session или verified email → customer; используют frequent_products и user/cards.
- Фронт: `restoreGuestSession` на CartSheet + Checkout (status → profile emailVerified → refresh frequent).
- Тесты: `guest_session_restore_test` + `guest_customer_resolver_test` · регрессия OTP/cards **26/0**.

## 2026-07-23 — ops: diag Fly — aramfifa UserCards (read-only)

- Prod Neon: `aramfifa100@gmail.com` — **2 карты** (*5953 default, *8782), 53 заказа / 10 succeeded, всё на **Demo Coffee Point A** (`2fdee1ac…`); на Fly Test — 0.
- Worker Fly **stopped** (на момент diag). Артефакт [`aramfifa_full_diag_2026-07-23.json`](../milestones/veha_2/artifacts/usercards_save_card/aramfifa_full_diag_2026-07-23.json). Код не менялся.

## 2026-07-23 — fix(shop): expanded cart sheet — remove catalog grid (prog30)

- Expanded: убрана сетка `FrequentSheetCategories` (выглядела как «пропал expanded»).
- Остался только список позиций заказа (`shop-cart-expanded-card`) как был.
- `CART_SHEET_BUILD=prog30` · тесты sheet zone 51/0.

## 2026-07-23 — docs(ops): cart sheet gesture hit area — MCP на Fly PASS (prog29)

- Owner deploy `01KY7BWBJW2NQPAY336P1STVJJ` (v380). MCP: зона **80×414** full-strip; свайпы left/center/right → hidden↔peek↔expanded **7/7 PASS**.
- Артефакт [`fly_gesture_hit_area_mcp_2026-07-23.json`](../milestones/veha_2/artifacts/cart_sheet_gesture_hit_area/fly_gesture_hit_area_mcp_2026-07-23.json) + 6 скринов. До/после: 56px/32px → 80px/20px.

## 2026-07-23 — fix(shop): cart sheet gesture — taller hit-area + sensitive swipe (prog29)

- Полоса свайпа: `min-h-14`→`min-h-20`, `data-gesture-hit-area=full-strip` (весь прямоугольник, не только крючок).
- Порог: `SWIPE_UP_PX` 32→20; `CART_SHEET_BUILD=prog29`.
- ТЗ заказчика + тесты `cart_sheet_gesture_hit_area_test` · регрессия sheet zone 45/0.

## 2026-07-23 — docs(ops): Quick Repeat layout prog28 — MCP на Fly PASS

- Owner deploy `01KY5BN0JKEW31V9GHAKSX6YXF` (v378). MCP DevTools: **6/6 PASS** (guest / empty 46vh full / peek embedded / hidden / repeat→4 chips / checkout без повтора).
- Артефакт [`fly_layout_prog28_mcp_2026-07-23.json`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/fly_layout_prog28_mcp_2026-07-23.json) + 6 скринов `fly_layout_prog28_2026-07-23/`.

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
- Артефакт [`fly_fix_af_mcp_2026-07-22.json`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/fly_fix_af_mcp_2026-07-22.json) + 6 скринов; DEMO_FEEDBACK жалоба → done *(MCP PASS)*; чеклист заказчику в JSON.

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

- `bin/usercards_fly_payment_root_cause.rb` + [`usercards_fly_payment_root_cause_2026-07-18.json`](milestones/veha_2/artifacts/usercards_save_card/usercards_fly_payment_root_cause_2026-07-18.json).
- FA 09:56 без RebillId; delayed webhook *8782 на следующий день; вердict **наш баг** (нет retry GetState).
- ISSUES/CHECKLIST/HANDOFF/TZ — сняты противоречия «backend resolved» vs 🔴 открыт.

## 2026-07-18 — docs: UserCards runbook привязки карты (Фаза 3.1)

- Runbook [`USERCARDS_SAVE_CARD_FLOW.md`](milestones/veha_2/runbooks/USERCARDS_SAVE_CARD_FLOW.md): цепочка Init→RebillId→список 8925; оплата vs привязка.
- ТЗ § Фаза 3 · runbooks/README · HANDOFF/SESSION_STATE.

## 2026-07-16 — ops: UserCards расследование 2-й оплаты aramfifa (Fly prod)

- `bin/usercards_fly_payment_investigate.rb` + `usercards_fly_payment_investigate_2026-07-16.json`.
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

- `bin/usercards_fly_diagnose.rb` — prod Neon stats via `fly machine exec`.
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
- **MCP:** после апрува владельца (`node bin/b113_s2a_s2b_rev2_mcp.mjs`).

## 2026-07-01 — B1.13 prog19: код CartSheet по § S2-канон

> **История (не канон):** описание раскладок ниже отражало промежуточный prog19; **текущий канон — prog20** (§ B1.13-S2-канон).

- **EXPANDED 2+:** горизонтальный ряд карточек 28vw (`shop-cart-expanded-horizontal`, `horizontal`).
- **MCP:** `b113_s2a_s2b_rev2_mcp.mjs` — layout assertions по канону.
- **Тесты:** b113_s2* — 36 runs, 0 failures.
- `CART_SHEET_BUILD=prog19`
- Коммит: `d136f16`

## 2026-06-30 — B1.13 docs: канон S2 — устранение противоречий


- **CHANGELOG:** prog9 помечен «не канон»; prog15 — канон vh 30/44 и раскладки; prog5/макеты — «устарело».
- **Артефакты:** `b113_s2_screenshot_baseline` — expanded vertical scroll при >3; MCP JSON action strings.
- **SESSION_STATE:** prog15 vh 44/30 зафиксирован как баг деплоя; код → prog19.

## 2026-06-30 — B1.13 prog18: cookie overflow fix + минус удаляет + SW networkFirst

- **P5 (3+ товар пропадал):** корень — `ActionDispatch::CookieOverflow` (session cookie ~4KB). В cookie хранили полные `selected_modifiers` (id+name+price). Теперь храним **только id**, name/price восстанавливаем из БД в `json_lines` (1 запрос). `compact_modifiers` + `modifier_option_lookup` + `hydrate_modifiers`.
- **P1 (старый JS):** SW-стратегия для `/vite/` сменена `staleWhileRevalidate` → `networkFirst` — онлайн всегда свежий бандл.
- `ModifierSelection.normalize_modifiers` — терпим к отсутствию price (compact-хранение).
- Тесты: shop регрессия 220 runs 0 failures; оплата §2.3 3/3; cart_service +2 теста. MCP **20/20 PASS** build=prog18.
- Коммит: `1185d90`

## 2026-06-30 — B1.13 prog17: SW cache_version auto от Vite manifest

- **Корень проблемы:** `SHOP_PWA_CACHE_VERSION="b14-1"` никогда не менялся → service worker раздавал старый JS через `staleWhileRevalidate` даже после деплоя.
- **Фикс:** `pwa_controller.rb#vite_manifest_cache_version` = MD5[0..7] от `public/vite/.vite/manifest.json`. Автоматически меняется при каждом деплое с новыми ассетами.
- Добавлен `Cache-Control: no-store` для `/sw.js` маршрута чтобы SW файл всегда забирался свежим.
- MCP: **20/20 PASS**, build=prog17 ✅
- Коммит: `df03f37`


- **Фикс:** `onPointerDown/Up` теперь возвращают early если `e.pointerType !== "mouse"`. Touch-жесты обрабатывает только touchstart/touchend.
- MCP: **20/20 PASS** — свайпы, scroll, layout, localStorage — всё зелёное.
- Коммит: `7449ea3`



- **EXPANDED 2+ (канон):** горизонтальный ряд карточек товара (`28vw`); при >3 — вертикальный скролл. **`expandedMulti=44vh`**.
- Тесты b113 s2/s2a/s2b — 21 runs, 0 failures ✅
- Коммит: `43a8189`


- **Фикс:** флаг `gestureActive`; touch-обработчики блокируют pointer. Inline `onpointerdown/up/cancel` удалены из шаблона.
- `CART_SHEET_BUILD=prog14`; тесты S2a/S2b/layout_gestures 21/21 ✅
- Коммит: `9c43fdc`

## 2026-06-30 — B1.13 prog13: scroll 1 товар 100px → hidden

- Fly MCP prog12: свайпы touch OK; найден баг скролла 1-item


- CartSheet: `$effect` вешает touch listeners когда `gestureZoneEl` готов (баг onMount)
- gesture-zone всегда min-h-14 (hidden тоже)
- Удалён мёртвый `cartSheetLayoutCache.js` (ссылался на удалённые layout-константы)
- `CART_SHEET_BUILD=prog12`

## 2026-06-30 — B1.13 docs: единый канон S2 (Variant B)

- § **B1.13-S2-канон** в `B1_13_shop_nav_profile_header.md` — единственный источник раскладки и жестов
- Удалены § S2-prog5 и rev1 S2 (противоречащие таблицы layout/popup)
- JSON/README S2/S3/S4 — ссылка на S2-канон, убраны «головки» и старые жесты

## 2026-06-30 — B1.13 prog11: hidden chip видимый + build stamp Fly

- hidden vh 14→20, gesture-zone min-h-8 в hidden
- чип: pill «Корзина» + сумма + «+цена»
- `data-cart-sheet-build=prog11` для верификации бандла на Fly

## 2026-06-29 — B1.13 prog10: канон layout + hidden chip (d408730)

- **EXPANDED 2+** → горизонтальные карточки 28vw
- **HIDDEN** → чип с суммой по ТЗ (без шапок товаров)
- Свайпы/скролл/1 товар — без изменений
- Тесты b113_s2* обновлены под канон


> ⚠️ **Не канон.** Ошибочный прогон; откачен **prog10**. Единственный источник раскладки — § **B1.13-S2-канon** в `B1_13_shop_nav_profile_header.md`.

- EXPANDED 2+ → вертикальный компактный список — **ошибка**

## 2026-06-29 — B1.13 prog8: финальный канон режимов (9177aed)

- **EXPANDED** = только 2+ товаров, всегда горизонтальные карточки (28vw)
- Удалён `cartSheetExpandedLayout` / `EXPANDED_LAYOUT_*` — убрана лишняя сложность
- Пороги скролла 100/200px по ТЗ заказчика

## 2026-06-29 — B1.13 prog7: layout restore fix (2d89bf3)

- `onCatalogRouteChange`: восстанавливает только mode, layout всегда vertical (horizontal только после явного свайпа)
- expanded horizontal карточки `w-[min(28vw,110px)]` — 3 видны одновременно, компактный вид

## 2026-06-29 — B1.13 prog6: UX fixes (6cdb5ed)

- **vertical default:** `applyCartData` всегда сбрасывает layout → vertical; localStorage не делает горизонтальный default
- **hidden heads:** `flex-row` горизонтальный ряд компактных верхушек (`w-11 h-9`), не широкие полосы
- **gesture zone:** `min-h-14` (56px) — шире зона свайпа


- `touchstart`/`touchend` → `addEventListener({ passive: false })` в `onMount` через `bind:this`
- Убраны `ontouchstart`/`ontouchend` из Svelte-шаблона (нельзя передать passive через атрибуты)
- Fly deploy + push `[x]`

## 2026-06-29 — B1.13 flex layout bug fix (829764b)

- **Диагноз MCP DevTools:** `gestureZone: false` — Fly держит старый бандл, прогон 5b не задеплоен
- **Фикс:** `flex flex-col overflow-hidden` на внешнем контейнере шита + `flex-1 min-h-0` на всех content-дивах (5 мест)
- **Нужно:** `git push` → GitHub Actions Deploy to Fly → re-MCP

## 2026-06-24 — B1.13 прогон 5b: gesture-zone + cold load expanded

- Тесты b113_s2* PASS · deploy → re-MCP

## 2026-06-24 — B1.13 прогон 5: канон положений поп-апа (layout + жесты)

> ⚠️ **Устарело.** § S2-prog5 удалён; актуальный канон — § **B1.13-S2-канon** (2026-06-30).

- **Док:** B1_13 § S2-prog5 — gap приёмки прогонов 1–4, таблицы mode×layout×жест
- **Тест:** b113_s2* — PASS · MCP скрипт обновлён
- **Дальше:** Fly deploy · re-MCP · апрув

## 2026-06-24 — B1.13: layout поп-апа по макетам + жесты drag-handle

> ⚠️ **Устарело.** Раскладка и hidden — только § **B1.13-S2-канон** (hidden = чип, не «головки»).

- **Тест:** `b113_s2_layout_gestures_test.rb` + b113_s2* — PASS
- **Дальше:** redeploy · re-MCP · апрув · S4


- **Код:** CartSheet pointer capture + touch-action none
- **Дальше:** redeploy UX · апрув S2a/S2b

## 2026-06-27 — B1.13 прогон 4: Fly MCP S2a/S2b (13/14)

- **MCP:** `b113_s2a_s2b_rev2_mcp.mjs` — 13/14 на Fly после deploy владельца
- **Артефакт:** `b113_s2a_s2b_rev2_post_deploy_2026-06-27.json` + скрины
- **Дальше:** redeploy → MCP 14/14 → апрув

## 2026-06-24 — B1.13-S2a прогон 3: сверка приёмки (с товаром)

- **Тест:** `b113_s2a_cart_sheet_acceptance_test.rb` + регрессия — PASS
- **Не трогали:** Q-rev2 пустая корзина · deploy · MCP
- **Дальше:** deploy + Fly MCP прогон 4

## 2026-06-24 — B1.13-S2b прогон 2: localStorage режима (Q-rev4)

- **Тест:** `b113_s2b_mode_persistence_test.rb` + регрессия S2b/S2 — PASS
- **Не сделано:** deploy · Fly MCP (прогон 4)
- **Дальше:** S2a сверка · deploy + MCP

## 2026-06-24 — B1.13-S2b прогон 1: скролл 100/200 px (Q-rev3)

- **Тест:** `b113_s2b_scroll_thresholds_test.rb` · регрессия `b113_s2_cart_popup_test.rb` — PASS
- **MCP скрипты:** scroll 100+100 px (деплой/Fly — прогон 4)


- **Дальше:** Q-rev2 → `go` S2a/S2b

## 2026-06-26 — B1.13 rev2 gate: ответы владельца Q-rev3, Q-rev4

- **Q-rev3:** скролл 100/200 px · **Q-rev4:** localStorage режима sheet
- **Q-rev2:** открыт
- **Дальше:** Q-rev2 → `go` S2a → S2b

## 2026-06-26 — B1.13-S3-rev2: post-redeploy Fly MCP 12/12 PASS

- **Deploy:** владелец — bump-queue на `coffeeos.fly.dev`
- **MCP:** повтор `b113_s3_cart_controls_mcp.mjs` — **12/12 PASS**
- **Артефакт:** `b113_s3_rev2_post_deploy_2026-06-26.json` (обновлён)
- **Дальше:** апрув S3-rev2 · S2a/S2b

## 2026-06-26 — B1.13-S3-rev2: Fly MCP 12/12 PASS (post-deploy)

- **Deploy:** владелец 2026-06-26
- **MCP:** `b113_s3_cart_controls_mcp.mjs` — 12 шагов rev2 на `coffeeos.fly.dev`
- **Хвост:** очередь bump в `cartSheetStore` — redeploy для стабильных rapid +/−
- **Дальше:** апрув S3-rev2 · S2a/S2b

## 2026-06-25 — B1.13-S3-rev2: управление qty в поп-апе (rev2)

- **API:** minus @ qty=1 → 404, не удаляет позицию; max qty guard сохранён
- **UI:** optimistic bump/remove · minus disabled @1 · `atMaxQty` @99
- **Тесты:** `b113_s3_rev2_cart_controls_test.rb` (rev1 `b113_s3_cart_controls_test` удалён)
- **Регрессия:** S3-rev2 + cart_service + S2 — 30 runs, 0 failures
- **MCP:** скрипт обновлён под rev2 (post-deploy после deploy владельца)
- **Дальше:** deploy → Fly MCP → S2a/S2b

## 2026-06-25 — B1.13-S2 фаза 3: Fly MCP PASS 9/9 (post-deploy)

- **Deploy:** владелец 2026-06-25
- **Артефакт:** `b113_s2_post_deploy_2026-06-25.json` + 5 скринов
- **Дальше:** апрув заказчика S2 · `go` S3

## 2026-06-25 — B1.13-S2 фаза 3: MCP скрипт + pre-deploy probe (blocked deploy)

- **Скрипты:** `b113_s2_cart_popup_prep_fly.rb` · `b113_s2_cart_popup_mcp.mjs` (9 шагов критериев S2)
- **Probe Fly:** 2/9 PASS — на стенде ещё pre-S2 (вкладка «Корзина»)
- **Deploy:** blocked — нет `flyctl` auth у агента
- **Артефакт:** `b113_s2_post_deploy_2026-06-25.json` + 5 скринов
- **Дальше:** владелец `bin/fly_deploy.sh` → повтор MCP

## 2026-06-24 — B1.13-S2 фаза 2: автотесты поп-ап корзины

- **Тесты:** `b113_s2_cart_popup_test.rb` — bottom bar 2 вкладки, CartSheet, пороги, cart API
- **S1:** `b113_s1_profile_header_test.rb` — убрана проверка вкладки «Корзина»
- **Регрессия:** `test/integration/shop/` — 147 runs, 0 failures
- **Дальше:** фаза 3 Fly MCP

## 2026-06-25 — B1.13: КАНОН bottom bar (2 вкладки, профиль в шапке) закрыт навсегда

- **B1_13:** § КАНОН + Q-rev1/Q-epic-1 — не обсуждаем «3 вкладки» из текста заказчика

## 2026-06-25 — B1.13 rev2: 4 документа заказчика в B1_13 (только docs)

- **Разделы:** S1-R1 · S2a · S2b · S3-rev2 — тексты дословно + чеклисты приёмки
- **Rev1:** S2/S3 помечены superseded; код rev1 без изменений
- **Конфликты:** Q-rev1…6 в `B1_13_shop_nav_profile_header.md`
- **Дальше:** скрины rev2 → `go` на код-дельты

## 2026-06-25 — B1.13-S3: управление товарами в поп-апе корзины

- **API:** `CartService#update_quantity!` — guard `MAX_ITEM_QUANTITY` (99)
- **Тесты:** `b113_s3_cart_controls_test.rb` (5) + `cart_service_test` max qty
- **MCP скрипт:** `bin/b113_s3_cart_controls_mcp.mjs`
- **Pre-deploy probe Fly:** `b113_s3_post_deploy_2026-06-25.json` — **FAIL** (step 02, нет testid на стенде) · скрин `b113_s3_post_deploy_expanded_2026-06-25.png`
- **Дальше:** deploy → повтор MCP S3 PASS · `go` S4




- **Deploy:** владелец · стенд `coffeeos.fly.dev`
- **Дальше:** апрув заказчика · `fly secrets set TBANK_RSA_PUBLIC_KEY`


- **UI:** `CheckoutPayButton` — синяя/зелёная/красная/серая, loader, shake State 5
- **Дальше:** фаза 3 — Fly deploy + MCP


- **Checkout:** summary-ряд «Способ оплаты» · убран legacy `saved-card-block` и таб «Картой»


- **Дальше:** `go` R3 код · deploy после R3


- **Checkout:** убран редирект на iframe/URL банка для новой карты
- **Дальше:** `go` R3 · deploy после R3




- **Правило:** один документ заказчика = один `go` = один R = commit/ops/стоп
- **Дальше:** Q-R2-1 → `go` R1


- **Конфликты:** Q-R2-1..3 (ex Q1/Q5/Q6) — блокер до ответов владельца
- **CHECKLIST:** C2a (docs) · C2b (legacy v1) · C2c (rev2 код)
- **Дальше:** Q-R2-1..3 → `go` R1



## 2026-06-24 — ops: fly_deploy WSL (docker.sock + /mnt/c/)

- **Проблема:** WSL `/mnt/c/` — `load build context` timeout; retry → `unix:///var/run/docker.sock: missing hostname`
- **Фикс:** `--remote-only` (как CI) · `unset DOCKER_HOST` · WSL `/mnt/*`: `git archive` + overlay → `~/.cache/coffeeos-fly-deploy`
- **Доки:** `FLY_DEMO_STAND.md` § WSL deploy · `bin/README.md`

## 2026-06-23 — B1.14-3d: карта всех точек на списке УК

- **УК:** `/admin/tenants` — Leaflet/OSM, маркеры sales_point с lat/lng, popup → карточка
- **Сервис:** `Platform::TenantsMapPins` · shared `leaflet_setup.js`
- **Тесты:** 2 новых + регрессия 3c — 4 runs, 0 failures
- **Дальше:** deploy · B1.14-4 cart

## 2026-06-23 — B1.14-3c: карта координат в УК (Leaflet/OSM)

- **УК:** форма точки — «Указать на карте», поля lat/lng, Stimulus `tenant_map_controller`
- **Карточка:** отображение координат в блоке «Входы и URL»
- **CSP:** `unpkg.com` для Leaflet (без геокодера)
- **Тесты:** `b114_tenant_map_test.rb` — 2 runs, 0 failures
- **Дальше:** deploy · B1.14-4 cart

## 2026-06-23 — B1.14-3b: дропдаун точек по городу + координаты

- **Миграция:** `latitude`/`longitude` на `tenants`
- **API:** `GET /shop/api/tenants` — все активные точки в городе (любая org) · текущая → ближайшие по geo
- **Demo:** `demo-point-c` (вторая org), координаты, цены +20, расписание 07–21
- **Тесты:** 12+2 runs, 0 failures (b114 + demo seed)
- **Дальше:** deploy → B1.14-4 cart

## 2026-06-23 — ops: Fly deploy Depot 401 + B1.14-2/3 на стенде

- **Проблема:** `fly deploy` → `ensure depot builder failed (401)` на этапе push (Depot, не код приложения)
- **Фикс:** `bin/fly_deploy.sh` (`--depot=false`) · runbook `FLY_DEMO_STAND.md` · CI `deploy.yml` · `INFRA_STACK.md`
- **Deploy:** `deployment-01KVT2DYNPBFBXC1JNHETRRQYZ` · `/up` 200 · B1.14 `display_address` в бандле
- **Дальше:** MCP скрины B1.14 · B1.14-4 cart

## 2026-06-23 — B1.14-3: Header адрес точки + дропдаун

- **Frontend:** `Header.svelte` · `shopTenantHeader.js` · `App.svelte` bootstrap
- **UX:** адрес «Город, Адрес» · дропдаун при `switchable` · localStorage офлайн · редирект на выбранную/последнюю точку
- **Тесты:** `b114_header_tenant_address_test.rb` + регрессия b113/b114 API — 10 runs, 0 failures
- **Дальше:** deploy → MCP скрины · B1.14-4 cart

## 2026-06-23 — B1.14-2: API адрес точки + demo seed

- **API:** `GET /shop/api/config` — блок `tenant` + `last_ordered_tenant_id` · `GET /shop/api/tenants` (история заказов)
- **Сервисы:** `Shop::TenantAddress`, `Shop::CustomerTenantHistory`
- **Seed:** `Demo::EnvironmentSetup` — Москва, ул. Ленина/Пушкина у demo A/B
- **Тесты:** 12 runs, 89 assertions, 0 failures (b114 + tenant_address + customer_tenant_history + config + demo seed)
- **Runbook:** `FLUTTER_API.md` § B1.14
- **Дальше:** `go` B1.14-3 Header

## 2026-06-23 — B1.14: скрины baseline заказчика

- **Скрины:** `b114_shop_header_coffeeos_before_2026-06-23.png` (витрина #1) · `b114_uk_tenants_card_before_2026-06-23.png` (УК #2+#3)
- **Артефакт:** [`b114_screenshot_baseline_2026-06-23.json`](../milestones/veha_2/artifacts/demo-feedback/b114_screenshot_baseline_2026-06-23.json)
- **README:** [`README_b114_baseline_2026-06-23.md`](../milestones/veha_2/artifacts/demo-feedback/screenshots/README_b114_baseline_2026-06-23.md)
- **ТЗ:** gate docs скрины `[x]` · ждём апрув + `go`

## 2026-06-23 — B1.14: этап 0 — ТЗ адрес точки в шапке витрины

- **ТЗ:** [`B1_14_shop_tenant_address_header.md`](../milestones/veha_2/requirements/customer_tasks/B1_14_shop_tenant_address_header.md) — текст заказчика («задача 2») дословно · scope · критерии OPS · ответы владельца Q1–Q10
- **Артефакт:** [`b114_stage0_scope_2026-06-23.json`](../milestones/veha_2/artifacts/demo-feedback/b114_stage0_scope_2026-06-23.json)
- **Ops:** CBR · README customer_tasks · CHECKLIST · HANDOFF · SESSION_STATE
- **Код:** не начат · апрув + `go`

## 2026-06-24 — B1.13-S2: CartSheet поп-ап корзины (фаза 1 код)

- **Код:** `CartSheet.svelte` · `cartSheetStore.js` · `cartSheetThresholds.js` · BottomNav 2 вкладки · `#/cart` → redirect
- **Фаза 2:** тесты + Fly MCP — ждём команды

## 2026-06-24 — B1.13-S2: ответы закрыты + пропорции макетов

- **Скрины:** 4 макета уже в `screenshots/b113_s2_customer_01..04.png`
- **ТЗ:** таблица Q-S2-1…10 · пороги vh/scroll · плейсхолдер «тут будут твои заказы»
- **JSON:** `b113_s2_screenshot_baseline_2026-06-22.json` обновлён
- **Дальше:** `go` на код S2

## 2026-06-24 — B1.13-S2: канон bottom bar (Q-epic-1 закрыт навсегда)

- **Канон:** 2 вкладки (Каталог + Избранное), профиль в шапке — не обсуждаем
- **ТЗ:** таблица «Критерии приёмки CoffeeOS» для S2 · примечание к дословному тексту заказчика

## 2026-06-24 — B1.13-S2/S3/S4: чеклисты реализации в ТЗ

- **Файл:** `B1_13_shop_nav_profile_header.md` — gate + реализация для S2, S3, S4
- **S1:** чеклист Fly MCP отмечен `[x]`
- **Дальше:** ждём `go` на S2

## 2026-06-23 — B1.13-S1: Fly MCP post-deploy (PASS)

- **Стенд:** `coffeeos.fly.dev/shop?tenant_id=655aaccb-…`
- **MCP:** 5/5 критериев · nav profile **101 ms** · гость «Профиль» без ID · bottom nav без «Профиль»
- **Артефакт:** [`b113_s1_post_deploy_2026-06-23.json`](../milestones/veha_2/artifacts/demo-feedback/b113_s1_post_deploy_2026-06-23.json)
- **Скрины:** `b113_s1_post_deploy_{320,360,428,profile}_2026-06-23.png`
- **Дальше:** апрув заказчика S1 → `go` S2

## 2026-06-22 — B1.13-S1: профиль в шапке (код)

- **Код:** `Header.svelte` «Профиль › ID» · `BottomNav` без «Профиль» · `shopProfileHeader.js`
- **Тест:** `b113_s1_profile_header_test.rb` — **5 runs, 37 assertions, 0 failures**
- **Скрины:** `b113_s1_after_{320,360,428}px_2026-06-22.png` · `b113_s1_local_pre_deploy_2026-06-22.json`
- **Deploy:** ждём владельца · затем Fly MCP

## 2026-06-22 — B1.13: ответы Q-epic-1…3, Q1–Q2 (не блокер)

- **Q-epic-1:** профиль в шапке · бар **Каталог + Избранное** · «Профиль» в S2 — опечатка
- **Q-epic-2:** корзина только поп-ап · `#/cart` убираем
- **Q-epic-3:** пороги скролла — по скринам заказчика (% экрана)
- **Q1:** гость → `#/profile` как сейчас
- **Q2:** ID сокращённо по ТЗ (`1002…34`)

## 2026-06-22 — B1.13: ТЗ S2–S4 эпик навигации (поп-ап корзины)

- **ТЗ:** [`B1_13_shop_nav_profile_header.md`](../milestones/veha_2/requirements/customer_tasks/B1_13_shop_nav_profile_header.md) — S2–S4 текст заказчика дословно · сводка эпика · Q-epic-1…3
- **Артефакт:** [`b113_stage0_s2_s4_2026-06-22.json`](../milestones/veha_2/artifacts/demo-feedback/b113_stage0_s2_s4_2026-06-22.json)
- **Порядок кода:** S1 → S2 → S3 → S4
- **Код:** не начат

## 2026-06-22 — B1.13-S1: ТЗ «Профиль в шапке» (эпик навигации витрины)

- **ТЗ:** [`B1_13_shop_nav_profile_header.md`](../milestones/veha_2/requirements/customer_tasks/B1_13_shop_nav_profile_header.md) — текст заказчика дословно · эпик B1.13 (S1–S4) · S1 = Header + BottomNav
- **Артефакт:** [`b113_stage0_scope_2026-06-22.json`](../milestones/veha_2/artifacts/demo-feedback/b113_stage0_scope_2026-06-22.json)
- **Индекс:** CBR · `customer_tasks/README.md` · CHECKLIST § B2B
- **Код:** не начат · стоп до апрува + `go`

## v1.239 — 2026-06-22 (B1.13-S4: макеты модификаторы + горизонтальный скролл)

- **Сохранено:** 3 PNG — горизонтальный ряд >3 · модификаторы в expanded · +цена справа.
- **Не делали:** код S4.

## v1.238 — 2026-06-22 (B1.13-S3: макеты управления в поп-апе — 3 режима)

- **Не делали:** код S3 (после S2).

## v1.237 — 2026-06-22 (B1.13-S2: макеты поп-апа корзины — 4 скрина)

- **Анализ:** сейчас bottom bar 4 вкладки + `#/cart`; цель — CartSheet 3 состояния без вкладки «Корзина».
- **Не делали:** код S2.

## v1.236 — 2026-06-22 (B1.13-S1: baseline скрин заказчика)

- **Скрин #1:** каталог — шапка «Витрина» (до S1), PWA-баннер.
- **Артефакты:** `b113_s1_catalog_before_2026-06-22.png` · `b113_s1_screenshot_baseline_2026-06-22.json`.
- **Не делали:** код S1 · скрин bottom nav.


- **Баг (после deploy заказчика):** 2-я оплата — снова Т-Банк снизу; карта не в блоке «Сохранённая карта» → флоу как первая оплата.
- **Нужен:** повторный **deploy Fly** + real-card 1→2.


- **Было:** форма Т-Банка встраивалась снизу на `#/checkout` (скрин заказчика).
- **Стало:** первая оплата — редирект на `payment_url`; этапы в кнопке; возврат `#/payment-result` + finalize.
- **API:** `payment_iframe: false` для card init.
- **Тест:** b112 checkout/r2/settle/r3 — 15 runs, 99 assertions, 0 failures.
- **Не делали:** deploy Fly · MCP post-deploy.


- **Не делали:** deploy Fly · real-card E2E · апрув заказчика.


- **Не делали:** deploy Fly · MCP real-card E2E · апрув заказчика.


- **Deploy:** владелец · `75dc252` на coffeeos.fly.dev.
- **Не делали:** апрув заказчика эпик · real-card E2E.


- **Сделано:** `Payment.svelte` удалён; маршрут `/payment` снят из `App.svelte` — оплата только inline на checkout.
- **Не делали:** deploy на Fly, повторный MCP post-deploy, апрув заказчика.


- **Deploy:** владелец · `783b4ff` на coffeeos.fly.dev.
- **Не делали:** апрув заказчика эпик · real-card E2E.


- **Ошибка (не было сделано):** после R2/R3 оставались экраны Оформление → Оплата → iframe; `push("/payment")`.
- **Стало:** inline iframe на `#/checkout`, кнопка со статусами, `#/payment` только redirect legacy.
- **Не делали:** Fly MCP post-deploy, апрув заказчика.


- **Было:** fix `2b15578` локально; post-deploy repro не гоняли.
- **Стало:** Fly MCP tenant `2fdee1ac-…` — immediate return → `#/order/:id` · poll+webhook → redirect · DevTools: POST finalize.
- **Не делали:** real-card 3DS E2E (нужна карта заказчика).


- **Было:** polling+cable только при `phase=paying`; после 3DS return (`deepLinkRedirectCallback`) — intro без watch.
- **Стало:** `payment_started` в session · `awaiting_settlement` + `beginSettlementWatch` + immediate finalize на return.
- **deepLinkRedirectCallback:** полный redirect в банк (канон T-Bank); возврат через sessionStorage.


- **Было:** баг 🔴 open — UI зависал на `#/payment` после webhook; fix `14cdf12` не на Fly.
- **Стало:** deploy владельца · Fly MCP tenant `2fdee1ac-…` — callback→accepted→finalize `payment_settled` PASS · ISSUES **resolved**.


- **Было:** `finishSuccess()` только из `integration.js`; embed fallback без callback — зависание на форме Т-Банка.
- **Стало:** `beginSettlementWatch()` — poll `POST /orders/:id/finalize` + cable `accepted`/`payment_settled` → `#/payment-result`.
- **Не делали:** fly deploy, MCP repro tenant `2fdee1ac-…`.


- **Likely repro:** order `acb7cc62…` 4.74₽ · payment `8704452356`.
- **Следующий:** шаг 2 polling finalize (код не меняли).


- **ISSUES:** 🔴 open — разбор в `agent_analysis`.

## v1.224 — 2026-06-21 (demo: открытые смены + Сб–Вс точка A)

- **demo:seed:** смены A/B открыты (barista-a/b) · точка A Сб–Вс 10–20, Пн–Пт до 22:00.
- **Цель:** проверка оплаты на Fly без баннера «закрыты» (воскресенье).
- **На Fly:** `fly deploy` + `demo:seed` (release или ssh).

## v1.223 — 2026-06-21 (B1.11 Fly MCP: шапка витрины post-deploy)

- **Fly:** demo-point-a `08–20/09–17` · demo-point-b `09–22/10–20` в header + API.
- **MCP:** browser A (closed banner) + B (open) · API match обе точки.
- **Тест:** 10/10 PASS.
- **Артефакт:** `b111_header_schedule_post_deploy_2026-06-21.json`.
- **Ждём:** апрув заказчика.

## v1.222 — 2026-06-21 (B1.11: режим работы в шапке витрины)

- **API:** `operating_hours.schedule_display` — компактная строка по дням.
- **UI:** `Header.svelte` — часы под CoffeeOS; `ShopClosedBanner` сдвинут ниже.
- **Demo:** `demo-point-a` Пн–Пт 08–20, Сб 09–17 · `demo-point-b` Пн–Пт 09–22, Сб–Вс 10–20 (`demo:seed`).
- **Тест:** `operating_hours_schedule_text_test` + b111 + environment_setup — 13 runs PASS.
- **Дальше:** deploy → апрув заказчика.

## v1.221 — 2026-06-19 (B1.11 handoff — ждём заказчика)

- **Статус:** код + Fly MCP + 37/37 — done с нашей стороны.
- **Блокер:** апрув заказчика — проверит на Fly, «ок» или правки.
- **Агент:** стоп, код не менять.

## v1.220 — 2026-06-19 (B1.11 Fly MCP post-deploy)

- **Deploy:** владелец вручную на `coffeeos.fly.dev`.
- **Fly MCP:** API + browser + session — shop `operating_hours`, barista табло, manager shifts, УК «Режим работы».
- **Тест:** 37 runs, 122 assertions, 0 failures (b111 suite).
- **Артефакт:** `b111_operating_hours_post_deploy_2026-06-19.json` — `fly_mcp: pass`.
- **Ожидает:** апрув заказчика.

## v1.219 — 2026-06-19 (B1.11 этап 7: integration + manager UI + артефакт)

- **Manager UI:** «Требуется закрытие смены» при конфликте / note `[B1.11]`.
- **CashShift:** `requires_manager_close?`, `schedule_close_requested?`.
- **Regression:** block_g shop order + email fix.
- **Артефакт:** `b111_operating_hours_post_deploy_2026-06-19.json` — 28/28 local.
- **Fly MCP:** pending_deploy.

## v1.218 — 2026-06-19 (B1.11 этап 5–6: табло + POS + logout)

- **Было:** табло показывало витрину без смены; нет конфликта смена/расписание.
- **Стало:** смена закрыта → табло пусто; конфликт → красный баннер + звук; POS вне часов ok; logout → note на смене.
- **Тест:** barista b111 + services — 16/16 PASS.

## v1.217 — 2026-06-19 (B1.11 этап 4–5: shop API + checkout)

- **API:** `operating_hours` в `/config` и `categories` meta; guard `POST /orders` вне часов; cart без блока.
- **Витрина:** `ShopClosedBanner`, checkout баннер + `canPay` off; legacy без расписания = открыто.
- **Тест:** `b111_operating_hours_test.rb` — 7/7 PASS.

## v1.216 — 2026-06-19 (B1.11 этап 3c: open_now? / next_open_at)

- **Было:** расписание в БД, без расчёта открыто/закрыто.
- **Стало:** `TenantOperatingHours` — timezone точки, open_now?, next_open_at (след. открытие).
- **Тест:** `tenant_operating_hours_test.rb` — 6/6 PASS.

## v1.215 — 2026-06-19 (B1.11 этап 3b: форма УК — режим работы)

- **Было:** форма точки без расписания пн–вс.
- **Стало:** блок «Режим работы» (sales_point) — чекбоксы + open/close; sync на create/update; ≥1 день обязателен.
- **Код:** `TenantWeekdaySchedulesSync`, `_weekday_schedules_fields`, `TenantsController`.
- **Тест:** sync + controller — 7/7 PASS.
- **Артефакт:** скрин до — `b111_uk_tenant_form_before_2026-06-19.png`.

## v1.214 — 2026-06-19 (B1.11 этап 3a: миграция + модель расписания)

- **БД:** `tenant_weekday_schedules` — weekday, enabled, opens_at/closes_at, RLS + UK admin.
- **Модель:** `TenantWeekdaySchedule`; `Tenant#weekday_schedules`.
- **Тест:** `test/models/tenant_weekday_schedule_test.rb` — 6/6 PASS.
- **Ops:** B1_11 checklist п.1, SESSION_STATE, HANDOFF.

## v1.213 — 2026-06-19 (B1.11: ответы раунд 2 — готовность полная)

- **Уточнения:** корзина ok/оплата off; баннер «след. утро раб. дня»; чекбоксы пн–вс; табло красный баннер+звук; barista POS в зале → табло.
- **Артефакт:** `b111_customer_answers_round2_2026-06-19.json`.
- **Ops:** `B1_11_tenant_operating_hours.md`, HANDOFF, SESSION_STATE, DEMO_FEEDBACK.

## v1.212 — 2026-06-19 (B1.11: ответы Q1–Q10, готовность к коду)

- **Режим работы:** ответы владельца Q5–Q10 + дефолты Q1–Q3 → `B1_11_tenant_operating_hours.md`.
- **Готовность:** READY_FOR_APPROVAL — ждём апрув + `go`; код не начинать.
- **Артефакт:** `b111_customer_answers_confirmed_2026-06-19.json`.
- **Ops:** CBR, CHECKLIST, DEMO_FEEDBACK, HANDOFF, SESSION_STATE.


- **Ops:** CBR, DEMO_FEEDBACK, `customer_tasks/README`, SESSION_STATE, HANDOFF.

## v1.210 — 2026-06-19 (Веха 1 закрыта — заочная приёмка)

- **В1 «Цифровой прилавок»:** формально **закрыта** по апруву владельца (2026-06-19).
- **CHECKLIST § I + H.3:** `[x]`; живое демо §1 (2026-05-30) принято заочно, блокеров не заявлено.
- **Хвосты → В2:** QA 5.1 онбординг; `demo:seed` в release_command; полный MCP LIVE_DEMO §2–10.
- **Ops:** `SESSION_STATE`, `HANDOFF`, `veha_1/README`, `PRACTICES.md`.




- **Не в шаге:** fly deploy, Fly MCP R3 post-deploy — по апруву.


- **Neon:** spending limit $15 включён владельцем в Console.

## v1.206 — 2026-06-19 (Neon Launch + Fly MPG удалён + deploy по апруву)

- **БД:** канон **Neon** `coffeeos` (Launch); `DATABASE_URL` на Fly; Fly MPG `coffeeos-db` **destroyed**.
- **Deploy:** `release_command` OK на Neon; GHA deploy — только `workflow_dispatch`.
- **Ops:** `INFRA_STACK.md` — лимит Neon **$15**, деплой только по апруву, экономия CU-hrs.
- **Владелец:** Neon Console → Billing → Spending limit **$15** Enable (alerts; suspend when available).

## v1.205 — 2026-06-19 (инфра: Fly MPG, запрет внешних BaaS)

- **БД:** Fly Managed Postgres `coffeeos-db` + attach `coffeeos`; снят случайный внешний `DATABASE_URL`.
- **Fix:** `schema.rb` — `pg_stat_statements` не в schema:load (MPG без superuser).
- **Docs:** `INFRA_STACK.md` — канон (Fly app + Fly MPG); Supabase/Neon/Render — не использовать без апрува.

## v1.204 — 2026-06-19 (Fly: docker-entrypoint не падает на db:prepare fail)

- **Fix:** Puma стартует при временной недоступности Postgres.
- **Docs:** `FLY_DEMO_STAND.md` §3 db:prepare troubleshooting.


- **Витрина:** PaymentResult «Карта привязана / Оплачено»; Payment intro для привязки.




- **Тесты:** 8 R1 + regression §2.3 PASS.


- **Q2** все карты храним, главная = последняя успешная оплата.
- **Q5** сохранять после первой успешной оплаты.
- **Q7** ошибки карты vs retry + идемпотентность.


- **Q1** только web-фрейм · **Q4** verified email (B1.7) · **Q6** без макетов, стиль витрины.
- Ждём: Q2, Q3, Q5, Q7.



## v1.197 — 2026-06-18 (B1.11: этап 0 — ТЗ режим работы точки)

- **B1.11:** ТЗ + `b111_stage0_scope_2026-06-18.json` · вопросы Q1–Q10 · код не начат.

## v1.196 — 2026-06-18 (B1.10: апрув заказчика)

- **B1.10:** убрать «Блог» из навигации — апрув `b110_customer_approval_2026-06-18.json`.

## v1.195 — 2026-06-18 (B1.9: апрув заказчика + backlog CC-2)

- **B1.9:** toggle-модификаторы — апрув `b19_customer_approval_2026-06-18.json`.
- **Backlog:** CC-2 восстановление выбора после возврата из корзины → CBR B1.9-CC2.

## v1.194 — 2026-06-18 (B1.7 BR-6: апрув заказчика)

- **BR-6:** отмена на `#/payment` — апрув `b17_br6_customer_approval_2026-06-18.json`.

## v1.193 — 2026-06-18 (B1.7 BR-5: апрув заказчика)

- **BR-5:** второй товар в корзину — апрув заказчика `b17_br5_customer_approval_2026-06-18.json`.
- **Артефакты:** обновлены `b17_br5_regression_post_deploy`, `b17_cart_second_product_post_deploy`.

## v1.192 — 2026-06-18 (B2.1: апрув заказчика + backlog фаза 2)

- **B2.1:** апрув заказчика MVP + ревизия — `b21_customer_approval_2026-06-18.json`.
- **Backlog:** брак/переделка, `defect_reasons`, звук отмены, списание, `prep_kitchen`, эскалация 5 мин → CBR + B2_1 § Бэклог.

## v1.191 — 2026-06-13 (B2.1 R3: revision tests + fly smoke)

- **Тесты:** tap white→yellow→gone, limit 6, `OrderBoardBroadcaster` broadcast target.
- **Smoke:** `bin/b21_revision_fly_smoke.rb` (REVISION=1).

## v1.190 — 2026-06-13 (B2.1 R2: Fly MCP live без F5)

- **Fly MCP:** разметка `#barista-board-slots` + turbo-cable + turbo-stream 200 — PASS.
- **Скрипт:** `bin/b21_revision_r2_live_fly.rb`.
- **Артефакт:** `b21_revision_r2_mcp_fly_2026-06-13.json`.

## v1.189 — 2026-06-12 (B2.1 ревизия: 6 слотов, тап, live broadcast)

- **Табло:** 2×3 грид, белый `accepted` / жёлтый `preparing`, тап → `ready` снимает с табло; max 6 FIFO.
- **Live:** `OrderBoardBroadcaster` и turbo streams бьют в `#barista-board-slots`.
- **Макет:** `b21_customer_mockup_6_cards.png` + analysis JSON.

## v1.188 — 2026-06-12 (B2.1 ревизия: подготовка ТЗ табло)

- **Заказчик:** 2 баг-репорта — 6 карточек (тап белый→жёлтый→убрать) + live без F5.
- **Доки:** §Ревизия в `B2_1_barista_order_board.md`, чеклист R0–R4, бэклог, scope vs MVP.
- **Артефакт:** `b21_revision_stage0_scope_2026-06-12.json`.

## v1.187 — 2026-06-12 (B1.1 R4: Fly MCP приёмка ревизии)

- **Приёмка:** chrome-devtools MCP — путь витрина→checkout→статус; 8 скринов на Fly; 4 шага прогресс-бара + WS.
- **Артефакты:** `b11_revision_acceptance_2026-06-12.json`, `b11_mcp_fly_2026-06-12.json`.
- **Скрипты:** `bin/b11_revision_fly_prep.rb`, `bin/b11_revision_fly_status.rb`.

## v1.186 — 2026-06-12 (B1.1 ревизия: экран статуса по макету)

- **UI:** `OrderStatus.svelte` — самовывоз (зелёная карточка), состав `1x`, блок оплаты, отмена текстом.
- **Прогресс:** только ETA «Примерно 8–12 минут»; иконки шагов 🍽/🔔.
- **WS:** reconnect каждые 5 с без лимита попыток.
- **Доки:** ревизия ТЗ заказчика, чеклист R0–R2, бэклог; макеты в `b11_order_status_revision_2026-06-12/`.

## v1.185 — 2026-06-12 (B1.4 хвосты: офлайн cart, UUID в БД, промокод UI)

- **Офлайн:** `shopOfflineCart.js`, `shopCartAdd.js` — очередь add в корзину.
- **Бэк:** `orders.client_order_uuid` unique; idempotency без Rails.cache.
- **Приёмка:** `b14_pwa_browser_shots.mjs`, `b14_run_acceptance.sh`; удалён flaky `acceptance_fly.mjs`.
- **UI:** промокод убран из корзины (BR).
- **Долги:** § в `B1_4_pwa_shop.md` — 2 SW, Background Sync, домен shop, приёмки.

## v1.184 — 2026-06-12 (B1.4 PWA: OPS_PASS на Fly)

- **Приёмка:** `b14_pwa_acceptance_2026-06-12.json` — smoke PASS, PWA audit 100%, LCP 183 ms.
- **Скрины:** `screenshots/b14_pwa_2026-06-11/` (5 файлов).
- **Скрипты:** `b14_pwa_fly_smoke`, `b14_pwa_programmatic_audit`, `b14_finalize_acceptance`.

## v1.183 — 2026-06-11 (B1.4 PWA: manifest, SW, offline checkout)

- **PWA:** `/shop/manifest.webmanifest`, `/shop/service-worker.js`, иконки `public/pwa/`.
- **Фронт:** `shopPwa.js`, `shopOfflineQueue.js`, `ShopPwaBanner`, offline catalog/cart fallback.
- **Бэк:** `client_order_uuid` idempotency в `OrderCreator`.
- **Тесты:** `pwa_manifest_test`, orders idempotent; smoke `bin/b14_pwa_fly_smoke.rb`.

## v1.182 — 2026-06-11 (B1.4 PWA: ТЗ + baseline, без кода)

- **ТЗ:** `B1_4_pwa_shop.md` — текст заказчика, этапы 0–5, критерии Lighthouse/LCP/offline checkout.
- **Runbook:** `SHOP_PWA.md` — политика кэша, SW vs FCM, проверки.
- **Артефакт:** `b14_stage0_baseline_2026-06-11.json`; папка скринов `b14_pwa_2026-06-11/`.
- **Ops:** CHECKLIST, CBR, customer_tasks README; B2.1 PWA → ссылка на B1.4.

## v1.181 — 2026-06-11 (B2.1: push pipeline simulation без устройства)

- **FCM_SIMULATE:** `FcmClient` — отправка без Google; job → `PushNotification.status=sent`.
- **Тесты:** `push_pipeline_simulation_test` — бариста → job → sent + B2.1 body.
- **Ops:** `bin/b21_push_pipeline_fly.rb`, `bin/rails shop:push:smoke ORDER_ID=…`.

## v1.180 — 2026-06-11 (витрина: removed_modifiers на табло бариста)

- **Логика:** все опции товара минус `selected_modifiers` → `removed_modifiers` («БЕЗ …» на карточке).
- **Код:** `Shop::ModifierSelection`, `CartService`, `OrderCreator`, `Product.svelte` + `modifiers.js`.
- **Тесты:** `modifier_selection_test`, `removed_modifiers_checkout_test`.

## v1.179 — 2026-06-11 (витрина: OTP verify в Postgres per tenant)

- **Миграция:** `shop_email_verifications` — `tenant_id` + `session_id` + email, TTL 24ч; FK tenants.
- **Сервис:** `Shop::EmailVerification` — session + DB; `EmailOtpController`, `OrderCreator` через единый API.
- **Зачем:** подтверждение email не слетает между web-инстансами (без Redis); изоляция по точке сохранена.
- **Тесты:** unit + integration DB fallback при пустой session bucket.

## v1.178 — 2026-06-11 (витрина checkout: sync email verified с сервером)

- **Фронт:** `Checkout.svelte` — `syncServerStatus` сбрасывает ложный verified; preflight перед `POST /orders`.
- **Профиль:** `clearEmailVerifiedInProfile()` — localStorage не врёт при истёкшей session.
- **Кейс:** гость видит OTP-форму, а не блок «Контакты» + ошибка при оплате.

## v1.177 — 2026-06-11 (B2.1: formal acceptance OPS_PASS — критерии 1–9)

- **Acceptance:** `bin/b21_acceptance_fly.rb` — Playwright замеры + скрины stage1–5 на Fly, FCM v1 pipeline.
- **Критерии:** 1–9 формально PASS (`b21_acceptance_2026-06-11.json`, `internal_signoff_ready`).
- **Скрины:** stage2/4 Fly, `stage1_*_fly`, `stage3_push_optional.png`.

## v1.176 — 2026-06-11 (B2.1: браузерный e2e витрина→бариста→гость Fly PASS)

- **Playwright e2e:** `bin/b21_mcp_e2e_prep.rb`, `b21_mcp_e2e_fly.mjs`, оркестратор `b21_mcp_e2e_fly.rb` — UI-клики бариста + WS гостю ≤5с.
- **Артефакт:** `b21_mcp_e2e_2026-06-11.json` — **PASS**; acceptance крит. 7, 9 формально PASS.
- **Smoke:** markup `ГОТОВИТСЯ` после заказа на табло (`b21_board_layout` + `b21_board_markup`).
- **Скрины:** полный набор `stage5_e2e_*` на Fly.

## v1.175 — 2026-06-11 (B2.1 этап 3: скрины гостя preparing/ready)

- **Скрины Fly:** `stage3_guest_preparing.png`, `stage3_guest_ready.png` — подзаголовки B2.1 на `/shop`.
- **Скрипты:** prep + Playwright `b21_stage3_guest_screenshots.mjs`, статус на Fly `b21_stage3_fly_status.rb`.

## v1.174 — 2026-06-11 (B2.1 этап 5: Fly smoke e2e PASS)

- **Smoke:** vitrina→табло **PASS** — `order_8e2bc72e`, `FLY_BIN=flyctl`, `b21_fly_smoke_2026-06-11.json`.
- **Acceptance:** критерий 9 формально PASS; этап 5 ops gate закрыт (без подписи заказчика).
- **Дальше:** stage3 guest скрины, MCP e2e бариста→гость.

## v1.173 — 2026-06-11 (B2.1: табло — scope смены вместо limit 50)

- **BoardOrdersQuery:** открытая смена + витрина (`cash_shift_id` NULL, `source: mobile`, с `opened_at`); убран слепой `limit(50)` по всему тенанту.
- **Counts:** `OrderBoardBroadcaster`, turbo `update_status`/`cancel`, `orders_controller#broadcast_order_counts` — тот же `board_scope`.
- **Тесты:** >50 accepted в смене — новый заказ виден (`order_<uuid>`); unit scope vitrina/FIFO.
- **Smoke:** проверка `id="order_<uuid>"` с retry вместо `include?` по всей странице.
- **Smoke e2e:** PASS — см. v1.174.

## v1.172 — 2026-06-11 (B2.1 post-deploy Fly: markup smoke PASS)

- **Fly:** B2.1 разметка на `coffeeos.fly.dev` — smoke + MCP verify PASS.
- **Скрины:** обновлены Fly `barista_board_after`, `stage5_e2e_vitrina_to_board`.
- **Smoke:** статус PARTIAL при OTP skip (не затирать FAIL).

## v1.171 — 2026-06-11 (B2.1: Bullet — убрать лишний includes на табло)

- **BoardOrdersQuery:** только `order_items` + `order_status_logs` (без customer/payments).
- **Карточка:** `first(4)` по preload вместо `.limit(4)` — Bullet AVOID eager loading.

## v1.170 — 2026-06-11 (B2.1 этап 5: ops gate — smoke, MCP, скрины)

- **Скрипты:** `b21_barista_board_fly_smoke.rb`, `b21_mcp_fly_verify.rb`.
- **Артефакты:** `b21_acceptance_2026-06-11.json`, MCP/Fly smoke JSON; скрины stage2/4/5.
- **Fix:** cancel overlay скрыт до `is-visible`.
- **Статус:** PARTIAL — Fly без B2.1 deploy; приёмка заказчика открыта.

## v1.169 — 2026-06-11 (B2.1 этап 4: overlay отмены на табло)

- **Отмена:** overlay на карточке, Stimulus, resync колонки через `cancel.turbo_stream`.
- **Артефакт:** `b21_stage4_cancel_2026-06-11.json`.

## v1.168 — 2026-06-11 (B2.1 этап 3: гость WS + push тексты)

- **Push/WS:** тексты B2.1, подзаголовки `OrderStatus.svelte`, retry в `shopOrderCable.js`.
- **Тесты:** `b21_guest_notify_test`, push notifier.
- **Артефакт:** `b21_stage3_guest_notify_2026-06-11.json`.

## v1.167 — 2026-06-11 (B2.1 этап 2: FIFO табло бариста)

- **FIFO:** `BoardOrdersQuery`, resync колонок в `OrderBoardBroadcaster` и turbo `update_status`.
- **UX:** убрана подсказка drag; partial `orders_column`.
- **Fix:** turbo-шаблон перенесён в `barista/orders/update_status.turbo_stream.erb`.
- **Артефакт:** `b21_stage2_fifo_2026-06-11.json`.

## v1.166 — 2026-06-10 (B2.1 этап 1: карточка табло бариста)

- **UI:** `_order_card` — цвет по статусу, кнопка 80px (ГОТОВИТСЯ/ГОТОВ/Выдать), модификаторы +/БЕЗ.
- **Perf:** preload `order_status_logs`; `Barista::DashboardHelper`.
- **Артефакты:** `b21_stage1_card_ui_2026-06-10.json`, скрины stage1_*.

## v1.165 — 2026-06-10 (B2.2 ТЗ: меню + создать бариста)

- **ТЗ:** `B2_2_barista_menu_create_merge.md` — полный текст заказчика, этапы 0–5, маппинг кода.
- **Этап 0:** `b22_stage0_mapping_2026-06-10.json`; baseline Fly + 2 макета в `screenshots/b22_menu_create_merge_2026-06-10/`.
- **Ops:** CBR, CHECKLIST §B2, SESSION_STATE, customer_tasks README.

## v1.164 — 2026-06-10 (B2.1 ТЗ: табло бариста + B2.2 заготовка)

- **ТЗ:** `B2_1_barista_order_board.md` — MVP scope, этапы 0–5, маппинг кода.
- **Заготовка:** `B2_2_barista_menu_create_merge.md`.
- **Ops:** CBR, CHECKLIST §B2, SESSION_STATE, `b21_stage0_mapping_2026-06-10.json`.

## v1.163 — 2026-06-10 (B1.7 BR-fixes: промокод и наличные с checkout)

- **Fix:** `Checkout.svelte` — BR-1 промокод, BR-2 наличные.
- **Артефакты:** `b17_br_fixes_2026-06-10.json`, MCP скрин.

## v1.162 — 2026-06-10 (B1.1 закрытие: Firebase secrets на Fly + приёмка)

- **Fly:** `FIREBASE_*` secrets (FCM HTTP v1); smoke `push_register` PASS.
- **Ops:** `config/secrets/` + gitignore; `bin/fly_firebase_secrets.sh`, `bin/minify_firebase_env.rb`, `bin/b11_mcp_fly_verify.sh`.
- **MCP Fly:** `b11_mcp_fly_2026-06-10.json` PASS (catalog, SW, bundle, meta).
- **Тесты:** B1.1 suite 21 runs PASS.
- **Доки:** B1.1 заказчик `[x]` в CBR + customer_tasks; `b11_acceptance` обновлён.

## v1.161 — 2026-06-10 (B1.1 push: FCM v1 + регистрация в витрине)

- **API:** `POST /shop/api/push/register`.
- **FCM HTTP v1:** `FcmClient`, `FirebaseConfig`, service worker.
- **Витрина:** `firebasePush.js`, кнопка на экране статуса.
- **Док:** `docs/operations/dev/FIREBASE_PUSH.md`.
- **Smoke:** `push_register` в `bin/b11_order_status_fly_smoke.rb`.

## v1.160 — 2026-06-10 (B1.1 этап 5: push + WS session + приёмка)

- **Push:** `OrderStatusPushNotifier`, `PushNotification`, `SendPushNotificationJob`, `FcmClient`.
- **WS:** подписка по customer session без `reconnect_token` (история заказов).
- **ТЗ:** убраны кухня/доставка; цепочка витрина → бариста; приёмка заказчика `[x]`.
- **Тесты:** B1.1 suite 20 runs PASS; deploy develop на Fly.

## v1.159 — 2026-06-10 (B1.1 этап 4: приёмка + Fly/MCP)

- **Тесты:** `order_status_acceptance_cbr_test` (7 критериев B1.1).
- **Скрипт:** `bin/b11_order_status_fly_smoke.rb`.
- **Артефакты:** `b11_acceptance_2026-06-10.json`, `b11_mcp_fly_2026-06-10.json`, MCP скрины.
- **Fly:** B1.1 не на проде — deploy pending; внутр. приёмка PASS.

## v1.158 — 2026-06-09 (B1.1 этап 3: отмена заказа гостем)

- **API:** `POST /shop/api/orders/:id/cancel`; `GuestOrderCancellationService`.
- **Модель:** `Order#guest_can_cancel?` — до `preparing`/`ready`.
- **UI:** кнопка отмены, сообщения guest/kitchen; presenter в API/WS.
- **Тесты:** guest cancel service + integration.

## v1.157 — 2026-06-09 (B1.1 этап 2: WebSocket статуса заказа)

- **Cable:** `Shop::GuestOrderChannel`, `GuestOrderBroadcaster`; гостевое подключение без user_id.
- **Триггеры:** бариста status/cancel, payment callback, cash order.
- **Витрина:** `shopOrderCable.js`, live update на `OrderStatus.svelte`.
- **Тесты:** channel + broadcaster.

## v1.156 — 2026-06-09 (B1.1 этап 1: экран статуса заказа)

- **Витрина:** `OrderStatus.svelte`, маршрут `#/order/:id`, `orderStatusProgress.js`.
- **API:** `GET /shop/api/orders/:id` — `order_number`, `tenant`, `payment_settled`.
- **Редиректы:** checkout (наличные), payment-result (успех), список заказов.
- **Артефакт:** `b11_stage1_static_ui_2026-06-09.json`.

## v1.155 — 2026-06-09 (B1.1 этап 0: маппинг статусов)

- **B1_1_order_status_progress.md:** план этапов 0–4; маппинг `pending_payment` → `accepted` → `preparing` → `ready`; UI из макетов; расхождение use case заказчика.
- **Артефакт:** `b11_stage0_mapping_2026-06-09.json`; `screenshots/b11_order_status_2026-06-09/README.md`.

## v1.154 — 2026-06-09 (ТЗ заказчика → customer_tasks/)

- **Новое:** `requirements/customer_tasks/` — отдельный `.md` на задачу (B1.7 checkout, B1.1 прогресс-бар).
- **CBR:** индекс и последовательность; полные тексты перенесены в `customer_tasks/`.
- **task-workflow:** старт сессии читает `customer_tasks/` для активного ТЗ.

## v1.153 — 2026-06-09 (правила: коммит всегда, отчёт Сделано/Не сделано)

- **Усилено:** `coffeeos-commit-ops.mdc` — commit обязателен до отчёта; список запрещённых формулировок («коммитить?» и т.п.).
- **Отчёт:** `coffeeos-task-workflow.mdc` — единый формат таблицы **Сделано | Не сделано**.
- **Синхрон:** `.cursorrules`, `AGENTS.md`, `RULES_INDEX`, `HANDOFF`, `SESSION_STATE`, `demo-feedback/README`, `AGENTS/git.md`.

## v1.152 — 2026-06-08 (правила: гармонизация workflow + project + доки)

- **Новое:** `docs/operations/RULES_INDEX.md`, `.cursor/rules/coffeeos-index.mdc`.
- **Синхрон:** `AGENTS.md`, `.cursorrules` с `commit-ops` (push по апруву, SESSION_STATE каждый шаг).
- **Symlinks:** `.cursor/rules/coffeeos-*.mdc` → `project/` для Cursor и старых путей.
- **Доки:** ссылки `project/coffeeos-*` в PRACTICES, HANDOFF, ISSUES, db/README.

## v1.151 — 2026-06-08 (корень: tmp_* → scripts/scratch)

- **Уборка:** 19 одноразовых `tmp_*` из корня → `scripts/scratch/`; `.gitignore` + `.keep`.
- **`.cursorrules`:** индекс на `workflow/`; коммит всегда, push по апруву; scratch не в корне.

## v1.150 — 2026-06-08 (task-workflow: go, тесты, честный отчёт)

- **Новое:** `coffeeos-task-workflow.mdc` — старт сессии, CHECKLIST/CBR, go, обязательные тесты, честный отчёт, backlog.
- **Обновлено:** `coffeeos-agent-workflow.mdc` — краткий индекс → task-workflow.

## v1.149 — 2026-06-08 (repo-layout: структура репозитория)

- **Новое:** `coffeeos-repo-layout.mdc` — куда класть код/docs, зеркало test/, переносы с go, README sync.
- **Обновлено:** `coffeeos-agent-workflow.mdc` — ссылка на repo-layout.

## v1.148 — 2026-06-08 (dev-gates: DoD, регрессия, hot-path)

- **Новое:** `coffeeos-dev-gates.mdc` — приоритет правил, DoD (CHECKLIST/CBR), регрессия по зонам Rails, hot-path, migration/API gate.
- **Обновлено:** `coffeeos-agent-workflow.mdc` — ссылка на dev-gates.

## v1.147 — 2026-06-08 (commit-ops: всегда git commit + ops)

- **Новое:** `coffeeos-commit-ops.mdc` — канон: commit + SESSION_STATE всегда; CHANGELOG + HANDOFF в конце шага; push только по апруву.
- **Обновлено:** `coffeeos-agent-workflow.mdc` — убран «коммит по просьбе», ссылка на commit-ops.

## v1.146 — 2026-06-08 (правила агента: workflow + project)

- **Структура:** `.cursor/rules/workflow/` + `.cursor/rules/project/`; 8× `coffeeos-*.mdc` перенесены из корня rules.
- **Новое:** `coffeeos-agent-workflow.mdc` (порядок шага, ops), `coffeeos-file-size-split.mdc` (лимиты 50/120/200, сплит по панелям).
- **Ops:** SESSION_STATE, HANDOFF обновлены.
- **Не в коммите:** правка `CUSTOMER_BUSINESS_REQUIREMENTS.md` (unstaged, отдельно).

## v1.145 — 2026-06-06 (W1.4 PASS — апрув заказчика, волна 4 закрыта)

- **Апрув:** сверка категорий vitrina = barista; Fly FULL A+B; CBR/CHECKLIST W1.4 `[x]`.
- **Волна 4 W1.1–W1.4:** закрыта; следующий фокус — **блок 2** табло.
- **Backlog:** barista стоп-лист UI; kiosk.

## v1.144 — 2026-06-06 (W1.4 Fly FULL sync A+B — на апрув)

- **Fly MCP:** tenant A+B — полная сверка shop `/api/categories` vs barista `/menu` (5 кат, 18 товаров, diffs=[]).
- **Ops:** MCP JSON обновлён; W1.4 `[ ]` до апрува; стоп-лист UI — backlog.

## v1.143 — 2026-06-06 (W1.4 сверка категорий — на апрув)

- **Код:** `Shop::Catalog.tenant_menu`; barista menu/POS → тот же scope, что витрина; shop categories → `Category.active`.
- **Тест:** `uk_menu_w14_category_sync_test.rb` (3 tests, 38 assertions); barista regression sold_out обновлён.
- **Fly:** spot-check `W12-FLY-0606` shop API = barista menu — PASS.
- **Не в scope:** полный audit demo-каталога, tenant B, deploy Fly, UI стоп-листа.
- **Ops:** MCP [`mcp_w14_category_sync_fly_2026-06-06.json`](../milestones/veha_2/artifacts/demo-feedback/mcp_w14_category_sync_fly_2026-06-06.json); CBR/CHECKLIST W1.4 `[ ]` до апрува.

## v1.142 — 2026-06-06 (W1.3 post-deploy: корзина Hot + polling 179₽)

- **Fly MCP post-deploy:** UK curl → Hot/Iced в `W13-REQ-SIZE`; vitrina happy path Hot → корзина (`W12-PHOTO-001` 299₽).
- **Polling:** `W12-PLAIN-001` **179₽** на vitrina A без F5; скрины `w13_cart_hot_happy_fly_2026-06-06.png`, `w12_polling_price_179_fly_2026-06-06.png`.
- **Ops:** MCP [`mcp_w13_required_modifiers_fly_2026-06-06.json`](../milestones/veha_2/artifacts/demo-feedback/mcp_w13_required_modifiers_fly_2026-06-06.json) обновлён; SESSION_STATE → W1.4.

## v1.141 — 2026-06-06 (W1.3 обяз. модификаторы + хвосты W1.2)

- **W1.3:** Fly MCP — `W13-REQ-SIZE` is_required, vitrina блокирует «В корзину»; test `uk_menu_w13_required_modifiers_test.rb`.
- **W1.2 хвосты:** модификаторы + FILE upload на Fly, vitrina B DOM; MCP [`mcp_w13_required_modifiers_fly_2026-06-06.json`](../milestones/veha_2/artifacts/demo-feedback/mcp_w13_required_modifiers_fly_2026-06-06.json).
- **Fix:** `Platform::MenuController#update_product` → `bust_shop_catalog_cache!`.
- **Ops:** CBR W1.3 `[x]`, CHECKLIST § B2B, SESSION_STATE → W1.4.

## v1.140 — 2026-06-06 (W1.2: MCP УК → меню → витрина)

- **Сценарий:** категория `W12-FLY-0606` + `W12-PHOTO-001` (299₽, фото URL) + `W12-PLAIN-001` (149₽) на Fly; API витрин A/B; DOM витрина A.
- **Тест:** `test/integration/platform/uk_menu_w12_vitrina_test.rb` — полный HTTP-поток включая PNG upload и optional модификаторы.
- **Ops:** CBR W1.2 `[x]`, CHECKLIST § B2B, MCP [`mcp_w12_uk_menu_vitrina_2026-06-06.json`](../milestones/veha_2/artifacts/demo-feedback/mcp_w12_uk_menu_vitrina_2026-06-06.json).
- **Хвост W1.2:** модификаторы на Fly через браузер не добавлены (MCP scroll); обязательные модификаторы — **W1.3**.

## v1.139 — 2026-06-06 (W1.1: цена manager → витрина)

- **Баг:** после смены цены в `/manager/menu` витрина показывала старую цену до 5 мин (кэш `shop/categories/...`).
- **Fix:** `Manager::MenuController#update_price` → `ProductTenantSync.bust_shop_catalog_cache!(tenant_ids: …)`; сброс ключей с `page=nil`.
- **Тест:** `test/integration/manager/menu_price_vitrina_cache_test.rb`.
- **Ops:** CBR W1.1 `[x]`, CHECKLIST § B2B, SESSION_STATE → W1.2.

## v1.138 — 2026-06-06 (CBR: три потока, траектория, волна 4)

**Зачем:** фиксируем **канон потоков** (приём → обработка → тест-приёмка), **как шли** (§2.3 → 2A → витрина), **северную звезду** (PDF 56 стр.), чтобы новые вводные не стирали курс.

**Документы:**
- [`requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md`](../milestones/veha_2/requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md) — три потока, траектория волн 0–5, W1.1–W1.5
- [`checklists/CHECKLIST.md`](../milestones/veha_2/checklists/CHECKLIST.md) — § B2B поток 1
- [`session/SESSION_STATE.md`](../session/SESSION_STATE.md) — фокус W1.1

**Следующий код:** W1.1 баг цены на витрине.

## v1.137 — 2026-06-06 (ops docs: навигация — папки вместо «простыни»)

**Зачем:** в `docs/operations/` и `milestones/veha_*` торчало 40+ файлов в корне — непонятно где CHECKLIST, CBR, runbook, demo. Агенты и люди терялись; в корне репо скапливался мусор `tmp_*` от сессий.

**Что сделано:**
- **veha_1 / veha_2:** `checklists/`, `requirements/`, `runbooks/`, `qa/`, `reference/` (+ README в подпапках).
- **operations:** `session/` (SESSION_STATE, HANDOFF), `journal/` (CHANGELOG), `demo/`, `dev/`, `reference/`; в корне только `ISSUES.md` + `README.md`.
- **`milestones/PATH_MAP.md`** — таблица старых путей → новых (без stub-файлов).
- **`bin/README.md`**, **`db/README.md`** — что где в скриптах и миграциях.
- **`tmp_pdf_pages/`** → `artifacts/demo-feedback/_source/pdf_pages/`; `.gitignore` для `/tmp_*`.
- Ссылки обновлены: AGENTS, `.cursorrules`, product, rake, milestones, CHANGELOG.

**Точка входа:** [`operations/README.md`](../README.md) · [`session/SESSION_STATE.md`](../session/SESSION_STATE.md) · [`veha_2/checklists/CHECKLIST.md`](../milestones/veha_2/checklists/CHECKLIST.md).

## v1.136 — 2026-06-06 (§2A.4 PASS — блок 2A закрыт)

- Апрув заказчика: 2A.4 транзакции точки → `[x]` PASS.
- **Блок 2A полностью закрыт** (2A.1–2A.4). Следующий фокус: **Блок 2** табло баристы.

## v1.135 — 2026-06-06 (§2A.4: транзакции точки — payments для УК)

- `Platform::TenantTransactionsOverview` + `/admin/monitoring/:id/transactions` (HTML + JSON).
- Фильтры status/method; сводка; T-Bank PaymentId; блок отказов; ▸ JSON.
- JSON API: `/health/tenants/:id/transactions`. **2A.3 → PASS. 2A.4 на апрув.**

## v1.134 — 2026-06-06 (§2A.3: сессии точки — кто онлайн, все пользователи)

- `Auth::SessionTracker` — запись активных сессий в таблицу `sessions` при login/logout.
- `LoginJournal` — `context_tenant_id` (точка менеджера / franchise).
- `/admin/monitoring/:id/sessions` — сводка ролей, онлайн, все пользователи + последний вход, лента входов, ▸ JSON.
- Ссылки «Сессии» в мониторинге. **2A.3 на апрув.**

## v1.133 — 2026-06-06 (§2A.3 UX: человеческая лента + раскрывающийся JSON)

- Лента мониторинга: понятный текст + **▸ JSON** на строку.
- `/admin/session` — HTML «Моя сессия»; JSON через `?format=json`.
- Nav: «Моя сессия». Commit `bd130e2`. **2A.3 на апрув.**

## v1.132 — 2026-06-06 (§2A.3: логин / user ID — на апрув)

- Nav УК: email + user id + Session JSON `/admin/session`.
- `Auth::LoginJournal`: audit входа/выхода с user_id, email, role.
- Event feed: actor_id/email в audit payload.
- 2A.2 → `[x]` PASS. Commit `123c059`.

## v1.131 — 2026-06-06 (§2A.2: журнал событий — на апрув)

- `Health::TenantEventFeed`: детали под checks + unified feed для UI и ИИ-агента.
- JSON: `/health/tenants/:id/events`, show дополнен `check_details`.
- UI drill-down: таблицы + единая лента 24ч.
- 2A.1 → `[x]` PASS. Commit `d46e3ed`.

## v1.130 — 2026-06-06 (§2A.1: мониторинг точек УК — на апрув)

- UI `/admin/monitoring` — сводка + drill-down; nav «Мониторинг точек».
- `Health::TenantChecker`: pending_payment, shop_vitrina, audit events.
- Rake `fly:health_smoke`; MCP + скрины Fly prod.
- Commit `72afacc`. **Статус 2A.1:** `[~]` до апрува заказчика.

## v1.129 — 2026-06-06 (§2.3 закрыт: апрув заказчика + этап 5.3)

- Апрув §2.3; 5.3 PASS — [`mcp_section_2_3_stage5_3_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage5_3_2026-06-06.json).
- Fix test: webhook REJECTED → order `cancelled` (PaymentFailureJournal).
- Retest Fly: `fly:callback_smoke`, `fly:stage5_2_smoke` PASS.
- Deploy: `deployment-01KTE3QZ9XNPXM62HZD5C01JB6`.
- **Следующий фокус:** блок 2 — табло баристы.

## v1.128 — 2026-06-06 (§2.3 этап 5.3: сводка на апрув заказчика)

- «Итог §2.3» + «Закрытие §2.3» в CBR — **§2.3 не закрыт** до апрува.
- MCP: [`mcp_section_2_3_summary_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_summary_2026-06-06.json).
- DEMO_FEEDBACK: §2.3 итог, fix устаревших «не гоняли».

## v1.127 — 2026-06-06 (§2.3 этап 5.2: «Заказы за сегодня» после оплаты)

- E2E-тест: accepted card-заказ в `GET /orders/history?today=1` (17 assertions).
- Rake `fly:stage5_2_smoke` — prod PASS, order `72801b25-…`, deploy `01KTE2SYJK31BGHHRVWQ9AH9Z2`.
- MCP: [`mcp_section_2_3_stage5_2_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage5_2_2026-06-06.json).

## v1.126 — 2026-06-06 (§2.3 этап 5.1: оплата → webhook → accepted)

- Интеграционный тест `qa_section_2_3_stage5_e2e_test.rb`: cart → card order → CONFIRMED callback → finalize.
- Fly smoke PASS: `fly:callback_smoke` order `05c99c7e-…` → `accepted`, payment `succeeded`.
- MCP: [`mcp_section_2_3_stage5_1_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage5_1_2026-06-06.json).

## v1.125 — 2026-06-06 (§2.3 этап 4.5: журнал отказов оплаты)

- `Shop::PaymentFailureJournal` — guest abandon, FailURL, webhook REJECTED.
- Менеджер: инциденты + история статусов заказа; УК: `health/tenants` → `recent_events`.

## v1.124 — 2026-06-06 (§2.3: оболочка CoffeeOS на экране оплаты)

- `Payment.svelte` — intro в стиле витрины, маска T-Pay/SberPay, тёмный iframe-host.
- `payment_method` в сессии оплаты; `setTheme(dark)` до mount.
- Deploy `01KTE0P9PZSVF3YNJYEMC1DVXX`, commit `7a0533c`.

## v1.123 — 2026-06-06 (§2.3 этап 4.2: integration.js PASS)

- `tbankPayment.js` — официальный API: `iframe.create` + `mount(PaymentURL)`; `integrationjs.tbank.ru`.
- CSP `frame-src` для `*.tbank.ru`; fallback embed PaymentURL сохранён.
- MCP PASS + скрин: [`stage4_payment_iframe_2026-06-06.png`](milestones/veha_2/artifacts/demo-feedback/screenshots/stage4_payment_iframe_2026-06-06.png), [`mcp_section_2_3_stage4_2026-06-06.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage4_2026-06-06.json).

## v1.122 — 2026-06-05 (§2.3 этап 4: iframe оплата на витрине)

- Экран `/payment` вместо полного редиректа; `integration.js` + fallback embed `PaymentURL`.
- API: `provider_payment_id`, `payment_iframe`, `GET /shop/api/config`; CSP для доменов T-Bank.
- Кнопка «Отмена», `PaymentResult` status=cancel; MCP JSON stage4.

## v1.121 — 2026-06-04 (§2.3 этап 3: оформление UX)

- `shopGuestProfile.js` — имя/телефон в localStorage; компактный блок на повторном заказе.
- Checkout/Cart/PaymentResult — шаги пути, «назад» в корзину, «История» на fail.
- MCP PASS: [`mcp_section_2_3_stage3_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage3_2026-06-04.json).

## v1.120 — 2026-06-04 (§2.3 этап 2: заказ виден после банка)

- `Shop::GuestOrderReconnect` + `POST /shop/api/session/reconnect` + `reconnect_token` в ответе создания заказа.
- Frontend: `shopGuestSession.js`, восстановление сессии в PaymentResult / Orders / App / Checkout.
- MCP PASS: [`mcp_section_2_3_stage2_2026-06-04.json`](milestones/veha_2/artifacts/demo-feedback/mcp_section_2_3_stage2_2026-06-04.json), deploy `01KTC026K62C7QHT6JC3VRKNRS`.

## v1.119 — 2026-06-04 (§2.3 чеклист этапы 1–5, синхронизация ops)

- [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](milestones/veha_2/requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md) — чеклист §2.3 (MCP → код → iframe → полная оплата); контекст PDF vs prog10 vs DEMO_FEEDBACK.
- [`../session/SESSION_STATE.md`](../session/SESSION_STATE.md), [`DEMO_FEEDBACK.md`](milestones/veha_2/requirements/DEMO_FEEDBACK.md) — честный статус: старые done ≠ новая работа заказчика.

## v1.118 — 2026-06-04 (бизнес-требования заказчика после прогонки)

- [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](milestones/veha_2/requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md) — перепись требований заказчика (витрина / табло / обратная связь); ссылка на PDF 56 стр.

## v1.117 — 2026-06-04 (УК→витрины: PTS, polling 8s, handoff)

- **Код:** `589e397` PTS на все точки + API categories `per_page=50`; `e398981` polling витрины 8s без F5; `1861f4f` PTS sync вне TX publish.
- **Fly:** автообновление A/B **PASS**; `OPS-POSTDEPLOY-001` на API A/B после create в браузере.
- **Ops:** [`HANDOFF_UK_MENU_VITRINA.md`](milestones/veha_2/runbooks/HANDOFF_UK_MENU_VITRINA.md), MCP `mcp_uk_menu_autorefresh_fly_2026-06-04.json`, `SESSION_STATE` обновлён.

## v1.116 — 2026-06-04 (ops: DEMO_FEEDBACK sync + franchise staff MCP)

- Синхронизация `DEMO_FEEDBACK`, `SESSION_STATE`, `CHECKLIST` §E — убраны устаревшие «ждём deploy» / «open franchise».
- MCP Fly franchise staff **PASS** — артефакт `mcp_franchise_staff_fly_2026-06-04.json`; код `7311338`, `62ced8e`.

## v1.115 — 2026-06-04 (§2: A↔B fix, онбординг, подвал MCP)

- **A↔B:** `CustomerSession` не отдаёт legacy на чужой tenant; подпись в «Заказы»; MCP+БД **PASS**.
- **Онбординг:** баннер + подсветка обязательных модификаторов в `Product.svelte`.
- **§2.5:** MCP Slow 3G + Offline in-app; подвал физически не гоняли.

## v1.114 — 2026-06-04 (§2.5: MCP после deploy ca6f2ef — skeleton не залипает)

- Fly Slow 3G: `boot_with_menu: 0`, финал без `.shop-boot-skeleton` — **PASS**.
- Артефакт `mcp_section_2_5` — 3 прогона; §2.5 полностью закрыт (подвал не в scope).

## v1.113 — 2026-06-04 (§2.5 post-deploy MCP + fix boot skeleton)

- Post-deploy MCP Slow 3G **PASS**: `.shop-boot-skeleton` на Fly, фон `#1a1a1a`.
- Fix: `application.js` — `replaceChildren()` перед mount (boot skeleton не залипал).
- Подвал: не гоняли (только DevTools).

## v1.112 — 2026-06-04 (§2.5: медленный интернет — витрина)

- MCP Slow 3G **PASS**: скелетон при загрузке меню, тёмный фон (не белый экран).
- Boot skeleton в HTML до гидрации Svelte; `DEMO_FEEDBACK` §2.5 → done.

## v1.111 — 2026-06-04 (§2.4: MCP Fly — двойной «Оплатить»)

- MCP §2.4 **PASS**: повторный клик blocked, один редирект на Т-Банк.
- Артефакт: `mcp_section_2_4_fly_2026-06-04.json`; `DEMO_FEEDBACK` §2.4 → done.

## v1.110 — 2026-06-04 (§2.3: оплата витрина — корзина после банка)

- **Fix:** корзина не очищается до успешной оплаты; return URL `/payment/success|fail`; abandon/finalize API; идемпотентность pending-заказа.
- **Fly deploy** + MCP §2.3 **PASS** (ФИО, «Идёт оплата…», корзина после Т-Банка).
- **Хвост:** успех оплаты + история без реальной оплаты в MCP.

## v1.109 — 2026-06-03 (ops handoff: УК/staff, онбординг обязательно)

- `DEMO_FEEDBACK`: заказчик **УК vs franchise** (staff); подсказки онбординга — **open, обязательно**.
- `SESSION_STATE`: актуальная шапка; §2.2 MCP PASS; внутренний апрув без ожидания PDF на каждый шаг.

## v1.108 — 2026-06-03 (§2.2: MCP Fly PASS — платные модификаторы)

- MCP Fly после redeploy: +15/+20/+40 на карточке; кордиал +20 → корзина **199₽** — **PASS**.
- `DEMO_FEEDBACK` §2.2 → `done *(MCP)*`; апрув заказчика — pending.

## v1.107 — 2026-06-03 (§2.2: платные модификаторы на витрине)

- Демо Бразилия: модификаторы **+15 / +20 / +40 ₽** (миграция + `demo:seed` repair).
- UI: метка «· обязательно» на обязательных группах; корзина показывает `(+N₽)`.
- Тесты: `qa_section_2_2_modifiers_test`. MCP Fly — после redeploy.

## v1.106 — 2026-06-03 (post-deploy MCP: §E долг закрыт на Fly)

- После deploy: MCP batch **PASS** — витрина A↔B, franchise, смена §1.3, подпись GM, склад §1.4.
- Артефакт: `mcp_post_deploy_fly_2026-06-03.json`; `DEMO_FEEDBACK` — `done *(MCP post-deploy)*` для §2/§3.6/§1.3/§1.4.
- Следующий scope витрины: **§2.2** (`open`).

## v1.105 — 2026-06-02 (§2.1: MCP Fly — витрина меню)

- MCP Fly §2.1: каталог → категория «Черный» → карточка **Фильтр-кофе Бразилия** (179₽, модификаторы) — **PASS**.
- `DEMO_FEEDBACK` §2.1 → **done**; артефакт `mcp_section_2_1_fly_2026-06-02.json`.

## v1.104 — 2026-06-03 (§1.4: MCP Fly — списание на точке, не в цехе)

- MCP Fly §1.4: продажа бариста A → остаток **точки** beans 3992→3974; **цех** без изменений.
- Обновлён plain-сценарий §1.4: смотреть **`gm-a` → Склад**, не только `pk-manager`.
- Артефакт: `veha_2/artifacts/demo-feedback/mcp_section_1_4_fly_2026-06-03.json`.

## v1.103 — 2026-06-02 (§1.3: открытие/закрытие смены в UI)

- **Смена:** `CashShifts::OpenService`; кнопки **Открыть/Закрыть** (бариста + менеджер); плашка «Смена открыта/закрыта» в шапке.
- **Демо:** `demo:seed` больше не открывает смену A автоматически — закрывает A/B для ручного сценария §1.3.
- **Тесты:** `qa_section_1_3_shift_flow_test`, `open_service_test`.
- §1.3 до апрува заказчика; MCP Fly — после deploy.

## v1.102 — 2026-06-02 (§1.2 GM isolation + role label)

- **Manager UI:** `general_manager` в шапке `/manager` — **«Управляющий точки»** (не «Офис-менеджер»).
- **Тесты:** `qa_section_1_2_gm_isolation_test` — 3 шага PDF §1.2; office panel — ожидание новой подписи.
- **MCP Fly:** артефакт `veha_2/artifacts/demo-feedback/mcp_section_1_2_fly_2026-06-02.json` — изоляция **PASS**; подпись на Fly после deploy.
- §I вехи **не закрыта**; §1.2 — до апрува заказчика.

## v1.101 — 2026-06-02 (V2 §E: фидбек PDF + shop/franchise fixes)

- PDF прогонка §1–3 → `veha_2/artifacts/demo-feedback/`; очередь [`DEMO_FEEDBACK.md`](milestones/veha_2/requirements/DEMO_FEEDBACK.md).
- **Shop:** `Shop::CustomerSession` — customer_id в сессии **по tenant_id** (фикс «пропал заказ» при A↔B).
- **Franchise:** `organization_id` при создании из УК; `demo:seed` чинит franchise без org; login — приоритет роли.
- §I вехи **не закрыта**; UI/оплата из PDF — в очереди `open`.

## v1.100 — 2026-06-02 (V2 ops: реорганизация артефактов прогона 10)

- Плоский `veha_2/artifacts/prog10_*` → дерево `artifacts/prog10/{_index,smoke,kiosk,shop,staff-rbac,connectivity,platform-ent,warehouse}/`.
- README: `artifacts/README.md`, `artifacts/prog10/README.md`, `artifacts/demo-feedback/README.md` (§E).
- Индекс: `prog10/_index/prog10_final_index.json` (пути относительно `prog10/`).
- Ссылки в QA/PRACTICES/POSTMORTEM/PROG10_TENANTS + `bin/prog10_*` OUT.
- **Код/тесты не менялись.** Веха 2 §I по-прежнему не закрыта.

## v1.99 — 2026-06-02 (SEC-07 → Веха 3)

- **V3-SEC-07:** убрать `shop-api-key` из meta витрины — [`veha_3/CHECKLIST.md`](milestones/veha_3/CHECKLIST.md) § E.
- В2 блок 4: SEC-07 закрыт как перенос (demo Fly OK).

## v1.98 — 2026-06-02 (gate: тесты 562/0, Fly ops — веха не закрыта)

- Перегон `bin/rails test` WSL: **562/0**.
- Fly deploy + verify secrets — владелец (агент без token).
- SEC-07 (API key в meta витрины) — явная задача в CHECKLIST блок 4, backlog после В2.
- **Веха 2 официально не закрыта.**

## v1.97 — 2026-06-02 (V2 прогон 10 — блок 14 postmortem)

- Postmortem § «Прогон 10» в `POSTMORTEM_2026-05-28.md`.
- Блоки **0–14** прогона 10 закрыты в CHECKLIST/QA; §I веха — после §E + живого демо.

## v1.96 — 2026-06-02 (V2 прогон 10 — блок 13 финал)

- Перепрогон Fly: curl **9×**, stress **8+8**, kiosk **9×** — `prog10/_index/prog10_final_block13.json`.
- Индекс артефактов `prog10/_index/prog10_final_index.json`; хвосты PASS/SKIP в QA §10d.

## v1.95 — 2026-06-02 (V2 прогон 10 — блок 12 склад)

- Блок 12 закрыт: barista↔цех e2e (`prog10/warehouse/prog10_warehouse_block12.json`).
- Тесты: `prep_kitchen_movements_test` + `onboarding_connectivity_test` → **6/50/0**.
- Зафиксирован backlog `V2-BACKLOG-PREP-MULTI`: общий цех на несколько точек — после В2 (Веха 3).

## v1.94 — 2026-06-02 (V2 прогон 10 — блок 11 связность)

- CON-02…06: тесты + Fly CON-02 + артефакт `prog10/_index/prog10_connectivity.json`.
- Backlog: `V2-BACKLOG-PREP-MULTI` (цех на N точек — после В2).
- Апрув блока 3 → блок 11; ждём апрув 11 → блок 12.

## v1.93 — 2026-06-02 (V2 прогон 10 — блок 3 закрыт)

- **CR-05:** Fly `POST /kiosk/api/auth` **9/9** — `prog10/kiosk/prog10_kiosk_auth_fly_cr05.json`, `bin/prog10_kiosk_auth_fly_verify.rb`.
- **CR-04:** wontfix на Fly 1 pod; при multi-pod / смене хостинга → Redis — `PRACTICES`.
- Push `develop` (23 коммита); `fly deploy` — владелец (`flyctl auth login`).

## v1.92 — 2026-06-02 (V2 прогон 10 — блок 3, CR-05 kiosk GUC)

- `Kiosk::Api::AuthController`: `SET LOCAL app.current_tenant_id` перед загрузкой `KioskSetting`.
- Тесты kiosk auth **7/0**; CR-04 CacheCounter — open.

## v1.91 — 2026-06-02 (V2 прогон 10 — блок 10 добивка)

- Mock **card** на 5 точках: curl + MCP (`prog10_shop_vitrina_card_*`).
- **SHP-03/05:** `/shop` без tenant_id — curl + MCP (`prog10_shop_shp03*`).
- Дальше: апрув 10 → блок 3 (CR-05); `source=kiosk` — V2-P10-08 позже.

## v1.90 — 2026-06-02 (V2 прогон 10 — блок 10, витрина 5 точек)

- curl **5/5:** меню, корзина, cash checkout, SHP-09 history API (`prog10/shop/prog10_shop_vitrina_curl.json`).
- MCP Puppeteer **5/5:** UI vitrina + история заказов (`prog10/shop/prog10_shop_vitrina_mcp.json`).
- Блок **9** ✅ + mock card (`prog10/kiosk/prog10_kiosk_barista_card.json`); блок **11** — после апрува.

## v1.89 — 2026-06-02 (V2 прогон 10 — блок 9, kiosk → barista ×9)

- curl **9/9:** киоск auth + cash order `accepted` + заказ на табло barista (`prog10/kiosk/prog10_kiosk_barista.json`, `bin/prog10_kiosk_barista.rb`).
- MCP Puppeteer **9/9:** login barista → `/barista`, заказ на доске (`prog10/kiosk/prog10_kiosk_barista_mcp.json`).
- Блок **8** ✅ после апрува; блок **10** — после апрува.

## v1.88 — 2026-06-02 (V2 прогон 10 — ENT-02 clipboard verify)

- ENT-02: реальная проверка буфера после «Копировать» + Ctrl+V (`prog10/platform-ent/prog10_ent02_clipboard.json`).

## v1.87 — 2026-06-02 (V2 прогон 10 — блок 8, ENT карточка УК)

- MCP: ENT-02, ENT-07, ENT-08 на demo-a — PASS 3/3 (`prog10/platform-ent/prog10_ent_card_mcp.json`).
- Блок 7 отмечен ✅ после апрува заказчика.
- Блок 8 — ждём апрув перед блоком 9.

## v1.86 — 2026-06-02 (V2 прогон 10 — блок 7, MCP 9 точек + STF-03)

- MCP Puppeteer: **9/9** точек — STF-01/02/04 на 9, **STF-03** (создание barista) на всех 9.
- `demo-prep`: barista-модуль ожидаемо недоступен (probe `GET /barista` не отдаёт панель barista).
- Артефакты: `prog10/staff-rbac/prog10_staff_mcp_9pt.json`, `prog10/staff-rbac/prog10_staff_mcp_9pt.md`.
- Блок 7 техготов, ждём апрув перед блоком **8**.

## v1.85 — 2026-06-02 (V2 прогон 10 — блок 7, MCP 6 точек + STF-03)

- MCP Puppeteer: **6/9** точек — STF-01/02, **STF-03** (создание barista ×6), STF-04 (login новых ×6).
- Артефакты: `prog10/staff-rbac/prog10_staff_mcp_6pt.json`, `prog10/staff-rbac/prog10_staff_mcp_6pt.md`.
- Блок 7 в QA — **не закрыт** (3 точки только curl; апрув перед блоком 8).

## v1.84 — 2026-06-02 (V2 прогон 10 — блок 7, MCP STF 3 org)

- MCP UI на Fly: **3 org** (Demo/Alpha/Beta) — STF-01/02/04 + изоляция заказа в браузере (own `200`, foreign `404`).
- Артефакты: `prog10/staff-rbac/prog10_staff_mcp_3org.json`, `prog10/staff-rbac/prog10_staff_mcp_3org.md`.
- curl 9/9 без изменений (`prog10/staff-rbac/prog10_staff_isolation.json`); STF-03 UI и 6 оставшихся точек в браузере — вне scope.

## v1.83 — 2026-06-02 (V2 прогон 10 — блок 7, staff/rbac isolation)

- Добавлен `bin/prog10_staff_rbac_isolation.rb` для проверки изоляции staff/RBAC по 9 точкам.
- Артефакты: `prog10/staff-rbac/prog10_staff_isolation.json` + `prog10/staff-rbac/prog10_staff_isolation.md` (PASS 9/9).
- Изоляция подтверждена: own order `200`, foreign order `404`; prep-tenant barista доступ ожидаемо закрыт (`302`).

## v1.82 — 2026-06-02 (V2 прогон 10 — блок 6, staff wizard)

- Карточка точки УК: добавлен wizard «первая команда» с шаблоном логинов (role/email/panel).
- `EntryPoints` теперь отдаёт `team_template` для sales point и production kitchen.
- `STAFF_ACCESS.md`: закрыты пункты wizard + лист логинов новой org.
- Тесты: `entry_points_test` **7/0**; полный suite **561/2318/0**.

## v1.81 — 2026-06-02 (V2 прогон 10 — блок 5, gate кода)

- Полный `bin/rails test` в WSL: **559/2311/0**.
- Блок 5 отмечен выполненным в `QA_ACCEPTANCE_RUN.md`.
- Синхронизированы статусы CR/gate в `PRACTICES.md` и `CODE_REVIEW.md`.

## v1.80 — 2026-06-02 (V2 прогон 10 — блок 4, ops checks)

- **V2-CR-02:** автоматическая проверка callback secrets на Fly не выполнена (в среде нет `flyctl`); в ops зафиксирован manual-check `CALLBACK_SHARED_SECRET` + `CALLBACK_SHARED_TOKEN`.
- **SEC-07:** подтверждён backlog — `shop-api-key` в meta витрины оставлен для демо-стенда, ротация после В2.
- **Тесты:** полный suite **559/0**.

## v1.79 — 2026-06-01 (V2 прогон 10 — блок 2, shop CSRF + order privacy)

- **Shop API:** `browser_shop_session?` — `valid_authenticity_token?` (V2-CR-03 / SEC-02).
- **Orders#show:** только заказ текущего `shop_customer_id` в сессии (SEC-08).
- **Тесты:** auth forged CSRF → 401; чужая сессия → 404 на show; suite **559/0**.

## v1.78 — 2026-06-01 (V2 прогон 10 — блок 1, CR-01 + V2-006)

- **CatalogBootstrap:** prefetch `ProductTenantSetting` по tenant — без N+1 `find_or_initialize_by` в цикле.
- **EntryPoints:** один запрос `FeatureFlag` на карточку точки (kiosk + modules).
- **Тесты:** `entry_points_test` — assert 1 FF query; suite **555/0**.

## v1.77 — 2026-06-01 (V2 прогон 10 — блок 0, план добивки)

- **Нет прогона 11:** добивка в рамках прогона 10, блоки 1–14 в `QA_ACCEPTANCE_RUN.md`.
- **Scope:** без Flutter / живого демо / живой оплаты; MCP-витрина 5 точек.
- **Точка входа агента:** `SESSION_STATE.md` + таблица блоков; блок 0 ✅, код не меняли.

## v1.76 — 2026-06-01 (V2 прогон 10c — финал QA scope)

- **10c:** 9× shop URLs, stress wave 2, kiosk cash+card 9×, Prog10 staff login (barista Alpha), prep_kitchen, AUTH-10 logout.
- **Скрипты:** `prog10_shop_urls_check.rb`, `prog10_setup_staff.rb`, `prog10_stress_wave2.rb`.
- **Тесты:** 554 runs, 1 failure при перегоне — см. журнал 10c.
- **QA прогон 10:** **PASS** (живое демо — §I чеклиста).

## v1.75 — 2026-06-01 (V2 прогон 10b — закрытие QA)

- **QA:** прогон 10 **PASS** — 9× cash/card, 9× kiosk, stress 8, RBAC-матрица, MCP checkout.
- **Скрипты:** `bin/prog10_fly_smoke.rb` (ORDER_DELAY_SEC), `bin/prog10_collect_kiosk_tokens.rb`.
- **Артефакты:** `prog10/smoke/prog10_curl_full.json`, `prog10/smoke/prog10_kiosk_full.json`, `prog10/staff-rbac/prog10_rbac_matrix.md`.
- **Живое демо** вынесено из QA → только §I [`CHECKLIST.md`](milestones/veha_2/checklists/CHECKLIST.md).

## v1.74 — 2026-06-01 (V2 прогон 10 — первый журнал)

- Промежуточный PASS; дополнен в v1.75 / прогон 10b.

## v1.73 — 2026-05-30 (V2 прогон 10 — черновик журнала)

- Промежуточная запись (заменена v1.74). См. коммит `b404fa7`.

---

## v1.72 — 2026-05-30 (V2 code review + CR fixes)

- **CR:** [`milestones/veha_2/qa/CODE_REVIEW.md`](milestones/veha_2/qa/CODE_REVIEW.md) — вердict «к прогону 10».
- **Код:** OrderCreator batch PTS; Tbank callback `claim` до enqueue; job lookup strict; Rack::Attack `/kiosk/api/`.
- **Тесты:** **554/0** (WSL). §I **не закрыта** — следующий шаг: **прогон 10**.

---

## v1.71 — 2026-05-30 (product docs: В2 реализовано)

- **Product:** синхронизация фактов В2 — `01_Vision`, `02_functional`, `03_Business_Logic`, `ARCHITECTURE`, `development_roadmap` (сделано vs В3, 554/0, §I открыта).
- **Agents:** `qa_scenarios.md` — расширен **[ВЕХА 2]** (Т-Банк, 3×3, AUTH, kiosk, stress); offline/единая смена → **В3**.
- **Источник правды для агентов:** `docs/product/development_roadmap.md` + ops `milestones/veha_2/checklists/CHECKLIST.md`.

---

## v1.70 — 2026-05-30 (живое демо В1: фидбек заказчика § 1)

- **Заказчик:** первый прогон plain § **1.1–1.4** — PDF + разбор в [`milestones/veha_1/reference/DEMO_FEEDBACK.md`](milestones/veha_1/reference/DEMO_FEEDBACK.md).
- **Артефакт:** [`milestones/veha_1/artifacts/customer_live_qa_block1_2026-05-30.pdf`](milestones/veha_1/artifacts/customer_live_qa_block1_2026-05-30.pdf).
- **Итог:** 1.2 **OK**; 1.1 / 1.3 / 1.4 **частично**; багов не заявлено. **H.3 В1 `[ ]`**; §I В2 **не закрыта**.

---

## v1.69 — 2026-05-30 (V2-T8: flaky callback timestamp test)

- **Тест:** `events_controller_test.rb` — anti-replay «timestamp within 300s»: было 299 с (race на границе) → **200 с + `travel_to`**.
- **Прогон:** файл **23 runs, 0 failures**; целевой тест **×5 PASS** (Windows native Ruby).
- **Ops:** V2-T8 **done** — `PRACTICES.md`, `CHECKLIST.md` §H, `POSTMORTEM_2026-05-28.md`.
- **§I приёмка В2:** не закрыта.

---

## v1.68 — 2026-05-30 (kiosk auth API + FLUTTER_API doc)

- **Kiosk:** `POST /kiosk/api/auth` — `device_token` → `tenant_id` (`c44b1eb`); тесты 6/0.
- **Docs:** [`FLUTTER_API.md`](milestones/veha_2/runbooks/FLUTTER_API.md), черновик postmortem.
- **§I приёмка В2:** **не закрыта** — ждёт апрува заказчика.

---

## v1.67 — 2026-05-28 (доки: shift_manager пропуск зафиксирован)

- **CHECKLIST §B, ONBOARDING_CHECKLIST §5:** добавлен пункт `[ ]` shift_manager login не проверялся (AUTH-06 SKIP).
- **DEMO_LOGINS.md В2:** полная таблица ролей включая shift_manager; замечание про AUTH-06.
- **STAFF_ACCESS.md:** таблица минимального набора с колонкой статус проверки.
- **PRACTICES.md:** раздел «Известные пропуски».
- **ONBOARDING_DEVTOOLS_RUN.md:** прогон 4 — AUTH-06 SKIP; замечание 3.
- Тесты и MCP-прогон 5 — после апрува.

---

## v1.66 — 2026-05-27 (блок B: feature flags + health endpoint)

- **Feature flags:** `barista/base_controller` + `prep_kitchen/base_controller` — `require_*_module!` блокирует доступ при выключенном модуле.
- **Health:** `Health::TenantsController` — `/health/tenants` (401 без auth, JSON для uk_global_admin).
- Тесты: `barista/feature_flags_test.rb` (2), `health/tenants_controller_test.rb` (3) — 5/5 PASS.
- CHECKLIST.md §B — все `[x]`.

---

## v1.65 — 2026-05-27 (онбординг: закрытие блока A)

- **CHECKLIST.md §A:** все `[x]` — PTS без demo:seed и rollback тестированы (`tenants_controller_test.rb`).
- **MCP Prod:** org + точка созданы на `coffeeos.fly.dev` — витрина работает, каталог подтянут.

---

## v1.64 — 2026-05-27 (MCP прогон 3: STF + CON-01 + SHP-08)

- **Staff:** `User#normalize_blank_phone` — пустой телефон → `NULL` (второй staff без дубликата `index_users_on_phone`).
- **MCP Run3** на org `MCP Run2 Org`: STF-01..03, CON-01 (199₽ на vitrina), SHP-08 (#202605-0002) — [`ONBOARDING_DEVTOOLS_RUN.md`](milestones/veha_2/runbooks/ONBOARDING_DEVTOOLS_RUN.md).
- ONBOARDING_CHECKLIST § приёмка: всё `[x]`, кроме **приёмки заказчиком**.

---

## v1.63 — 2026-05-26 (онбординг: фиксы замечаний + прогон 2)

- **order_number:** `DatabaseTriggers.ensure_order_number!`, rake `db:ensure_triggers`, boot в dev/test, `fly:release`.
- **Shop:** CSP Vite HMR (dev), Header без перехода на `/login`, org select `name (slug)`, catch-all `/shop/*`.
- Журнал MCP прогон 2: TEN-02..04, product card, integration CON-03/04 — [`ONBOARDING_DEVTOOLS_RUN.md`](milestones/veha_2/runbooks/ONBOARDING_DEVTOOLS_RUN.md).

---

## v1.62 — 2026-05-27 (MCP DevTools прогон онбординга)

- Каталог 58 сценариев: [`milestones/veha_2/runbooks/ONBOARDING_DEVTOOLS_SCENARIOS.md`](milestones/veha_2/runbooks/ONBOARDING_DEVTOOLS_SCENARIOS.md).
- Журнал прогона локалки (34 PASS): [`milestones/veha_2/runbooks/ONBOARDING_DEVTOOLS_RUN.md`](milestones/veha_2/runbooks/ONBOARDING_DEVTOOLS_RUN.md).
- ONBOARDING_CHECKLIST § приёмка — ссылка на MCP; блок **не закрыт** (ждём заказчика + CON-03/04).

---

## v1.61 — 2026-05-27 (ops: локальный подъём WSL)

- Документ [`../dev/LOCAL_DEV.md`](../dev/LOCAL_DEV.md): migrate, `demo:seed`, `demo:shop_urls`, `ruby bin/dev`, URL витрины, типичные ошибки, сверка с Fly (режим B).
- Ссылки из `milestones/veha_2/runbooks/ONBOARDING.md`, `milestones/veha_2/README.md`.

---

## v1.60 — 2026-05-26 (В2 онбординг §3: заготовочный цех)

- ONBOARDING §3: `production_kitchen` + `prep_kitchen`, staff → `/prep_kitchen` — работает без правок.
- Тесты: `onboarding_prep_kitchen_test.rb` (2/0).

---

## v1.59 — 2026-05-26 (В2 онбординг §2: точка продаж)

- Поле `address` в форме создания точки УК (`platform/tenants`).
- Тесты: `onboarding_sales_point_test.rb` — 3 точки, модули, flash URL, меню, RLS (5/0).
- ONBOARDING_CHECKLIST §2 `[x]`; V2-T2 закрыт.

---

## v1.58 — 2026-05-26 (В2 онбординг §1: организация)

- Проверка ONBOARDING_CHECKLIST §1: создание org в УК (`/admin/organizations`), список, привязка tenant к org — **работает без правок кода**.
- Тесты: `test/integration/platform/onboarding_organization_test.rb` (3/0).
- Ops: `ONBOARDING_CHECKLIST.md` §1 `[x]`, журнал в `veha_2/PRACTICES.md`.

---

## v1.57 — 2026-05-26 (Fly: troubleshooting certs/SSH; полные Shop URL в demo:seed)

### Ops

- `FLY_DEMO_STAND.md`: разбор `fly certs` (ожидаемый отказ) и `fly ssh` timeout; как взять URL витрин **без SSH** (`fly logs`, УК).
- `demo:seed` печатает полные `https://coffeeos.fly.dev/shop?tenant_id=…` в лог release (APP_HOST).

---

## v1.56 — 2026-05-25 (URL витрины: режим Fly demo vs поддомены прод)

### Проблема

- `fly certs add "*.coffeeos.fly.dev"` и `demo-point-a.coffeeos.fly.dev` → `cannot register certificate for this domain` (зона `*.fly.dev` у Fly, нет DNS на `{slug}.coffeeos.fly.dev`).

### Решение (два режима, поддомены не отменены)

| Режим | Где | URL витрины |
|-------|-----|-------------|
| **A — прод** | Свой домен + `SHOP_BASE_DOMAIN` | `https://{slug}.shop.бренд.ru/shop` |
| **B — Fly demo** | `coffeeos`, без `SHOP_BASE_DOMAIN` | `https://coffeeos.fly.dev/shop?tenant_id=` |

- `UrlBuilder`: поддомены **только** при явном `SHOP_BASE_DOMAIN` (убран дефолт `coffeeos.fly.dev` в production).
- `fly.toml`: `SHOP_BASE_DOMAIN` не задан (комментарий про переход на режим A).
- `bin/rails demo:shop_urls` — печать URL всех активных точек.
- Доки: [`SHOP_URL_MODES.md`](SHOP_URL_MODES.md), обновлены `FLY_DEMO_STAND.md`, `INFRA_URLS.md`, `ONBOARDING.md`, чеклисты В1/В2.

### Твои действия после merge/deploy

1. Push `develop` → дождаться GitHub Actions → Fly.
2. `fly ssh console -a coffeeos -C 'bin/rails demo:shop_urls'` — скопировать URL витрин A/B.
3. Smoke: витрина A с `?tenant_id=`, логин barista (`DEMO_LOGINS.md`).
4. Свой домен — по чеклисту **A-inf** в `veha_2/checklists/CHECKLIST.md` и § «Переход B → A» в `SHOP_URL_MODES.md`.

---

## v1.55 — 2026-05-25 (Fly demo-стенд: автосид + docs в git)

### Fly / живое демо

- `fly.toml`: `SHOP_BASE_DOMAIN=coffeeos.fly.dev`, `DEMO_AUTO_SEED=true`, `release_command` = `db:prepare` + `demo:seed` (временно до закрытия H.3).
- `bin/docker-entrypoint`: запасной `demo:seed` при `DEMO_AUTO_SEED=true`.
- `docs/operations/demo/FLY_DEMO_STAND.md` — инструкция, wildcard cert, откат автосида.
- Чеклист § **H.0** в `milestones/veha_1/checklists/CHECKLIST.md`, этап 0 в `QA_ACCEPTANCE_RUN.md`.

### Документация

- `.gitignore`: `docs/operations/**` и `milestones/**` в git (агенты + команда).
- Полный комплект `milestones/veha_2/` (чеклисты, онбординг, оплата, …).

---

## v1.54 — 2026-05-25 (параллельный старт В2; В1 **не закрыта** официально)

### Git / деплой

- **develop → origin:** 16 коммитов В1 (код A–G, тесты, docs product/ops/agents, `milestones/veha_1/` в git после правки `.gitignore`).
- **Fly:** первый деплой упал (`npm EBADPLATFORM`, win32 bindings) — **v1.53** исправлен; повторный push `4a25187`. Деплой через GitHub Actions `Deploy to Fly.io` на push в `develop`.
- **Прод:** https://coffeeos.fly.dev · витрина А https://demo-point-a.coffeeos.fly.dev/shop · Б https://demo-point-b.coffeeos.fly.dev/shop

### Документация (сессия 2026-05-25, конец В1)

- `docs/operations/milestones/veha_1/qa/LIVE_DEMO_SCENARIOS.md` — ручные сценарии для технарей (все роли, 2–4 мин).
- `docs/operations/milestones/veha_1/qa/LIVE_DEMO_SCENARIOS_PLAIN.md` — то же простым языком для заказчика/нетехнарей; ссылки на витрину, роли `gm-a`/`gm-b`/`shift-a` в словаре.
- Обновлены `CHECKLIST.md` § H.3, `README.md` (карта папки вехи).

### Код (уже в develop, кратко)

- Блоки A–G: сервисы barista/shop/inventory/demo, shop Svelte, block F/G тесты, RLS, гибрид смены, `OrderCancellationService`, `MovementCreator`, миграции stock/order_number.
- Code review: N+1 fix в `Shop::OrderCreator`.
- Deploy fix: `package.json` без win32 devDeps, `Dockerfile` → `npm ci`.

### Не закрыто (В1)

- **H.3** живое демо владельцем (инструкции готовы).
- **§ I** формальное закрытие вехи в ops.
- Локально **не в git** (на момент записи): `LIVE_DEMO_SCENARIOS*.md`, правки `CHECKLIST`/`README` — закоммитить перед В2.

### Следующий этап

- **Веха 2** — основная разработка (`HANDOFF.md`, `milestones/veha_2/`).
- **Веха 1** — остаётся открытой в ops до H.3 + § I; закрытие может быть заочным, без остановки В2.

---

## v1.53 — 2026-05-25

### Деплой Fly

- **Причина падения:** в `package.json` были прямые `devDependencies` только под Windows ARM64 (`@rolldown/binding-win32-arm64-msvc`, `@tailwindcss/oxide-win32-arm64-msvc`, `lightningcss-win32-arm64-msvc`) — `npm install` в Docker (linux/x64) падал с `EBADPLATFORM`.
- **Исправление:** убраны win32-binding из `package.json`; платформенные биндинги подтягивает Vite/Tailwind как optional. В Dockerfile — `npm ci`.
- **Локально на Windows:** после `npm install` optional-биндинги ставятся сами; не добавлять win32-пакеты в корень `package.json`.

---

## v1.52 — 2026-05-25

### Итог

- Документация **Вехи 1** собрана в `docs/operations/milestones/veha_1/`.
- Корневой `MILESTONE_PRACTICES.md` — указатель на папки вех.

### Структура

- `milestones/veha_1/`: CHECKLIST, PRACTICES, QA_ACCEPTANCE_RUN, CODE_REVIEW, ORDER_ENTRY_AUDIT, DEMO_LOGINS.
- `milestones/veha_2/` — заготовка под В2.

---

## v1.51 — 2026-05-25

### Итог

- Code review В1 перед демо: `docs/operations/milestones/veha_1/qa/CODE_REVIEW.md`; блокеров нет.
- Исправление N+1 в `Shop::OrderCreator` (preload products).

### Тесты

- shop + block_g после правки: **51 runs, 165 assertions, 0 failures**.

---

## v1.50 — 2026-05-25

### Итог

- Gate **A/B гибрид смены**: `docs/operations/milestones/veha_1/reference/ORDER_ENTRY_AUDIT.md`, §G чеклиста, gate в `MILESTONE_PRACTICES.md`.
- Сквозной аудит 8 входов заказа — все соответствуют В1.

### Документация

- `docs/operations/milestones/veha_1/reference/ORDER_ENTRY_AUDIT.md` — реестр + правило синхронизации с таск-трекером.
- Комментарии в `Shop::OrderCreator`, `Barista::OrderCreationService` → ссылка на аудит.

---

## v1.49 — 2026-05-25

### Итог

- Блок **H.2** (агент): сухой прогон + MCP DevTools по `qa_scenarios.md`; журнал V1-* заполнен (Авто/MCP).
- Полный suite: **479 runs, 0 failures** (повторный прогон 2026-05-25).
- Живое демо (**H.3**) — на владельце.

### Документация

- `docs/agents/AGENTS/qa_scenarios.md` — этапы 1–3, журнал прогона.
- `docs/operations/milestones/veha_1/qa/QA_ACCEPTANCE_RUN.md` — протокол прогона (сухой + MCP).

### Заметки QA

- `tmp/shop_mcp_flow.rb` in-process: 2/9 (401 без browser session); компенсировано MCP + `test/integration/shop/`.
- Batch shop+block_g: единичный 429 Rack::Attack; изолированный `block_g` shop test — OK.

---

## v1.48 — 2026-05-24

### Итог

- Блок **G закрыт**: гибрид shop без смены / barista только с открытой `CashShift`; отмена с причиной + audit; MCP UI OK.
- Полный suite: **479 runs, 1896 assertions, 0 failures** (2026-05-24).

### Изменено

- `Barista::OrderCreationService` — `shift.open?` guard.
- `Barista::OrderCancellationService` — обязательная причина.
- `Barista::OrdersController` — `normalize_cart_items`, `@shift` в `new`, cancel reason + rescue.
- `app/views/barista/orders/new.html.erb` — JS корзины внутри `content_for`.
- `lib/port_killer.rb`, `lib/dev_server.rb`, `bin/ensure-server` — MCP/dev на Windows.
- `test/integration/block_g_cash_shift_test.rb` — 8 runs (+ HTML form cart_items index).

---

## v1.47 — 2026-05-24

### Итог

- Блок **F закрыт**: списание по техкарте при продаже, отрицательный остаток, prep_kitchen movements, техдолг зафиксирован.
- `Inventory::OrderRecipeDeduction`, migration `block_f_stock_deduction`, demo recipes/stock.

### Изменено

- `app/services/inventory/order_recipe_deduction.rb` — новый.
- `Barista::OrderCreationService`, `Shop::OrderCreator` — вызов deduction.
- `IngredientTenantStock` — снят validation `qty >= 0`.
- `Demo::EnvironmentSetup` — `ensure_demo_recipes_and_stock!`.
- Тесты: `block_f_stock_flow_test.rb`, `order_recipe_deduction_test.rb`.

---

## v1.46 — 2026-05-24

### Итог

- Блок **E UI MCP закрыт**: Chrome DevTools — полный shop-флоу в браузере **OK**.
- Vite на Windows ARM: явные native bindings (`rolldown`, `tailwindcss/oxide`, `lightningcss`).
- `.env`: `SHOP_API_KEY` + `SHOP_DEFAULT_TENANT_ID` (demo-point-a).

---

## v1.45 — 2026-05-21

### Итог

- Блок **E закрыт**: MCP-эквивалент `tmp/shop_mcp_flow.rb` **9/9** на demo-point-a; shop suite **57/147/0**; полный suite **462/1834/0**.
- Chrome DevTools / Puppeteer MCP — **errored**; API-сценарии покрыты in-process runner + `block_e_shop_flow_test`.

### Изменено

- `tmp/shop_mcp_flow.rb` — CSRF bypass для dev-runner, API key header, fix status check.
- `docs/operations/milestones/veha_1/checklists/CHECKLIST.md` — блок E `[x]`.
- `docs/operations/reference/MILESTONE_PRACTICES.md` — журнал MCP Block E.

---

## v1.44 — 2026-05-21

### Итог

- Блок **E спец-тесты**: `block_e_shop_flow_test.rb` + auth browser session; shop suite **57/147/0**.
- MCP и полный suite **не запускали** — ждём апрув.

### Изменено

- `test/integration/shop/block_e_shop_flow_test.rb` — новый.
- `test/integration/shop/api/authentication_test.rb` — browser CSRF session.

---

## v1.43 — 2026-05-21

### Итог

- Блок **E фаза 1**: Svelte shop — меню, корзина+модификаторы, mock оплата, история за сегодня, skeleton, anti double-click.
- Локальные shop-тесты: **51/113/0**. Полный suite **не запускали** — ждём апрув.

### Изменено

- Frontend: `catalog.js`, `api.js`, `modifiers.js`, `PageSkeleton.svelte`, Catalog/Cart/Checkout/Orders/Product/CategoryProducts.
- Backend: `orders_controller#history` (`today=1`), `shop_api_auth` browser session, layout `shop-api-key` meta.
- Тест: `orders_controller_test` — history today.

---

## v1.42 — 2026-05-21

### Итог

- Блок **D закрыт**: полный `bin/rails test` — **455 runs, 1795 assertions, 0 failures**.
- Fix тестов после `Demo::EnvironmentSetup` (глобальные `order_cancel_reasons`, shop-каталог в test DB).
- Чеклист `VEHA_1_CHECKLIST.md` § D — все 7 ролей `[x]`.

### Изменено

- `test/support/factories.rb` — `ensure_order_cancel_reason!`.
- Тесты: manager_office/shift, barista_tablet, catalog_bootstrap, publish_product_service.

---

## v1.41 — 2026-05-21

### Итог

- **Критические фиксы блока D:** форма movement (`movement[items][][...]`), триггер `generate_order_number`, `demo:seed` без `tmp/mcp_setup.rb`.
- Миграция `20260523140000_ensure_order_number_trigger` — функция + триггер + backfill пустых номеров.
- `Demo::EnvironmentSetup` — открытая смена demo-point-a, `order_cancel_reasons`, stock цеха, сброс stop-list.
- Целевые тесты: **42 runs, 206 assertions, 0 failures** (environment_setup, order_creation, prep_kitchen movements, movement_creator, block_d smoke).
- Полный suite **не запускали** — ждём апрув.

### Изменено

- `app/views/prep_kitchen/movements/new.html.erb` — `scope: :movement`, items `movement[items][][...]`.
- `app/controllers/prep_kitchen/movements_controller.rb` — `movement_params`, `normalize_items`.
- `app/services/barista/order_creation_service.rb` — `reload` + ошибка при пустом `order_number`.
- `app/services/demo/environment_setup.rb` — cancel reasons, open shift, kitchen stock, PTS reset.
- `db/migrate/20260523140000_ensure_order_number_trigger.rb` — новый.
- Тесты: `order_creation_service_test`, `environment_setup_test`, `prep_kitchen_movements_test`.

---

## v1.40 — 2026-05-23

### Итог

- Блок **D**: MCP **POST**-флоу всех 7 ролей (Chrome DevTools, isolated context).
- Подготовка dev: `demo:seed`, `tmp/mcp_setup.rb` (CashShift + `order_cancel_reasons`), restart `rails s`.
- Заметка: barista повторный create в dev — `idx_orders_tenant_number` (пустой `order_number`).
- Полный suite **не запускали** — ждём апрув.

### Изменено

- `MILESTONE_PRACTICES.md` § Block D — журнал POST-флоу.
- `SESSION_STATE.md`, `VEHA_1_CHECKLIST.md` — статус awaiting approval.

---

## v1.39 — 2026-05-23

### Итог

- Блок **D**: обход **7 ролей через Chrome DevTools MCP** — все GET-экраны OK.
- Fix: `login_form_controller.js` — email regex для `@demo.coffeeos.local`.
- Smoke: `block_d_panel_screens_test` **7/84/0**. Полный suite **не запускали**.

### Изменено

- `MILESTONE_PRACTICES.md` § Block D — журнал MCP-прогона.
- `app/javascript/controllers/login_form_controller.js` — multi-dot email domains.

---

## v1.38 — 2026-05-21

### Итог

- Подготовка блока **D**: единые demo-логины, чеклист с MCP, smoke GET всех панелей (**7 runs, 84 assertions, 0 failures**).
- Полный `bin/rails test` **не запускали** — ожидание апрува.

### Добавлено

- `docs/operations/milestones/veha_1/reference/DEMO_LOGINS.md`
- `test/integration/panels/block_d_panel_screens_test.rb`

### Изменено

- `lib/tasks/test_login.rake` — делегирует `Demo::EnvironmentSetup` (убран `office_manager` и старые @test.com).
- `VEHA_1_CHECKLIST.md` §D — MCP + demo logins + порядок закрытия.

---

## v1.37 — 2026-05-21

### Итог

- Блок **C** чеклиста В1 закрыт: RBAC **platform / УК** — org, tenant, выдача `franchise_manager`, только `uk_global_admin`.
- Полный прогон: **446 runs, 1686 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/platform_uk_rbac_test.rb` — 7 тестов.

### Документация

- `VEHA_1_CHECKLIST.md` — C platform/УК [x]; блок C завершён.
- `MILESTONE_PRACTICES.md` § Platform / УК RBAC.

---

## v1.36 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **prep_kitchen_worker** — просмотр своего цеха, без мутаций и чужих панелей.
- Полный прогон: **439 runs, 1644 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/prep_kitchen_worker_rbac_test.rb` — 6 тестов.

### Документация

- `VEHA_1_CHECKLIST.md` — C prep_kitchen_worker [x]; `MILESTONE_PRACTICES.md` § Prep kitchen worker RBAC.

---

## v1.35 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **prep_kitchen_manager** — полный доступ к цеху, без чужих панелей.
- Полный прогон: **433 runs, 1612 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/prep_kitchen_manager_rbac_test.rb` — 6 тестов.

### Документация

- `VEHA_1_CHECKLIST.md` — C prep_kitchen_manager [x]; `MILESTONE_PRACTICES.md` § Prep kitchen manager RBAC.

---

## v1.34 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **franchise_manager** — просмотр своих точек, без POS и редактирования меню.
- Полный прогон: **427 runs, 1577 assertions, 0 failures**.

### Изменено

- `ProductTenantSettingPolicy#update?` — franchise_manager не может менять цены.
- `manager/menu/index.html.erb` — форма цены только для general_manager / УК.

### Добавлено

- `test/integration/auth/franchise_manager_rbac_test.rb` — 6 тестов.

### Документация

- `VEHA_1_CHECKLIST.md` — C franchise_manager [x]; `MILESTONE_PRACTICES.md` § Franchise manager RBAC.

---

## v1.33 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **general_manager** — меню, цены, staff, склад своей точки.
- Полный прогон: **421 runs, 1544 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/general_manager_rbac_test.rb` — 9 тестов: privileged paths, tenant isolation, forbidden panels.

### Документация

- `VEHA_1_CHECKLIST.md` — C general_manager [x]; `MILESTONE_PRACTICES.md` § General manager RBAC.

---

## v1.32 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **shift_manager** — оперативка текущей смены, без «глубокой» истории.
- Полный прогон: **412 runs, 1500 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/shift_manager_rbac_test.rb` — 8 тестов: scope текущей смены, forbidden panels, menu read-only, closed shift hidden.

### Документация

- `VEHA_1_CHECKLIST.md` — C shift_manager [x]; `MILESTONE_PRACTICES.md` § Shift manager RBAC.

---

## v1.31 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: RBAC **barista** — только POS и своя смена; manager/prep_kitchen/admin закрыты.
- Полный прогон: **404 runs, 1457 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/barista_rbac_test.rb` — 7 тестов: allowed POS paths, forbidden panels, PATCH/POST guard, tenant isolation.

### Документация

- `VEHA_1_CHECKLIST.md` — C barista [x]; `MILESTONE_PRACTICES.md` § Barista RBAC.

---

## v1.30 — 2026-05-21

### Итог

- Блок **C** чеклиста В1: session-login для всех панелей (barista, manager, prep_kitchen, platform/УК).
- Полный прогон: **397 runs, 1414 assertions, 0 failures**.

### Добавлено

- `test/integration/auth/panel_login_test.rb` — 11 тестов: редиректы по ролям, guard без сессии, logout, user без ролей.

### Документация

- `VEHA_1_CHECKLIST.md` — C session login [x]; `MILESTONE_PRACTICES.md` § Session login.

---

## v1.29 — 2026-05-21

### Итог

- Блок **B** чеклиста В1: RLS — точка A не видит данные точки B; **новых Postgres-политик нет**.
- Полный прогон: **386 runs, 1327 assertions, 0 failures**.

### Добавлено

- `test/support/rls_test_bootstrap.rb`, `rls_test_helper.rb` — bootstrap существующих migrate-политик в test DB; роль `coffeeos_rls_test` (NOBYPASSRLS).
- `test/integration/rls_tenant_isolation_test.rb` — 7 тестов Postgres RLS (orders, payments, PTS, смены, остатки).

### Документация

- `VEHA_1_CHECKLIST.md` — RLS [x]; `MILESTONE_PRACTICES.md` § RLS.

---

## v1.28 — 2026-05-21

### Итог

- Блок **B** чеклиста В1: Shop API (меню, заказ, auth); **имитация оплаты** без шлюза (до вехи 2).
- Полный прогон: **377 runs, 1293 assertions, 0 failures**.

### Изменено

- `Shop::OrderCreator` — `SHOP_SIMULATE_PAYMENT=1` (default): все методы → accepted/succeeded; `=0` — режим pending для вехи 2.
- `Shop::Api::ProductsController#index` — fix default `per_page`.

### Добавлено

- Тесты: `shop/api/{products_controller,mvp_flow,authentication}_test.rb`.

### Документация

- `VEHA_1_CHECKLIST.md` — Shop API [x]; `MILESTONE_PRACTICES.md` § Shop API.

---

## v1.27 — 2026-05-21

### Итог

- Блок **B** чеклиста В1: демо-среда (1 org, 2 точки, каталог, PTS, пользователи с ролями).
- Полный прогон: **367 runs, 1246 assertions, 0 failures**.

### Добавлено

- `Demo::EnvironmentSetup` — идемпотентная демо-среда В1.
- `db/seeds_demo_v1.rb`, `lib/tasks/demo.rake` (`bin/rails demo:seed`).
- `test/services/demo/environment_setup_test.rb`.

### Изменено

- `db/seeds.rb` — вместо прямой загрузки каталога вызывает demo seed (каталог внутри setup).
- Демо: добавлен `demo-prep-kitchen` + `pk-manager` / `pk-worker` (prep_kitchen).

---

## v1.26 — 2026-05-21

### Итог

- Блок **B** чеклиста В1: проверены CRUD и связи MVP-моделей (Tenant, Category, Product, Modifier, Order, OrderItem).
- Полный прогон: **364 runs, 1217 assertions, 0 failures**.

### Добавлено

- `test/models/mvp_core_models_test.rb` — 17 тестов CRUD, ассоциаций, cascade/restrict, jsonb `modifier_options`.

### Документация

- `VEHA_1_CHECKLIST.md` — пункт B «MVP-модели» [x].
- `MILESTONE_PRACTICES.md` — таблица проверки моделей + журнал.

---

## v1.25 — 2026-05-21

### Итог

- Блок **A. Service Objects** чеклиста В1 закрыт.
- Полный прогон: **347 runs, 1166 assertions, 0 failures**.

### Документация

- `MILESTONE_PRACTICES.md` — таблица «Рефактор: что сделано и зачем».
- `VEHA_1_CHECKLIST.md` — все пункты секции A отмечены [x].

---

## v1.24 — 2026-05-21

### Добавлено

- `Barista::OrderStatusUpdateService`, `Callbacks::PaymentStatusUpdater`, `Platform::Menu::PublishProductService` + unit-тесты.

### Изменено

- `barista/orders_controller#update_status`, `callbacks/events_controller#payment`, `platform/menu_controller` create/update product.
- `docs/operations/milestones/veha_1/checklists/CHECKLIST.md` — аудит контроллеров [x].

### Проверка

- `bin/rails test test/services/barista/ test/services/callbacks/ test/services/platform/menu/ test/controllers/callbacks/events_controller_test.rb test/controllers/barista/orders_controller_test.rb` → 75 runs, 0 failures.

---

## v1.23 — 2026-05-21

### Изменено

- `app/services/prep_kitchen/stock/movement_creator.rb` — создание черновика: сначала `StockMovement`, затем `stock_movement_items` в транзакции (вместо nested save).
- `test/services/prep_kitchen/stock/movement_creator_test.rb` — happy-path и hash items из формы.

### Проверка

- `bin/rails test test/services/prep_kitchen/stock/` → 10 runs, 0 failures.

### Изменено (docs)

- `docs/operations/milestones/veha_1/checklists/CHECKLIST.md` — MovementCreator [x].

---

## v1.22 — 2026-05-21

### Добавлено

- `app/services/barista/order_cancellation_service.rb` — отмена заказа, `OrderStatusLog`, `AdminAuditLog`, возврат склада при `preparing` + `ingredients_used=false`.
- `test/services/barista/order_cancellation_service_test.rb`.

### Изменено

- `app/controllers/barista/orders_controller.rb` — `#cancel` вызывает сервис.
- `docs/operations/milestones/veha_1/checklists/CHECKLIST.md` — пункт отмена [x].

### Проверка

- `bin/rails test test/services/barista/ test/controllers/barista/orders_controller_test.rb` → 47 runs, 0 failures.

---

## v1.21 — 2026-05-21

### Добавлено

- `test/services/prep_kitchen/stock/movement_creator_test.rb` — валидации `MovementCreator`.
- `test/services/prep_kitchen/stock/movement_confirmer_test.rb` — подтверждение черновика, отрицательный остаток.
- `test/services/prep_kitchen/stock/movement_canceller_test.rb` — отмена черновика.
- `test/services/health/tenant_checker_test.rb` — структура чеков и касса.

### Проверка

- `PARALLEL_WORKERS=0 bin/rails test test/services/ test/controllers/platform/tenants_controller_test.rb` → 86 runs, 0 failures.
- `PARALLEL_WORKERS=0 bin/rails test` → 337 runs, 1124 assertions, 0 failures.

### Изменено

- `docs/operations/reference/MILESTONE_PRACTICES.md`, `SESSION_STATE.md` — журнал прогона тестов Service Objects.

---

## v1.20 — 2026-05-14

### Изменено

- Удалён `.cursor/rules/prd-factory-agent.mdc`; операционный процесс перенесён в **`.cursorrules`** и **`docs/agents/AGENTS.md`**: обязательные `ISSUES` при багах, батчевый `SESSION_STATE` (2–3+ шага / смена задачи / ~3–4 коммита), акцент на **коммитах** для истории, продуктовый вход — `docs/product/01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`; `ARCHITECTURE.md` — по явной готовности канона.
- `docs/operations/ISSUES.md`: шапка без PRD Factory, ссылка на `.cursorrules`.

---

## v1.19 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511190000_create_production_kitchen_and_supply.rb`:
  - `production_recipes`, `production_batches`, `supply_orders`, `supply_order_items` (FK, CHECK, индексы по core);
  - расширение `ingredients`: поля production/хранения + constraint `chk_ingredient_storage_temp` + частичный индекс по полуфабрикатам (без уникального индекса на `name`).
- Миграция `db/migrate/20260511190500_remove_duplicate_production_batches_semifinished_index.rb`: убран дублирующий индекс по `semifinished_id` у `production_batches`; в `20260511190000` для `references :semifinished` задано `index: false` (чистые новые прогоны без дубля).

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B5:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/reference/GAP_LIST_CORE_SCHEMA.md`: прогресс B5, покрытие `62/62`, помечены закрытые пункты `production_*`, `supply_*`.
- `docs/operations/session/HANDOFF.md`, `docs/operations/session/SESSION_STATE.md`: батч B5 завершён.

### Причина

Закрыть последний миграционный батч production/supply по core и зафиксировать полное табличное покрытие gap-листа.

---

## v1.18 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511184500_create_pickup_tables_and_orders_fields.rb`:
  - `pickup_display_settings`;
  - `pickup_calls`;
  - `pickup_events`;
  - расширение `orders`: `ready_at`, `issued_at`, `pickup_method` + constraint/indexes.

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B4:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/reference/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B4 и покрытием (`58/62`, `93.5%` с mapping).
- `docs/operations/session/HANDOFF.md` и `docs/operations/session/SESSION_STATE.md` переведены на следующий батч B5.

### Причина

Закрыть контур smart pickup (этап 10 core) и подготовить основу для финального production/supply батча.

---

## v1.17 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511183000_create_mobile_carts_and_payment_methods.rb`:
  - `mobile_carts`;

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B3.5:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/reference/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B3.5 и покрытием (`55/62`, `88.7%` с mapping).
- `docs/operations/session/HANDOFF.md` и `docs/operations/session/SESSION_STATE.md` переведены на следующий батч B4.

### Причина

Закрыть мобильный слой ядра перед переходом к модулю умной выдачи (pickup), сохраняя стабильность через полный тестовый контур.

---

## v1.16 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511181500_create_loyalty_promo_push_feedback.rb`:
  - `loyalty_accounts`;
  - `loyalty_transactions`;
  - `promo_code_usages`;
  - `push_notifications`;
  - `order_feedback`.

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B3:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/reference/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B3 и покрытием (`53/62`, `85.5%` с mapping).
- `docs/operations/session/HANDOFF.md` и `docs/operations/session/SESSION_STATE.md` переведены на следующий батч (B3.5/B4).

### Причина

Закрыть крупный слой мобильной лояльности и коммуникаций до перехода к выдаче (pickup) и production/supply модулям.

---

## v1.15 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511180000_create_billing_and_tenant_invitations.rb`:
  - `billing_plans`;
  - `billing_subscriptions`;
  - `tenant_invitations`;
  - `tenants.plan_id` + FK на `billing_plans`.

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B2:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/reference/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B2 и покрытием (`48/62`, `77.4%` с mapping).
- `docs/operations/session/HANDOFF.md` и `docs/operations/session/SESSION_STATE.md` переведены на следующий батч B3.

### Причина

Продолжить синхронизацию ядра безопасными батчами, закрывая приоритетный billing/admin контур до перехода к loyalty/pickup/production.

---

## v1.14 — 2026-05-11

### Добавлено

- Миграция `db/migrate/20260511174500_create_admin_audit_and_feature_flags_logs.rb`:
  - `admin_audit_logs` (tenant/actor/entity/action/details/request_id + индексы);
  - `feature_flags_logs` (tenant/changed_by/module/action/enabled/changed_at/meta + индексы).

### Проверка

- Миграции применены в `development` и `test`.
- Полный тестовый прогон после B1:
  - `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.

### Изменено

- `docs/operations/reference/GAP_LIST_CORE_SCHEMA.md` обновлён прогрессом B1 (добавлены `done-in-b1` отметки и новый coverage с mapping).
- `docs/operations/session/HANDOFF.md` и `docs/operations/session/SESSION_STATE.md` переведены на следующий батч B2.

### Причина

Запуск практической синхронизации core->schema с минимальным риском: сначала закрываем audit/log базу и подтверждаем стабильность тестами.

---

## v1.13 — 2026-05-11

### Изменено

- `docs/operations/reference/GAP_LIST_CORE_SCHEMA.md` переведён из чернового списка в рабочий артефакт Шага 2:
  - выполнена классификация всех 25 гэпов (`rename-only` / `missing-table`);
  - назначены батчи исполнения B0..B5;
  - добавлен чек-лист анти-ошибок до/после каждого батча.
- `docs/operations/session/HANDOFF.md` обновлён на текущий рабочий маршрут: B0 -> B1.
- `docs/operations/session/SESSION_STATE.md` обновлён: Шаг 1 завершён, классификация зафиксирована, следующий шаг — исполнение батчей.

### Причина

После пользовательского апрува нужен был не только список расхождений, но и управляемый план выполнения с контролем риска, чтобы доводить систему до синхронности без регрессий.

---

## v1.12 — 2026-05-11

### Изменено

- Документация переведена в новый базовый контур: в `docs/product` оставлены только `01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`; остальные материалы перенесены в `docs/archive/2026-05-11-reset`.
- Создан контур ядра в `docs/product/core`: загружены 11 SQL-доков, выровнены имена файлов по смыслу с сохранением нумерации `01..11`.
- Добавлен `docs/product/core/README.md` с картой ядра и порядком чтения.
- В `docs/agents/AGENTS.md` удалён блок «Воркфлоу задачи» по запросу пользователя.

### Анализ

- Проведено сравнение `docs/product/core/*.md` с текущим `db/schema.rb`.
- Покрытие core-ядра по таблицам: `37/62` (≈ `59.7%`).
- Выявлены 2 типа расхождений:
  1. Нейминг/множественное число (`*_log` vs `*_logs`, `*_visibility` vs `*_visibilities`).
  2. Реально отсутствующие в схеме модули поздних этапов (в т.ч. billing, loyalty, pickup, production, push).

### Причина

Система развивалась итеративно под рабочие задачи, поэтому часть модулей реализована частично/в упрощённом виде и не полностью синхронизирована с полной 11-этапной core-спецификацией.

### План

- Шаг 1: зафиксировать `gap-list` core→schema (что уже есть, что rename, что отсутствует).
- Шаг 2: закрывать гэпы батчами по модулям через обратимые миграции + тесты.
- Шаг 3: выполнить сквозной smoke/regression на критичных потоках.
- Шаг 4: pre-prod прогон, rollback-план, затем production rollout.

---

## v1.11 — 2026-05-03

### Добавлено

- Онбординг точки в УК: `Platform::TenantOnboarding::Provision`, `CatalogBootstrap` (авто PTS для активных продуктов), транзакционный create/update в `Platform::TenantsController`.
- Резолвинг витрины по поддомену (`tenants.slug` + `SHOP_BASE_DOMAIN`, прод по умолчанию `coffeeos.fly.dev`), `UrlBuilder` для ссылки в flash после создания точки.
- Переменная `SHOP_BASE_DOMAIN` в `.env.example`; тесты сервисов, контроллера УК, интеграция shop API по Host.

### Причина

Свести создание точки к одному сценарию (модули + каталог + канонический URL) и поддержать мультиточечную витрину по поддомену.

---

## v1.10 — 2026-05-02

### Добавлено

- `docs/product/ARCHITECTURE.md` — секция «Архитектура онбординга организации и точки (v1)»: точка входа в УК, состав доменных сущностей, tenant/RLS-изоляция, поддомены и shop↔tenant, аудит, требования идемпотентности и границы v1.

### Причина

Зафиксировать технический контракт перед реализацией фичи автосоздания организации/точки/доступов.

---

## v1.9 — 2026-05-02

### Добавлено

- `docs/product/PRD.md` — секция «Онбординг организации и точки»: УК создаёт организацию/точку/владельца, автомодули и каталог, поддомены, аудит, без киоска в v1; глоссарий (MVP-скоуп потока, идемпотентность).

### Причина

Фиксация ответов заказчика перед проектированием в ARCHITECTURE и реализацией.

---

## v1.8 — 2026-05-02

### Добавлено

- `.cursor/rules/prd-factory-agent.mdc` — анти-игнор: срочность не отменяет гейты; приоритет операционных правил v10 над расхождениями в `AGENTS.md`; обязательный минимум при конце сессии (`HANDOFF` + `SESSION_STATE`); деструктивные git-операции и Merge Conflict Gate; передачи между ролями и протокол mid-sprint.
- `docs/agents/AGENTS.md` — уточняющие пункты (согласование с v10, одна ведущая роль, конец сессии, git/merge), без удаления существующих правил.

### Причина

Снизить «игнор» инструкций: явные стыки цепочки агентов, запрет обхода протоколов под давлением, разрешение противоречия батчей vs «обновляй всё каждый шаг».

---

## v1.7 — 2026-05-02

### Добавлено

- Rake-задача `shop:catalog:load` — заливка каталога витрины из `db/seeds_shop_catalog.rb` без полного `db:seed`. В production только с `ALLOW_SHOP_CATALOG_LOAD=1`.
- `.env.example` — переменная `ALLOW_SHOP_CATALOG_LOAD` с комментарием.

### Причина

Нужен явный, контролируемый способ наполнить витрину (категории, товары, цены по точкам) в dev и при необходимости на production.

---

## v1.6 — 2026-05-02

### Исправлено

- Shop API: 500 на `GET /shop/api/categories` в production (SolidCache / `Rails.cache.write`) — миграция уникального индекса для cache-БД, безопасное чтение/запись кэша в `Shop::Api::CategoriesController`, деплой без кэша сборки Docker.

### Изменено

- `db/cache_migrate/20260502100000_ensure_solid_cache_key_hash_unique_index.rb` — индекс `key_hash` для Solid Cache upsert.
- `app/controllers/shop/api/categories_controller.rb` — `safe_cache_read` / `safe_cache_write`.
- `db/cache_schema.rb` — версия схемы cache.

### Причина

Solid Cache и Rack::Attack используют разные хранилища; падение оставалось на записи каталога в `Rails.cache`.

---

## v1.5 — 2026-05-01

### Изменено

- `.cursor/rules/prd-factory-agent.mdc` — устранен конфликт между "после каждого действия" и батч-режимом записей.
- `.cursor/rules/prd-factory-agent.mdc` — закреплено: `SESSION_STATE` обновляется после каждого действия (кратко, 1-2 строки).
- `.cursor/rules/prd-factory-agent.mdc` — закреплено: `ISSUES` создается сразу при ошибке, статус/решение дополняются в конце логического шага.
- `.cursor/rules/prd-factory-agent.mdc` — закреплено: `CHANGELOG` и `HANDOFF` обновляются батчем в конце логического шага.
- `.cursor/rules/prd-factory-agent.mdc` — добавлено правило сессии: `PRD` и `ARCHITECTURE` читаются полно один раз, дальше опора на `SESSION_STATE/HANDOFF`.

### Причина

Ускорить работу агента без потери контроля: меньше тяжелых записей и повторных перечитываний при сохранении строгого протокола ошибок и трассировки действий.

---

## v1.4 — 2026-05-01

### Изменено

- `.cursor/rules/prd-factory-agent.mdc` — добавлен `Hard Persistence Gate` (fail-closed): без обязательных обновлений `SESSION_STATE/ISSUES/HANDOFF/CHANGELOG` переход к следующему шагу запрещен.
- `.cursor/rules/prd-factory-agent.mdc` — добавлен обязательный стартовый блок новой сессии: `last_done`, `current_state`, `next_step`.
- `.cursor/rules/prd-factory-agent.mdc` — в `Execution Kernel` добавлена обязательная проверка gate перед отчетом шага.

### Причина

Устранить несистемные пропуски операционных записей и гарантировать непрерывность контекста между сессиями без "памяти по умолчанию".

---

## v1.3 — 2026-04-30

### Добавлено

- SESSION_STATE.md — текущее состояние проекта, следующий шаг, блокеры
- HANDOFF.md — текущий спринт, задача, статус
- config/initializers/shop_api_auth.rb — Auth модуль с проверкой API ключа
- config/initializers/shop_api_error_handler.rb — ErrorHandler модуль
- app/policies/* — Pundit политики для всех доменов
- test/integration/shop/* — интеграционные тесты shop API
- test/services/shop/* — сервисные тесты shop

### Изменено

- .cursor/rules/prd-factory-agent.mdc — оптимизирован до v10 (347 строк вместо 1637)
- AGENTS.md — обновлен для v10 (HANDOFF.md в порядке чтения)
- START.md — обновлен для v10 (HANDOFF.md в порядке чтения)
- app/controllers/shop/api/base_controller.rb — CSRF защита изменена на :null_session
- app/controllers/shop/api/cart_controller.rb — валидация параметров
- app/controllers/shop/api/categories_controller.rb — кэширование и пагинация
- app/controllers/shop/api/products_controller.rb — кэширование и пагинация
- app/controllers/shop/api/orders_controller.rb — логирование и пагинация
- app/services/shop/cart_service.rb — лимиты товаров

### Git

- Коммит: f2b157e — fix: исправлены ошибки Shop API и оптимизирована инструкция агента v10
- Пуш: develop обновлен

### Причина

Оптимизация инструкции агента v10. Исправление ошибок Shop API (500 error). Добавлена авторизация, обработка ошибок, валидация, кэширование, пагинация, логирование. Тесты проходят.

---

## v1.2 — 2026-04-30

### Добавлено

- SESSION_STATE.md — текущее состояние проекта, следующий шаг, блокеры
- HANDOFF.md — текущий спринт, задача, статус

### Изменено

- .cursor/rules/prd-factory-agent.mdc — оптимизирован до v10 (347 строк вместо 1637)
- .cursor/rules/prd-factory-agent.mdc — удалена устаревшая версия v6.0
- AGENTS.md — обновлен для v10 (HANDOFF.md в порядке чтения)
- START.md — обновлен для v10 (HANDOFF.md в порядке чтения)

### Причина

Оптимизация инструкции агента для повышения эффективности и снижения контекста. Удалена дублирующаяся устаревшая версия v6.0, оставлена только актуальная v10. Добавлен HANDOFF.md для отслеживания спринтов.

---

## v1.1 — 2026-04-30

### Добавлено

- Правила ведения документов в .cursor/rules/prd-factory-agent.mdc
- Правила чтения SESSION_STATE.md и CHANGELOG.md в AGENTS.md
- Раздел о восстановлении контекста в START.md

### Изменено

- .cursor/rules/prd-factory-agent.mdc — добавлено правило о ведении документов после каждого шага
- AGENTS.md — добавлено правило о чтении SESSION_STATE.md и CHANGELOG.md
- START.md — добавлен раздел "Новый диалог — восстановление контекста"

### Причина

Обеспечить непрерывность контекста между диалогами. Агент теперь автоматически ведёт SESSION_STATE.md, CHANGELOG.md и ISSUES.md после каждого шага.

---

## v1.0 — 2026-04-29

### Добавлено

**Документы PRD Factory:**
- PRD.md — суть продукта, роли, P1/P2/P3, метрики успеха
- ARCHITECTURE.md — структура проекта, схема БД, API-контракты, модули
- AGENTS.md — воркфлоу задачи, правила работы, Definition of Done
- CHANGELOG.md — история изменений
- ISSUES.md — трекер проблем
- START.md — инструкция старта проекта
- SPRINT_1_PROMPT.md — промпт первого спринта
- .env.example — ENV переменные с SHOP_API_KEY

**Код:**
- Shop API авторизация (config/initializers/shop_api_auth.rb)
- Shop API обработка ошибок (config/initializers/shop_api_error_handler.rb)
- Solid Cache конфигурация (config/initializers/solid_cache.rb)
- Модель PromoCode с методом active?
- Промокод coffeefree в seeds (db/seeds_shop_promo_code.rb)

**Миграции:**
- 20260428000001_create_solid_cache_entries.rb
- 20260428000002_fix_rls_product_tenant_settings_franchise_isolation.rb

**Тесты:**
- test/integration/shop/api/categories_controller_test.rb
- test/integration/shop/api/orders_controller_test.rb

**Документация:**
- docs/shop_api_auth.md

### Изменено

**Контроллеры:**
- app/controllers/shop/api/base_controller.rb — CSRF защита
- app/controllers/shop/api/cart_controller.rb — валидация параметров
- app/controllers/shop/api/products_controller.rb — пагинация
- app/controllers/shop/api/categories_controller.rb — пагинация + кэширование
- app/controllers/shop/api/orders_controller.rb — пагинация

**Сервисы:**
- app/services/shop/cart_service.rb — лимиты товаров
- app/services/shop/order_creator.rb — промокоды

**Модели:**
- app/models/refund.rb — исправление lock
- app/models/payment.rb — RLS политика для franchise_manager

**Конфигурация:**
- config/environments/test.rb — memory_store вместо null_store
- config/initializers/rack_attack.rb — логирование с защитой от Hash
- test/support/factories.rb — create_mobile_customer!, login_as! с tenant_id

### Причина

Привести документацию к единому процессу PRD Factory и обеспечить непрерывность контекста между диалогами.
