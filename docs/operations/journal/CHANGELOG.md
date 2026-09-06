# CHANGELOG

## Шапка

**Текущий месяц:** `2026-09`  
**Архив:** [`archive/README.md`](archive/README.md) — `CHANGELOG-2026-06.md` … `CHANGELOG-2026-08.md`

> Агент: **не читать** весь CHANGELOG на старте. Писать новую запись сверху текущего месяца. Архив — по запросу.

---

## Текущий месяц (2026-09)

## 2026-09-06 — REVIEW: #35 QA reopen compact status sheet

- bugbot: no bugs · security: no issues
- Local: JS 60 · rails 15 PASS · Entire `01M1V0RTYSBYRP8NWWEAWR24W0` на `fa7d6d75`
- Push develop · CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34026092095
- Deploy / Fly MCP Point A — только по апруву

## 2026-09-06 — regress: #26 step5 pay inline PASS

- JS: payment_error + repeat_invalid_token **29/0**
- rails: repeat_invalid_token_payment **12/0**
- Next: `/review` · Fly MCP Point A ещё для заказчика

## 2026-09-06 — regress: #35 QA status sheet PASS

- JS: cancel/accordion/sheet/notify **60/0**
- rails: acceptance+mount **15/0** · peek/expanded stack **9/0**
- Next: `/review` · Fly MCP Point A ещё для заказчика

## 2026-09-06 — REVIEW: CartSheet «Итого» (правка 5)

- GREEN `7d7cfbec` · fix thousands `91daaf19` · Entire `01M1V145Z4ABQQM5APY2EXEG6N`
- bugbot: hidden total → `formatThousands` · security: no issues
- Local: cart zone 36/0 · Next: deploy по апруву

## 2026-09-06 — GREEN: #35 QA reopen compact status sheet

- RED `785fa2e3` · GREEN `7ab3f3e6` · Entire `01M1V0RTYSBYRP8NWWEAWR24W0`
- Post-pay → `/` + compact sheet; status без receipt; cancel hint «1–3 дня»; X = Скрыть
- Local: JS zone 60 PASS · rails acceptance/mount 15 PASS

## 2026-09-06 — SPEC: #71 QA reopen email remember / don’t re-ask

- Канон: после первого email для чека — блок не показывать на следующих заказах
- `todo.md` → #71 · SPEC `[x]` · RED `[ ]`
- Решение: tenant LS receipt-email + hide `OrderSuccessEmailBlock` в `PaymentResult`

## 2026-09-06 — feat: CartSheet видимое «Итого» (правка 5) [GREEN]

- `checkoutBar`: слева **Итого N₽** (`shop-cart-order-total`), справа кнопка `+N₽`
- Hidden: `shop-cart-hidden-total` без `sr-only`
- Тесты: `cart_checkout_button_total_dynamic` + регрессия b113/quick_repeat PASS
- Next: `/review`

## 2026-09-06 — docs: #71 QA reopen (email remember, don’t re-ask)

- Фидбек заказчика: почту после оплаты для чека — **запомнить**, на следующих заказах **не спрашивать**
- ТЗ #71 без перезаписи; артефакт `…/email_collection_after_payment/`
- CBR #71 → QA reopen · Next `/spec`
- Мета: правки заказчика — **как сказано** (очередь 1–5 + эта)

## 2026-09-06 — SPEC: #26 QA reopen step5 inline pay error

- Root: `resolveCheckoutSheetInlineError` → null; G7 `$effect` сбрасывает FSM/selection
- Решение: friendly label в слот sheet; selection сохранить; CTA click → new card
- `todo.md` → #26 · SPEC `[x]` · RED `[ ]`

## 2026-09-06 — docs: #26 QA reopen (pay error inline copy)

- Фидбек заказчика: отказ карты есть, **нет** пояснения («попробуйте другую карту» / что делать)
- ТЗ #26 без перезаписи; артефакт `…/repeat_order_invalid_token_payment_sheet/screenshots/qa_2026-09-06/`
- CBR #26 → QA reopen · #35 на паузе · Next `/spec`

