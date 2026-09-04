# CHANGELOG

## Шапка

**Текущий месяц:** `2026-09`  
**Архив:** [`archive/README.md`](archive/README.md) — `CHANGELOG-2026-06.md` … `CHANGELOG-2026-08.md`

> Агент: **не читать** весь CHANGELOG на старте. Писать новую запись сверху текущего месяца. Архив — по запросу.

---

## Текущий месяц (2026-09)

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