## 2026-09-06 — SPEC: #35 reopen QA статусной шторки

- Заказчик: 3 правки (home post-pay full-screen; X/состав/cancel 1–3д; UX референс)
- `todo.md` → #35 reopen · SPEC `[x]` · RED `[ ]`
- QA скрины → `artifacts/order_status_compact_sheet_push/screenshots/qa_2026-09-06/`
- Решения: PaymentResult → `/`; status row без receipt; CTA hint 1–3 дня; X = dismiss

## 2026-09-05 — deploy v480 + Fly MCP ×3 Point A PASS

- `git push` develop up-to-date · CI green `33951901384`
- `fly deploy --remote-only --depot=false` → **v480** `deployment-01M1R6VMAJFWR0VDA4V5TCGRJ7`
- MCP-1 offer rollback: УК OFF + config `enabled=false` + ready CTA tips · PASS
- MCP-2 promo `amount_rub` 11→15→11 via `point_campaign_settings` · PASS (live charge SKIP)
- MCP-3 #78: `subscription_*` tables on Fly · shop smoke PASS · purchase E2E SKIP (no API/UI)
- Sentry 24h new: none · Fly logs: OK
- Artifacts: `…/mcp/fly_v480_2026-09-05/` (offer / promo / subscription_billing)

## 2026-09-05 — review: #78 subscription slice-1

- bugbot: no bugs · security HIGH → fix webhook `subscription_intent` → closed + PaymentFulfillment
- Local: purchase + PaymentStatusUpdater + qa_2_3/order_creator PASS
- Push `develop` → CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33951753636
- Entire: `01M1R4VQH6TPMM6SQ2RZ5JTM46` на `cb02d8b4`
- Deploy / Fly MCP: **только по апруву**

## 2026-09-05 — REVIEW: promo amount from point_campaign_settings

- bugbot: no bugs · security: no medium+ · Local 43 runs PASS
- Push `develop` → CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33951212810
- Entire: `01M1R4VQH6TPMM6SQ2RZ5JTM46` · impl GREEN `34a899d4`
- Deploy / Fly MCP Point A: **только по апруву** (live Subtask 12)

## 2026-09-05 — ops: /regress #78 subscription PurchaseService PASS

- `purchase_service_test` 1/19 PASS
- `qa_section_2_3_payment_cart` + `order_creator` 23/44 PASS
- Next: `/review`; Fly MCP Point A — после deploy

## 2026-09-05 — regress: promo amount from config PASS

- growth_promo 13 + point_campaign 4 + user_cards 3 + qa_2_3 2 + order_creator 21 — 0 failures
- Next: `/review`; Fly MCP Point A — после deploy

## 2026-09-05 — REVIEW: emergency disable subscription offer Point A

- bugbot: no bugs · security: no medium+ · Local regress PASS
- Push `develop` → CI **green** https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33950595431
- Entire: `01M1P2BSG7MY3C0VM0FXCSZXRK` · Point A offer remains OFF (config, no deploy needed)
- Deploy: не требуется для этого отката (уже на Fly v479)

## 2026-09-05 — feat: promo amount from point_campaign_settings [GREEN]

- `GrowthPromo.promo_amount_rub(tenant)` ← `config["promo_amount_rub"]`; fallback `DEFAULT_PROMO_AMOUNT_RUB`
- `AMOUNT_RUB` alias на DEFAULT; UserCards API `amount_rub` с того же helper
- Entire: `01M1R4VQH6TPMM6SQ2RZ5JTM46` (impl `34a899d4`); next `/regress`

## 2026-09-05 — docs: SPEC #78 subscription billing slice-1

- todo: plans/subscriptions + PurchaseService; backlog usage/renewal/API/UI
- Не ломать: checkout, binding, webhook idempotency, #77 offer OFF
- Next: `/sbr` RED

## 2026-09-05 — docs: intake #78 Архитектура подписки

- customer_tasks + CBR + artifacts `subscription_billing_architecture/`
- Scope: plans/subscriptions/usage, Purchase/Renewal/Cancel, Shop API, PWA, jobs; без правок `TbankAdapter`
- Next: `/spec`; Задача-2 promo parked

## 2026-09-05 — regress: subscription offer zone PASS (post-rollback)

- Local: rails 20/79 PASS + CTA JS 16 PASS
- UK Point A recheck: `enabled=false`, `second_cta_mode=tips`
- CTA matrix: offerOff → tips on ready (no subscription stub)

## 2026-09-05 — ops: emergency disable subscription offer (Point A) [GREEN]

- УК PATCH Point A: `enabled=false` + `second_cta_mode=tips` (было subscription)
- Audit: в УК visible только Point A (SINGLE_POINT_A); других risky нет
- Verify: `GET /shop/api/config` → `subscription_offer.enabled=false`
- Artifact: `subscription_offer_eligibility/ops/rollback_point_a_2026-09-05.json`
- Код CTA/eligibility / `INTEGRATIONS.md` не менялись; ready CTA E2E → `/regress`

## 2026-09-05 — SPEC: promo amount from point_campaign_settings

- Задача-2: `price!` / `charge_amount` / API `amount_rub` ← `promo_amount_rub`; дефолт один (`DEFAULT_PROMO_AMOUNT_RUB`)
- Scope: GrowthPromo + UserCardsController + тесты; Tbank/antifraud/subscriptions вне
- Next: `/sbr` RED; subscription-offer rollback → **done** (см. запись выше)

## 2026-09-05 — SPEC: emergency disable subscription offer (Point A)

- Config-only rollback plan: УК `subscription_offer_setting` → `enabled=false`
- Point A `2fdee1ac-4674-41ee-b89e-87b45643f789`; код CTA/eligibility не трогаем
- todo: Audit SELECT → GREEN УК → CTA verify → DEMO_FEEDBACK

## 2026-09-04 — ops: clear stuck T-Bank pending (StuckPayments spam)

- Fly runner: mark `tbank` pending/processing `< 2026-09-01` → `failed` (186); related `pending_payment` orders → `cancelled` (182)
- Also cleared 2 Point A MCP leftovers from 2026-09-04 (live charge SKIP)
- `STUCK_ALERT_CANDIDATES_NOW=0` (Telegram StuckPaymentsCheckJob quiet)
- One-shot scripts under `tmp/` (not productized)

## 2026-09-04 — fix: Sentry RUBY-1F / RUBY-16 runner Current noise

- `SentryNoiseFilter`: `LocalJumpError` + `tags.source=runner` (пустой transaction)
- `Current.assign!` — assign без блока (вместо ошибочного `set!` / `set` без `do`)
- Tests: noise filter + Current
- Fixes RUBY-1F · Fixes RUBY-16

## 2026-09-04 — deploy: Fly v479 + MCP #75/#76/#77 Point A

- `fly deploy` → **v479**; release: ConcurrentMigrationError → soft-skip when schema current (`fly_release.rake`)
- MCP Point A: #76 PASS · #75 UI PASS (live charge SKIP) · #77 A–F PASS
- Artifacts: `…/mcp/fly_v479_2026-09-04/`
- Next: апрув заказчика

## 2026-09-04 — review: #77 subscription offer eligibility · CI

- bugbot: no bugs · security: no medium+
- follow-up: wire config/profile into OrderActionButtons + OrderStatus; subscription → ЛК
- docs: shop-api + pwa-realtime (#77)
- Entire: `01M1P2BSG7MY3C0VM0FXCSZXRK` на `4087ad4e`
- Next: deploy апрув · Fly MCP Point A

## 2026-09-04 — ops: /regress #77 PASS subscription offer zone

- eligibility + settings + profile/UK API: 20 runs / 79 assert PASS
- push_register + orders_email: 10 runs / 38 assert PASS
- Next: `/review` · Fly MCP Point A после deploy

## 2026-09-04 — fix+review: #76 kitchen disables promo · REVIEW

- bugbot medium: смена типа на `production_kitchen` гасит `card_binding_promo` (counter сохранён)
- security-review: no medium+
- Entire GREEN: `01M1P2BSG7MY3C0VM0FXCSZXRK` на `6c1966d2`
- Next: CI green · deploy апрув · Fly MCP Point A

## 2026-09-04 — ops: /regress #76 PASS

- Platform/promo: 31 runs / 96 assert PASS
- order_creator + user_cards_sbp: 23 runs / 50 assert PASS
- Next: `/review` · Fly MCP Point A после deploy

## 2026-09-04 — docs: SPEC #77 subscription offer eligibility

- todo.md: signals на mobile_customers · settings per-point · Eligibility service · profile/config · CTA + appinstalled
- Решения §4: fallback=tips · enum tips|subscription · completed_orders query · без денормализации
- Не ломать: orders_count · CTA при enabled=false · FCM/email · PWA banner · Tbank/фискал/11₽/billing
- Проверка: eligibility + settings + profile API; регресс push_register + orders_email

## 2026-09-04 — docs: intake #77 subscription offer eligibility

- ТЗ 1:1: `customer_tasks/Умный показ оффера подписки — сигналы толерантности и УК-переключатель.md`
- Artifacts: `subscription_offer_eligibility/`
- CBR #77; #76 parked (SPEC done → `/sbr`); фокус сессии → `/spec` #77

## 2026-09-04 — docs: SPEC #76 point_campaign_settings

- todo.md: Tenant=точка · УК form/show · GrowthPromo.point_allows_promo? · sync upsert
- Не ломать: checkout full price · attempts semantics · изоляция точек
- Проверка: tenants_controller + growth_promo + order_creator / user_cards

## 2026-09-04 — docs: intake #76 УК point campaign promo 11₽

- ТЗ 1:1: `customer_tasks/УК — включение промо 11₽ при создании точки.md`
- Artifacts: `uk_point_campaign_promo_11rub/`
- CBR #76 + README customer_tasks; #75 статус → REVIEW+follow-up

## 2026-09-04 — fix(ci): soft-skip importmap audit on npm transport flake

- `scan_js`: retry ×3; после 3× `Net::ReadTimeout` → warning + exit 0
- Реальные vuln findings по-прежнему валят job
- `config/ci.rb` — тот же контракт

## 2026-09-04 — fix(ci): retry importmap audit on npm ReadTimeout

- `scan_js`: 3 попытки с backoff вокруг `bin/importmap audit` (флейк `Net::ReadTimeout`)
- `config/ci.rb`: тот же retry для локального `bin/ci`
- Реальные уязвимости по-прежнему валят job (без continue-on-error)

## 2026-09-04 — feat: #75 follow-up velocity phone_status Checkout PII

- `BindingVelocity` 15м (hash/phone/device/IP/BIN; BIN не для СБП)
- `phone_status` enum + `BindingStepUp` (OTP только телефон аккаунта)
- Checkout `promoEligible`/`cartTotalRub` + `growth_promo` в `/user/cards`
- `phone_digest` + `purge_expired!`; SBP `dedupe_active_sbp_method_hashes!`

## 2026-09-04 — fix: #75 REVIEW growth promo amounts + mark_used

- `GrowthPromo.price!` — discount под `chk_order_amounts`
- `consume_from_payment!` после успешной card/SBP bind
- SBP init применяет 11₽ при `save_sbp_account`
- Receipt: одна позиция 11₽ при `growth_promo_intent`

## 2026-09-04 — feat: stuck payments cron + channel order stats log

- `config/recurring.yml`: `Payments::StuckPaymentsCheckJob` every 15m (TelegramAlertJob без дедупа)
- `Analytics::ChannelOrderStatsJob` + Collector — счётчики `orders.source` / 15m / `open_now`, только лог `[ChannelOrderStats]`
- Без правок `Health::TenantChecker`; без Telegram на stats
- Local: analytics collector+job PASS

## 2026-09-04 — ops: /regress #75 binding+promo PASS

- payments+growth 28 runs PASS · order_creator+qa§2.3 23 PASS · i18n 4 PASS
- Зона: shop/оплата · Fly MCP Point A ещё нужен для заказчика
- Next: `/review`

## 2026-09-04 — docs: SPEC #75 binding + promo 11₽

- `todo.md` — SBR фазы, 7 файлов (SavedCardStore / SbpAccountTokenStore / MPM / OrderCreator / PaymentMethodsSheet + net-new attempts + growth_promo)
- Не ломать: полная оплата · UserCards/one-click · СБП bind · callback
- Проверка: saved_card_store + sbp_account_token_store; order_creator + qa §2.3 cart
- Ждёт `/sbr` RED

## 2026-09-04 — docs: intake #75 Привязка способа оплаты и промо 11₽

- ТЗ 1:1: `customer_tasks/Привязка способа оплаты и промо 11₽.md`
- Артефакты: `artifacts/payment_method_binding_promo_11rub/` (скрин шторки + P2 placeholder)
- CBR / README: строка #75 · статус intake · ждёт `/spec`
- Задача 1 из 3 (две следующие ещё не присланы)

## 2026-09-02 — feat: УК single-point lists (UkCatalogScope)

- `Platform::UkCatalogScope` — в `DEMO_SINGLE_POINT` только Point A + org в `/admin`
- Без single-point: только `active` sales_point (inactive/prog10 скрыты)
- Скрыты «Новая точка/орг» в single-point; show/edit по id не трогаем
- Тесты: uk_catalog_scope + uk_single_point_dashboard (9 runs PASS в зоне)

## 2026-09-02 — feat: single Point A prod (Fly cleanup + DEMO_SINGLE_POINT)

- `Platform::ProdSinglePointCleanup` — inactive лишних sales_point, без DELETE
- `DEMO_SINGLE_POINT=true` + `SHOP_DEFAULT_TENANT_ID` в `fly.toml`
- `fly:release` → `platform:prod_single_point` после `demo:seed`
- Deploy **v474** · release `[platform:prod_single_point] OK`
- Активны: **demo-point-a** + demo-prep-kitchen (backend)
- Артефакт: `artifacts/single_point_a/cleanup_2026-09-02.json`
- Тесты: platform cleanup + environment_setup + RLS (19 runs PASS)

## 2026-09-02 — ops: ctx-trim токенов (rules + todo + ISSUES)

- Удалены 7 дублей `.cursor/rules/coffeeos-*.mdc` в корне (канон — `project/`)
- Сжат always-бандл: `.cursorrules`, `coffeeos-index.mdc`, `coffeeos-agent-workflow.mdc`
- `todo.md` → stub deploy pending; полный SPEC → `session/archive/todo-shift-close-2026-09.md`
- ISSUES 🔴 — короткая таблица (ID / статус / блокер)
- `coffeeos-performance` globs: убран `test/**`
- **~600 tok/ход** always rules · **~650 tok/старт** todo+ISSUES · **~200 tok/edit** без дублей globs

## 2026-09-01 — chore: uploads gitignore (меньше шума в git status)

- `.gitignore`: убран `!/public/uploads/products/` — картинки локально/Fly эфемерны, в git только README
- Удалены 15 тестовых файлов из `public/uploads/products/` (MCP/локальные загрузки)

## 2026-09-01 — ops: ctx-trim + архив августа

- Коммит `e929d3bd` · ops ref `5b1519a5`
- Команда `/ctx-trim` + правило `coffeeos-context-hygiene.mdc` (ручной + weekly пт–вс)
- Архив: `handoff-2026-08.md`, `session_state-2026-08.md`, `CHANGELOG-2026-08.md`, `ISSUES-resolved-through-2026-08.md`
- Живые HANDOFF/SESSION/CHANGELOG/ISSUES — шапка + сентябрь; **~4k tok** экономии на старте vs проглатывание августа
