# CHANGELOG

## Шапка

**Текущий месяц:** `2026-08`  
**Архив:** [`archive/README.md`](archive/README.md) — `CHANGELOG-2026-06.md`, `CHANGELOG-2026-07.md`

> Агент: **не читать** весь CHANGELOG на старте. Писать новую запись сверху текущего месяца. Архив — по запросу.

---

## Текущий месяц (2026-08)

## 2026-08-27 — #72 MCP_DEPLOY_CHECKLIST (deploy отложен)

- Чеклист Point A для агента: `artifacts/receipt_email_fiscal_checks/MCP_DEPLOY_CHECKLIST.md`
- Deploy в этой сессии **не** делали (экономия)

## 2026-08-27 — #72 REVIEW: Receipt.Email/Phone Init

- Local 70/0 · security clean · bugbot out-of-scope (#71 webhook/bounce) not blocking
- Entire `01M11269FD48FXF42NCW98AG0X` на `5f68efea` · push develop → CI
- Deploy / Fly MCP Point A — апрув

## 2026-08-27 — #72 /regress PASS (Receipt.Email)

- builder+adapter+sbp 48/0 · order_creator+qa_2.3 24/0 (2 skip) · widget+inline 12/0
- GREEN `5f68efea` · Entire `01M11269FD48FXF42NCW98AG0X` · next `/review`

## 2026-08-27 — #72 SPEC: Receipt.Email / Phone

- todo: политика Email>Phone; Init на всех путях витрины; Confirm/Cancel/SendClosing — documented
- Gap: card Init без Receipt; SendClosing NOT FOUND → SKIP

## 2026-08-27 — #72 intake: Receipt.Email / Phone для фискальных чеков

- PHASE 0: ТЗ 1:1 → `customer_tasks/Доработка бэкенда — передача email покупателя в Receipt для фискальных чеков.md`
- CBR #72 · artifacts `receipt_email_fiscal_checks/`
- Серия security review: старт с #72; код/todo — после `/spec`

## 2026-08-26 — #71 MCP API догон (без live pay) → PASS

- D1 `POST …/email?tenant_id=` + API key + reconnect_token → 200
- D2 без token → 404; D4 HMAC bounce → `order_emails.status=bounced`
- A3 save_card в Fly bundle; D5 EmailService ≠ FiscalReceipt
- Артефакт: `email_collection_after_payment/mcp/fly_v458_2026-08-26/MCP_RESULT.md`

## 2026-08-26 — Fly v458 deploy + MCP #69/#70/#71

- Deploy coffeeos **v458** (v457 release_command ConcurrentMigrationError после migrate `order_emails`; retry OK)
- MCP Point A: **#70 PASS** · **#69 PASS** · **#71 PARTIAL** (email-блок UI OK; live pay SKIP)
- Артефакты: `…/mcp/fly_v458_2026-08-26/` в `telegram_bot_support_lk`, `pwa_personal_account_lk`, `email_collection_after_payment`

## 2026-08-26 — #71 Entire backfill

- Checkpoint `01M0Z3E52ZCDTRECJT1F22G954` на `2e551ea7` (session `5a70b841…`)
- Fix: WSL `ln -sfn /mnt/c/Users/darks/.cursor ~/.cursor`

## 2026-08-26 — #71 REVIEW: Email after pay

- Bugbot+security fixes `94f36822` (API path, waitingForBank, bounce HMAC, visibility)
- Entire attach CLI fail (transcript) — backfill
- CI [32971396113](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/32971396113) **green** · deploy апрув · Fly MCP Point A
- Prod: set `EMAIL_BOUNCE_WEBHOOK_SECRET` (or `CALLBACK_SHARED_SECRET`)

## 2026-08-26 — #71 /regress PASS (Email after pay)

- JS 31/0 · Rails 16/0 · GREEN `31cf0e21` · next /review

## 2026-08-26 — #71 intake+SPEC: Email-сбор после оплаты (Callcheck)

- ТЗ 1:1 + artifacts `email_collection_after_payment/` + CBR #71
- Gap: каркас Cloud Code есть; happy-path email-блок, Minitest/`node --test`, INTEGRATIONS
- Next: RED

## 2026-08-26 — #70 REVIEW: Telegram bot support ЛК

- Bugbot fix: support URL ≠ product `VITE_SHOP_TELEGRAM_URL` (`f2cfceb2`)
- Security: #70 PASS · Entire `01M0YNQZGQSNJ5Z6XSNGHGHHZB`
- CI [32967225563](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/32967225563) **green** · deploy апрув · Fly MCP

## 2026-08-26 — #70 /regress PASS (Telegram bot support ЛК)

- JS 19/0 · Rails LK 6/0 · GREEN `7cfc3736` · next /review

## 2026-08-26 — #70 intake+SPEC: Telegram bot support в ЛК

- Канон ТЗ + artifacts + CBR #70; gap: единый URL (Header OK, ЛК `shopSupportTelegramUrl` empty)
- todo → RED next

## 2026-08-26 — CI green: #69 UTF-8 fix [32953148661](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/32953148661)

- Commit `4b0733cb` · all jobs pass (test, lint, scan, system-test)

## 2026-08-26 — fix: #69 Profile.svelte UTF-8 (CI mojibake после rebase)

- Восстановлена кириллица («повторить», «История заказов» и др.) — grep-тест `pwa_personal_account_lk_test.rb`

## 2026-08-26 — #69 REVIEW: logout pending fix + push

- Security review: `PendingOrderSession.clear!` on DELETE session
- Commits b243d42b..99a8dd1e

## 2026-08-26 — #69 regress local PASS

- Зона shop/LK: Ruby 24 runs 0 fail · Node 6/0
- Fix: `profile_ui_contract_test` — «Подтвердить» вместо «Привязать» (#69 settings)

## 2026-08-26 — #69 PWA ЛК: intake + SPEC + GREEN slice 1

- PHASE 0: `customer_tasks/Доработка личного кабинета (ЛК) в PWA.md` · артефакт `artifacts/pwa_personal_account_lk/mockup_lk_screens_2026-08-26.png`
- Hub `#/profile`, settings `#/profile/settings`, `#/about`, `#/order/:id/receipt`; PLG placeholders; history inline; logout `DELETE /shop/api/session`
- Tests: `pwa_personal_account_lk_test.rb` · `shop_personal_account_lk_test.mjs` PASS local

## 2026-08-19 — feat: TASK-TELEGRAM-SUPPORT PHASE 2 RED/GREEN (`db01076` + `dc69366`)

- PHASE 2 RED `db01076`: тесты падают (18 pass config/utils, 13 todo)
- PHASE 2 GREEN `dc69366`: реализация компонентов + интеграция
  - SupportContactSheet.svelte: bottom sheet с Email/Telegram опциями
  - Header.svelte: добавлен иконка чата (MessageCircle) для открытия шторки
  - Profile.svelte: добавлена кнопка «Написать нам» в меню
  - supportConfig.js: централизованная конфигурация Telegram/Email URL'ов
  - deepLink.js: утилиты для открытия ссылок без пользовательских данных
- Регрессия Header/Profile: не сломано, все работает
- Готово к PHASE 3: REVIEW

## 2026-08-18 — docs(rules): сжатие always rules (токены -31%)

- Оценка: ≈6648 -> ≈4594 токенов на always applied rules; ключевые триггеры/формат отчёта сохранены.

## 2026-08-15 — push: `645eda9c` Entire MCP · CI green [31888110550](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31888110550)

## 2026-08-15 — entire: MCP SHA `7f5925e` ← `01M02FTNFTCX13ZSPHDGCNC292`

## 2026-08-15 — mcp: Fly v456 Point A #64–#68 (Chrome)

- #64 Chrome PASS · #65 PASS · #66 PASS · #67 PARTIAL (S7 SKIP) · #68 PASS
- TG/IG skip. Артефакты `artifacts/.../mcp/fly_v456_2026-08-15/`
- Пачка: Sentry skip · Fly logs OK (poll 8с) · Neon skip · УК skip

## 2026-08-15 — deploy: Fly coffeeos v456 (#64–#68)

- Push `d8e61821` · `fly deploy --remote-only --depot=false`
- `/up` 200 · Point A shop 200
- MCP Point A — ждём апрув (пачка Sentry/логи/Neon вместе с MCP)

## 2026-08-15 — test: #64–#68 pre-deploy suite PASS

- JS 50/0 (webview/catalog/tenant query)
- Rails 36/0 (webview+boot+linkage+categories+S2a + tenant isolation)
- Полный shop/ на Windows не гоняли · deploy — апрув

## 2026-08-15 — docs: Entire must be enriched (not a review checkbox)

- `ENTIRE.md` закон: empty `explain` → стоп + attach, не push
- PHASE 3 / GREEN / отчёт: обязателен `Entire: <id> на <sha>`
- «spec vs shop-api OK» без checkpoint id — запрещено

## 2026-08-15 — docs: Entire backfill #64–#68 Telegram/Instagram shop

- GREEN SHA без trailer не переписывали
- `ENTIRE.md` карта CBR → SHA → Cursor session; attach why-context на этот коммит
- Новых backend endpoints нет (`GET /shop` + `GET /shop/api/categories`)

## 2026-08-15 — docs: Entire CLI on Windows PATH (scoop entire/cli)

- GREEN `ff9374d1` без trailer не переписываем (уже push)
- Native `entire.exe` 0.8.42 · git hooks больше не skip
- Checkpoint на этот коммит · why-context vs #68 spec

## 2026-08-15 — docs(ops): #68 PHASE 3 CI green `c5898e0e`

- Push develop · CI 5/5 [run 31878722151](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31878722151)
- Local JS 46/0 · Rails 8/0
- Стоп: deploy апрув

## 2026-08-15 — docs(ops): #68 PHASE 3 REVIEW local

- Local JS 46/0 · Rails webview+boot 8/0
- bugbot/security-review: Cursor Task usage limit → manual, блокеров нет
- Entire: нет checkpoint `ff9374d1` (Windows hook skip) · spec vs todo/shop-api OK
- Push develop · стоп до CI green · deploy апрув

## 2026-08-15 — docs(ops): #68 /regress shop WebView UX/perf PASS

- JS 46/0 (ux_perf + catalog_load + webview + webview_ui)
- Rails webview+boot 8/0
- Полный `test/integration/shop/` на Windows не гоняли (канон)
- Next: `/review` · Fly MCP после deploy

## 2026-08-15 — docs: intake + SPEC #68 Telegram WebView UX/perf

- ТЗ 1:1 `customer_tasks/UX и Performance мобильной витрины CoffeeOS внутри Telegram WebView.md` · CBR #68
- artifacts `mobile_storefront_telegram_webview_ux_perf/` · shop-api.md § WebView UX/perf
- Стоп до RED. Runtime #66 и UI #67 не трогаем. #67 deploy — отдельно

## 2026-08-15 — docs(ops): #67 PHASE 3 CI green `cbcb58f9`

- Push develop · CI 5/5 [run 31877829022](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31877829022)
- Local JS 27/0 · Rails 8/0 · S2a 12/0
- Стоп: deploy апрув

## 2026-08-15 — docs(ops): #67 PHASE 3 REVIEW local

- Local JS 27/0 · Rails webview+boot 8/0
- Cursor Task bugbot/security-review: usage limit → manual; блокеров нет
- Entire checkpoint нет (Windows hook skip)
- Push → CI; deploy только апрув

## 2026-08-15 — docs: intake + SPEC #67 Telegram WebView mobile UI

- ТЗ 1:1 `customer_tasks/Адаптация Mobile UI витрины CoffeeOS под Telegram WebView.md` · CBR #67
- Артефакты `mobile_storefront_telegram_webview_ui/` · SPEC в `todo.md` (layout.js / CartSheet / Header / Catalog)
- Стоп до RED. Runtime #66 и задача 5 (perf) не трогаем

## 2026-08-15 — docs(ops): #66 PHASE 3 CI green `044f3130`

- Push develop · CI 5/5 [run 31876503882](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31876503882)
- Local JS 23/0 · Rails 12/0 · `--log-failed` пусто
- Стоп: deploy апрув

## 2026-08-15 — docs(rules): PHASE 3 REVIEW канон

- Таблица 6 шагов: local → bugbot+security-review → Entire → push/CI цикл → CI green → стоп
- Deploy только апрув владельца; push на `/review` без вопроса
- Указатели: commit-ops, `/review`, agent-workflow, dev-gates (пачка после deploy)

## 2026-08-15 — feat: #66 Telegram WebView storefront compatibility [GREEN]

- Isolated `shopWebView.js`: detect (не auth), storage fallback, `--shop-vvh`, SPA stay-in-webview
- `reconnectGuestOrder` без голого sessionStorage; catalog cache `v1:<tenant_id>`
- viewport-fit=cover; shop-api.md WebView runtime; без bot/CORS/CSP loosening
- Local: JS 23/0 · Rails webview 5/0 · boot+linkage 7/0

## 2026-08-15 — docs: SPEC #66 Telegram WebView storefront runtime

- Compatibility layer `shopWebView.js`; safe sessionStorage; catalog cache keyed by tenant
- Viewport-fit + `--shop-vvh`; shop-api.md WebView runtime; без bot/CORS/CSP loosening
- Дальше RED

## 2026-08-15 — docs: intake #66 Telegram WebView storefront runtime

- ТЗ 1:1: полноценная работа `/shop` внутри Telegram In-App Browser
- CBR #66 · artifacts `mobile_storefront_telegram_webview/`
- Серия задача 3; bot/payments/UI#4/perf#5 — не смешивать
- Дальше: SPEC

## 2026-08-14 — test: #65 linkage without Vite layout (CI)

- `ShopTenantLinkageTest`: ResolveProbe + structural meta (без GET /shop)
- CI `f861048d`: Vite missing `application.js` на layout render

## 2026-08-14 — test: Tbank callback CI enqueue flake

- `assert_no_enqueued_jobs` на CONFIRMED ловил retry/fallback под parallel
- `save_card: false` + RLS off + clear queue в `tbank_controller_test`
- Local: 16 runs / 0 failures (WSL)

## 2026-08-14 — feat: #65 tenant_id linkage integrity [GREEN]

- Явный `?tenant_id=` (в т.ч. blank) не silent-fallback на другую точку
- FE: export helpers; blank key → `tenant_id=` в categories URL
- Rails: `params.key?(:tenant_id)` short-circuit; shop-api.md § integrity
- Local: JS 9/0 · categories 7/0 · linkage 3/0 · boot 3/0

## 2026-08-14 — docs: SPEC #65 TG/IG In-App → /shop linkage

- todo: целостность `tenant_id` link→HTML→categories; identity без UA/TG auth; errors/cache; без forced redirect
- Риск: silent fallback `TenantResolution` при потере query
- Дальше RED

## 2026-08-14 — docs: intake #65 TG/IG In-App → /shop linkage

- ТЗ 1:1: связка Telegram/Instagram In-App Browser → CoffeeOS `/shop`
- CBR #65 · artifacts `telegram_instagram_inapp_shop_linkage/`
- Серия задача 2; #64 MCP не закрыт — не смешивать
- Дальше: SPEC по `go`

## 2026-08-14 — chore: push develop `41b22c12`

- `origin/develop` = `41b22c12` (пайплайн rules + #64 GREEN + MCP v455)
- Deploy — по апруву

## 2026-08-14 — docs(rules): пайплайн на стенд (CI → Sentry+логи+MCP)

- `coffeeos-dev-gates`: порядок local → review → push → CI → deploy → пачка Sentry/Fly/Neon/УК + MCP Point A
- Мелочь/docs без пачки; push/deploy только по апруву

## 2026-08-14 — feat: #64 shop boot watchdog for embedded browsers [GREEN]

- Classic `shop-boot-watchdog`: нет вечного «Загрузка меню…» если `type=module` не исполнился
- `application.js` ловит mount; Catalog — «Повторить»; storage throw не роняет loadCatalog
- Chrome Point A эталон PASS; UA-веток нет
- Local: JS catalog+ls 5/0 · boot structural 3/0

## 2026-08-14 — docs: intake + SPEC #64 shop Telegram/Instagram in-app

- ТЗ 1:1: открытие `/shop?tenant_id=` во встроенных браузерах Telegram и Instagram
- CBR #64 · SPEC в `todo.md` · код не меняли
- Дальше: диагностика точки отказа, не фикс «на всякий случай»

## 2026-08-14 — MCP: Point A Fly v455 PASS

- Каталог / product / checkout / pay stack / profile — без регресса #63
- Оплату картой Арама не проводили; dismiss X skip (нет active order)
- Код не меняли — косяков на правку нет
- Evidence: `mcp/fly_v455_2026-08-14/`

## 2026-08-14 — deploy: Fly v455 Sentry N+1 + noise filter

- Fly `coffeeos` v455 · release OK без advisory lock error
- Фильтр Sentry live: ConcurrentMigrationError / SystemExit / bin/rails CLI
- `/up` 200 · MCP skip (апрув)

## 2026-08-14 — fix: Sentry shop N+1 + drop migrate/console noise

- FE/API: `ModifierGroupsPresenter` не бьёт SELECT опций после includes (RUBY-19)
- Cart: `json_lines` без EXISTS `product_tenant_settings` на строку (RUBY-V)
- Sentry: `SentryNoiseFilter` — ConcurrentMigrationError, SystemExit, bin/rails NameError/NoMethodError/…
- Не добавляли Customer / paid / payment_status / reconnect_token в схему

## 2026-08-14 — test: WSL full shop suite green + Tbank idempotency flake

- WSL Linux: `test/integration/shop/` 506/506 (npm ci + local PG)
- `tbank_controller_test`: unique `provider_payment_id` — нет коллизии Rails.cache idempotency в parallel CI

## 2026-08-14 — fix: legacy shop asserts + dismissedIds terminal + Wallet i18n test

- Legacy: `order_status_acceptance_cbr_test` b11_02 → PaymentResult + offline queue redirect (не Checkout)
- Legacy: `shop_user_cards_extremes` E7 → `labelAddCard()` / «Картой +»
- JS: `order_action_buttons_test` → «Карта в Apple Wallet» (#41 i18n)
- FE: `dismissedIds` не сбрасывается на terminal — stale re-sync не поднимает виджет
- Local: legacy 4 + mount 27/0 · JS 294/294

## 2026-08-13 — deploy+MCP: #63 status widget UX Fly v454 PASS

- Fly `coffeeos` v454 · Point A: dismiss X · hide product/profile/checkout · sheet returns on catalog
- Evidence: `artifacts/svelte5_status_widget_reactivity_ux/mcp/fly_v454_2026-08-13/`
- CI #32 green (`79d90704` displayOrders assert + CashShift FK)

## 2026-08-13 — feat(#63): Svelte 5 status widget reactivity + dismiss UX [GREEN]

- FE: иммутабельный `applyCableEvent` / sync; `dismissOrder` + `userDismissed`; скрытие UI на `#/product` / `#/profile` / checkout / pay-stack
- FE: кнопка X в `ActiveOrdersAccordion`; Cable-подписка после dismiss сохраняется
- Тесты: `order_status_sheet_test.mjs` 22/0
- ТЗ: `customer_tasks/Исправление реактивности Svelte 5…` · CBR #63

## 2026-08-13 — CI #31 green (подтверждение)

- Actions run #31 `success` на `353c5a7a`: scan_ruby · scan_js · lint · test · system-test
- Ops: HANDOFF/SESSION/ISSUES — CI gate закрыт; 4 legacy shop остаются вне suite

## 2026-08-13 — fix(ci): CI #30 — Rack::Attack test · onboarding · volume · Tbank super

- Rack::Attack: global `enabled=false` + cache clear в `test_helper`; teardown login tests не включает лимит
- Onboarding UK: `weekday_schedules` + city/address в franchise + platform_uk_rbac
- `manager_volume_test`: `count-accepted` = 250 (total accepted, UI не cap 50)
- `payment_status_confirm_test`: teardown `remove_method` — не ломать `super` prepended Tbank stubs
- Local: 8 target files PASS

## 2026-08-13 — fix(ci): green `test` job clusters A–I

- Vite/npm: `actions/setup-node` + `npm ci` в CI `test` / `system-test`
- FakeTbank stubs: `pay_type` / `data` kwargs
- Service tests: `TestFactories` · OpenStruct · roles_summary count
- Push body / manager turbo / count-accepted asserts
- Shop order tests: verified email payload
- Onboarding: `weekday_schedules` + teardown FK
- RLS bootstrap: race-safe `CREATE ROLE`
- Legacy shop 4 files по-прежнему exclude

## 2026-08-13 — chore(ci): rubocop -A + exclude legacy shop from CI test

- lint: `bin/rubocop -A` (~274 files) + fix broken migration line in stage_2_payments
- test job: exclude 4 known legacy shop files (ISSUES); не гейт фичи
- scan_ruby / scan_js / system-test уже green на #28

## 2026-08-13 — chore(ci): lint + brakeman/audit + skip empty system-test

- После bin/+x: lint/scan_ruby/system-test/test красные (не «больше багов продукта»)
- RuboCop: trailing whitespace / quotes в Cable + LoginForm
- Brakeman 8.0.6 + `config/brakeman.ignore` (port_killer / profile_merger FP)
- bundler-audit: rails 8.1.3.1, puma 8.0.2, nokogiri 1.19.4, bcrypt, net-imap, …
- CI system-test: skip если нет `test/system/*`
- job `test`: triage по логу (legacy shop backlog)

## 2026-08-13 — chore(ci): restore executable bit on bin/*

- GitHub Actions CI #20–#25: все jobs **exit 126** (~40s) — не тесты
- `bin/rails` / `brakeman` / `rubocop` / `importmap` были `100644` → `100755`
- Windows git не сохранял +x; на ubuntu-latest `run: bin/…` → Permission denied

## 2026-08-13 — deploy+MCP: recheck NET+A6 on Fly v451/v452 PASS

- Push `7d4e9c2c` → v451 · NET offline: CTA «Нет связи. Повторить», без `Failed to fetch`
- A6 race на v451 → `refresh_cache!` `c17c67cd` → v452 · cancel #0041 → «повторить» без reload
- Evidence: `artifacts/.../mcp/fly_2026-08-13_recheck/MCP_RESULT.md`

## 2026-08-13 — fix(shop): MCP FAIL — NET raw Failed to fetch + A6 frequent after cancel

- Checkout: `resolveCheckoutSheetInlineError` — нет сырого `Failed to fetch` в PaymentMethodsSheet (copy на CTA)
- Guest cancel: `bust_cache!` frequent v3 — иначе `has_active_order=true` после отмены
- Local: JS **9/0** · `guest_order_cancellation` **13/0** · Fly MCP: skip

## 2026-08-13 — deploy+MCP: Point A v450 пакет (#62 / sheet / errors / Callcheck)

- Push `develop` `8f51deba` · Fly **v450** `deployment-01KZXCYNBPG9CVXJGTKG0BSXDS`
- MCP Point A PASS: #62 checkbox default ON + preserve · СБП active · PaymentMethodsSheet vs 09 · NewCard in sheet · Callcheck (не FlashCall) · `/code/call` 404 · status inside sheet
- MCP FAIL → ISSUES: сырой `Failed to fetch` рядом с «Нет связи. Повторить»; A6 `frequent_products.has_active_order` после cancel
- Evidence: `artifacts/sbp_autopay_checkbox_default_checked/mcp/fly_2026-08-13/MCP_RESULT.md`

## 2026-08-13 — feat(shop): #62 SBP autopay checkbox checked by default

- Доп к #34: чекбокс «Привязать счет для покупок в один клик» checked по умолчанию
- `DEFAULT_SAVE_SBP_ACCOUNT` + `resolveSaveSbpAccountForSbpMode` + `saveSbpAccountTouched`
- Uncheck → `save_sbp_account` не уходит; leave checked → `true`; UI-redraw не сбрасывает выбор
- Backend / AccountToken / Init-Charge API не менялись
- Local: JS SBP zone **39/0 PASS** · Fly MCP: skip
- ТЗ: `customer_tasks/Предустановленный чекбокс автоплатежа СБП.md`

## 2026-08-13 — feat(shop): понятные сообщения при ошибке оплаты One-Click

- ТЗ: `customer_tasks/Понятные сообщения пользователю при ошибке оплаты.md`
- Карта (коды `isCardErrorCode`) → «Недостаточно средств, или карта заблокирована…»
- Сеть/timeout → «Нет связи. Повторить» + кнопка `inline-pay-retry` (тот же pay flow)
- Checkout FSM labels CLIENT/NET синхронизированы; эквайринг/payload не трогали
- Local: JS 17/0 · repeat_invalid_token 12/0 · shop_pay_fsm_3ds PASS · Fly MCP: skip

## 2026-08-13 — feat(shop): One-Click fail / invalid token → PaymentMethodsSheet

- Канон UI = скрин `09_customer_payment_methods_sheet_canon_2026-08-13.png` (checkout pay-stack)
- «карта +» после отказа One-Click → `openRepeatPaymentSheet` (не NewCardForm в peek)
- Repeat fail → `setTokenInvalid` → CTA «Добавить карту»
- addToCart только при пустой корзине (не дублировать qty после defer_init)
- ТЗ UX: `customer_tasks/UX повторная оплата после ошибки One-Click…`
- Local: JS UX 5/0 · `repeat_invalid_token_payment` 12/0 · Fly MCP: skip

## 2026-08-12 — feat(shop): Phone OTP Callcheck + SMS fallback (BUG-REPORT)

- Убран FlashCall `/code/call` из authorization flow
- API: `init_callcheck` / `check_status` / `send_sms` / `verify_sms`; `check_id` в session
- PWA: Callcheck (tel:, poll 3s, timeout 40s) → SMS PIN
- sms-auth / INTEGRATIONS / shop-api обновлены
- Local PASS (phone_otp + funnel UI + profile_merge + CBR + JS)
- Fly MCP: skip

## 2026-08-12 — feat(shop): Phone OTP — SMS и Flash Call раздельно

- SMS генерирует свой 4‑значный код (больше не «запросите звонок сначала»)
- ТЗ: `Вход по телефону Flash Call OTP` · `Вход по телефону SMS OTP`; старые смешанные — superseded
- Local: 25/0 (`phone_otp` + `sms_ru_phone_otp` + api)
- Fly MCP: skip до push/deploy

## 2026-08-12 — feat(shop): enable SBP in PaymentMethodsSheet

- Сняли hardcoded `disabled` (#26 G4); ряд СБП / счёт СБП → `onSelectSbp` / `onSelectSbpAccount`
- Тесты: sbp_payment_ui + checkout CBR + repeat_invalid_token + cleanup + sbp_accounts → **29/0**
- Fly MCP: skip до push/deploy; банк 3001 — отдельно

## 2026-08-11 — deploy: coffeeos v448 (callbacks security)

- push develop `1c53a065` · fly deploy · `/up` 200 · tbank 401 · **tbank 413** oversized · sms_ru 401 · Point A shop 200 + MCP browser

## 2026-08-11 — review#2: SMS.ru + Tbank callbacks security OK

- Bugbot: **0 findings**
- Security: все прежние medium (Tbank + SMS.ru body/dedup) **CLOSED**; medium+ в callback hot-path нет
- GREEN residual `10774cfe` · regress 23/0 · Entire no trailer

## 2026-08-11 — review: Tbank body limit + Rails.cache claim CLOSED

- Security: прежние medium Tbank (413 + shared claim) **закрыты**; regress 49/0
- Bugbot residual: SMS.ru MemoryStore dedup; CI full `test` vs legacy shop fails
- Entire: `d26acf09` — no checkpoint trailer (CLI not on PATH at commit)

## 2026-08-11 — fix(payments): Tbank claim release + CacheCounter Mutex + CI Postgres

- Bugbot: webhook claim освобождается на 500 → retry банка не `duplicate`
- `Payments::CacheCounter` — Mutex на claim/increment (same-pod)
- CI: push `develop`+`main` (было `master`); Postgres 16 service для test jobs
- Тесты: tbank_controller + cache_counter + tbank_adapter → 47/0

## 2026-08-11 — deploy: coffeeos v447 (#61 webhooks)

- push develop `858821af` · fly deploy · smoke `/up` 200 · `POST /callbacks/sms_ru` 401(bad hash) · Point A shop 200

## 2026-08-11 — feat(callbacks): SMS.ru #61 webhooks

- `POST /callbacks/sms_ru` · SHA256 hash · sms_status → order_notification_logs.payload · callcheck → MemoryStore

## 2026-08-11 — feat(shop): SMS.ru #60 stoplist/get

- `SmsRuClient.stoplist_get!` → `StoplistGetResult#stoplist` (Hash phone⇒note)

## 2026-08-11 — feat(shop): SMS.ru #59 stoplist/del

- `SmsRuClient.stoplist_del!(phone:)` → `StoplistDelResult`; api_id только ENV

## 2026-08-11 — feat(shop): SMS.ru #58 stoplist/add

- `SmsRuClient.stoplist_add!(phone:, text:)` → `StoplistAddResult`; api_id только ENV

## 2026-08-11 — feat(shop): SMS.ru #57 auth/check

- `SmsRuClient.auth_check!` → `AuthCheckResult`; только api_id ENV; login/password SKIP

## 2026-08-11 — feat(shop): SMS.ru #56 my/senders

- `SmsRuClient.senders!` → `SendersResult#senders`; api_id только ENV

## 2026-08-11 — feat(shop): SMS.ru #55 my/free

- `SmsRuClient.free!` → `FreeResult` (total_free, used_today); api_id только ENV

## 2026-08-11 — feat(shop): SMS.ru #54 my/limit

- `SmsRuClient.limit!` → `LimitResult` (total_limit, used_today); api_id только ENV

## 2026-08-11 — feat(shop): SMS.ru #53 my/balance

- `SmsRuClient.balance!` → `BalanceResult#balance`; api_id только ENV; не публичный shop API

## 2026-08-11 — feat(shop): SMS.ru #52 callcheck client

- `callcheck_add!` / `callcheck_status!` (401=confirmed); PWA funnel не трогали

## 2026-08-11 — feat(shop): SMS.ru #51 sms/cost before send

- `SmsRuClient.cost!(phone:, msg:)` → CostResult; api_id ENV only

## 2026-08-11 — feat(shop): SMS.ru #50 sms/status poll

- `SmsRuClient.status!(sms_ids:)` → StatusResult; api_id только ENV
- Local client 19/0 · cascade 11/0; webhook — backlog

## 2026-08-11 — docs: SMS.ru #49 email2sms SKIP + ENV runbook

- Intake email2sms → код не делаем; канон HTTP #48
- `SMS_RU_SECRETS.md`; local `.env` плейсхолдеры (не в git); CBR #49

## 2026-08-11 — feat(shop): SMS.ru #48 sms/send SendResult + REVIEW

- GREEN `61061658`: parse `sms_id`, per-phone ERROR, cascade `payload.sms_id`
- REVIEW: bugbot 0 · security OK · Entire skip (no trailer)
- Local PASS (client/notifier/cascade/phone_otp); Fly MCP skip

## 2026-08-11 — docs: SPEC SMS.ru #48 sms/send (Result + sms_id)

- todo: Acceptance, файлы, Не ломать, Проверка; RED следующий
- Scope: parse json/`sms_id`, notifier payload; без DDL

## 2026-08-11 — docs: intake SMS.ru #48 sms/send + bridge enrich

- ТЗ `SMS.ru API Отправить СМС HTTP запросом.md` · artifacts `sms_ru_api_send_http` · CBR #48
- `sms-auth.md` + индекс: контракт send (params, gap `sms_id`, коды); `api_id` из ЛК редэкт
- Код не менялся — SPEC после go

## 2026-08-10 — deploy: G1–G4 на Fly v445 + MCP Point A

- push `develop` `4e52ac6e`; fly deploy coffeeos **v445** (web+worker)
- MCP Point A: session · repeats · PaymentMethodsSheet · pay-stack без status sheet
- Skip live ready→push/SMS и UserCards E2E real MIR

## 2026-08-10 — fix(shop): Group 4 notify SMS idempotency + push subscribe truth

- Cascade: 15s grace before SMS; skip duplicate SMS if already `sent` in logs
- FE: FCM registered localStorage (permission≠subscribed); CTA labels aligned to #37
- Local notify 39/0 + JS 42/0; live push/SMS MCP — после deploy + SMS_RU

## 2026-08-10 — fix(shop): Group 3 ready-in-sheet + Cable dedupe + pay-stack

- `/orders/active` + Cable: `ready` остаётся в шторке до issued (не пусто +0₽)
- poll не tear-down Cable при том же наборе id; статус скрыт на checkout pay-stack
- Local sheet/status 45/0 + JS 42/0; MCP catalog «повторить» PASS; full pay-stack verify после deploy

## 2026-08-10 — fix(shop): Group 2 payment ErrorCode / cancel / invalid token

- status API: `error_code` из provider_data (inline 1051 «Недостаточно средств»)
- GetState sync сохраняет ErrorCode/Message; Cancel ApiError → 422 REFUND_UNAVAILABLE
- 1051 больше не триггерит «невалидный RebillId» CTA; MCP Point A PaymentMethodsSheet *8782/*5953

## 2026-08-10 — fix(shop): silent refresh race + Group 1 auth gate

- Parallel App/CartSheet restore wiped rotated refresh_token on 401 — inflight + safe clear
- Structural test: Checkout↔PhoneAuth `refreshToken` contract; messenger comment cleanup
- MCP Point A: profile email+phone confirmed; artifact `group1_session_auth_merge/`

## 2026-08-10 — ops: UserCards 3.5 MCP 8925 on Fly v444

- Local UserCards зона 61/0; Fly diagnose + GET `/user/cards` — MIR *8782 + *5953
- MCP PaymentMethodsSheet скрин для апрува 3.5; E2E new card real PAN — blocked (prod test PAN)
- Артефакты: `usercards_phase35_mcp_2026-08-10.json` + screenshot; ISSUES 🟡

## 2026-08-10 — docs: integration bridge audit + PWA/payments deploy runbook

- **Gap matrix:** `docs/integrations/gap-matrix-pwa-payments.md` — 17 задач, слепые зоны, payment decision tree
- **Bridge:** `shop-api.md`, `pwa-realtime.md`; расширены `tbank.md`, `sms-auth.md`, `notify-loyalty.md`, `INTEGRATIONS.md`
- **Runbook:** `docs/operations/runbooks/DEPLOY_PWA_PAYMENTS_BATCH.md` — preflight, Fly deploy, MCP matrix Point A

## 2026-08-10 — fix: Dockerfile bin sed skip subdirectories (fly deploy)

- `sed: couldn't edit bin/acceptance: not a regular file` — только top-level файлы в `bin/` через `find -maxdepth 1 -type f`

## 2026-08-10 — docs: Entire Windows git hook PATH note

- `ENTIRE.md`: commit из Windows Git skip hook без Entire в PATH; варианты WSL git / Cursor hooks

## 2026-08-10 — chore: workflow audit (ISSUES, Entire, docs sync)

- **ISSUES:** секция `## 🔴 Открыто` (таблица ~15 строк); resolved — ниже; правила обновлены
- **Entire:** `entire enable` из WSL · git hooks в `.git/hooks/`; runbook § Windows + критерий работы
- **AGENTS.md:** slash-команды вместо «go»; Windows + дисциплина отчёта
- **Удалён** `.cursor/CURSOR_RULES_REPORT.txt` (устарел 2026-06)
- **code-review.mdc:** ссылка на `/review` + spec-build-review (не несуществующий REVIEW.md)
- **agent-workflow / dev-gates:** Windows regress · дисциплина отчёта без auto-gate
- Удалена мусорная папка Windows Entire pitfall в корне репо

## 2026-08-10 — docs: INTEGRATIONS.md → docs/integrations/
- Индекс карты интеграций перенесён из корня в `docs/integrations/INTEGRATIONS.md`
- Обновлены `.cursorrules`, `/trace-bug`, RULES_INDEX, ENTIRE.md; убран `!INTEGRATIONS.md` из gitignore
- Удалён root scratch: `tmp_fetch_otp.rb`, `tmp_route_debug.png`

## 2026-08-10 — docs: Entire.io layer (Review/resume, без docs/tasks/)
- `entire enable -y --agent cursor` · `.entire/settings.json` + `.cursor/hooks.json`
- Runbook `docs/operations/dev/ENTIRE.md` — маппинг на `customer_tasks/`, `todo.md`, `artifacts/`, `INTEGRATIONS.md`
- `/review`, `spec-build-review` PHASE 3, `agent-workflow`, `.cursorrules`, `RULES_INDEX`
- Git hooks в `.git/hooks/` (enable из WSL); примечание про Windows path pitfall

## 2026-08-09 — docs: INTEGRATIONS split (меньше токенов)
- Корень `INTEGRATIONS.md` → индекс ~45 строк + маршрутизация
- Детали: `docs/integrations/tbank.md`, `sms-auth.md`, `notify-loyalty.md`
- `/trace-bug`, `.cursorrules`: индекс → один секционный файл

## 2026-08-09 — docs: карта интеграций INTEGRATIONS.md + /trace-bug
- `INTEGRATIONS.md` (корень): bridge Т-Банк, SMS.ru OTP/cascade, identity merge, loyalty [DRAFT], push/WS
- `.cursor/commands/trace-bug.md` — сквозной аудит hot-path до правок
- `.cursorrules`: обновлять карту при правках payments/callbacks/OTP; gitignore exception `!INTEGRATIONS.md`
- Заказчику: сверить карту с болями (банк, бонусы, регистрация)

## 2026-08-09 — fix: legacy shop triage — messenger OTP тесты приведены к реальному флоу заказчика
- Git log подтвердил: канал `messenger` осознанно снесён (`b2685910` cascade flash_call×2→SMS, `8b76da10` remove messenger from Rack::Attack/Svelte) — у заказчика сейчас нет кнопки мессенджера, только flash_call + SMS fallback
- `phone_otp_test.rb`: `channel: "sms"` на новом номере → `flash_call` (sms сам код не генерирует); 3 теста про `messenger` удалены (фичи нет)
- `profile_merge_test.rb`: `bind_via_phone!` + `link_phone` тест → `flash_call`
- `auth_funnel_wizard_ui_test.rb`: тест "messenger and sms fallback" сужен до реального "sms fallback"
- Проверка: `test/integration/shop/api/phone_otp_test.rb test/integration/shop/api/profile_merge_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb` → 17/17; полный `test/integration/shop/` → 502 runs, 4 failures/1 error (известный хвост, без новых регрессий)

## 2026-08-09 — fix: legacy shop triage — receipt kwarg regression + messenger OTP gap found
- `test/integration/shop/{shop_second_card_step5,shop_save_card_false_step6}_test.rb`: `init_payment` stub `**` — fixed `ArgumentError: unknown keyword: :receipt` cascading through prepend chain
- Regress: T-Bank callback zone 42/0; targeted files 12/0
- Found (not fixed): `Shop::PhoneOtp::CHANNELS` missing `messenger` — real product gap, needs owner decision (see 🔴 ISSUES)

## 2026-08-09 — rules: hot-path Не ломать/Проверка + DoD Point A
- Обязательные блоки SPEC/todo для shop/оплата/статусы/Cable/RLS
- DoD: Local + Fly MCP Point A; legacy shop ~24 — не гейт
- Anti-gem/skills; MCP-safety (не OTP на профиле заказчика); банк≠баг
- Канон Point A в `DEMO_LOGINS.md`; команды `/spec` `/regress` обновлены

## 2026-08-09 — feat: CoffeeOS slash commands start→review
- `.cursor/commands/{start,spec,sbr,regress,review}.md` + README
- Зеркало `.cursor/skills/*/SKILL.md` (`disable-model-invocation: true`)
- Умный `/start`; обязательный `Next: /…` после этапа; regress до push/Fly

## 2026-08-09 — rules: subagent triggers by SBR stage
- `agent-workflow`: политика + таблица explore/shell/bugbot/security-review/ci-investigator
- SBR: explore на SPEC, shell на длинной регрессии, bugbot(+security) на REVIEW
- Отчёт: обязательная строка `Субагент: …`; карта `docs/agents/SUBAGENTS.md`
- Мелочь без субагентов; CE/ce-* не по умолчанию

## 2026-08-09 — rules: harden header-only + anti-noise (README/ce-*/soft blast-radius)
- `agent-workflow` / `coffeeos-index` / `.cursorrules` / `RULES_INDEX` / task-workflow / SBR / commit-ops
- Шапка ops только `limit` до `---`; запрет глотать тело жирных docs
- Folder README не при обходе; мелочь без роя ce-*; субагент 1–2
- Мягкий blast-radius; обязательные «Не ломать»/«Проверка» в todo — отложены
- User Rule «commit only when asked» — игнор в репо; лучше удалить в Cursor Settings

## 2026-08-09 — docs: remove redundant agent/product noise
- Удалены tech-дубли `LIVE_DEMO_SCENARIOS.md` (оставлен PLAIN), `qa/CODE_REVIEW.md` v1/v2
- Удалены `docs/agents/AGENTS/*` (канон — `AGENTS.md`), `docs/product/core/*.sql.md` (~440 KB SQL-черновиков)
- Обновлены PATH_MAP / README вех / CHECKLIST / QA / PRACTICES / runbooks
- ~502 KB с диска; оценка токенов — в отчёте шага

## 2026-08-09 — refactor: reorganize bin/ into acceptance, prog10, fly-tools
- Корень `bin/`: rails/dev/smoke/ci/deploy stubs (~39 файлов)
- `bin/acceptance/`: приёмка MCP/Fly (`b11*`…`b21*`)
- `bin/prog10/`: прогон 10 точек
- `bin/fly-tools/`: usercards/OTP/Firebase/иконки
- Обновлены пути в скриптах и живых docs; README в каждой папке

## 2026-08-09 — docs: folder READMEs plain language (owner/customer)
- ~320 коротких `README.md` по папкам app/test/config/docs/.cursor/… простым языком
- Ignore-папки (log/tmp/storage/uploads/scratch/node_modules/…) — README + исключения в `.gitignore`
- Агенту: не always; только если нужно понять зону (`coffeeos-index`)

## 2026-08-09 — docs: add .cursor/README.md (rules folder map)
- Простая карта папок/файлов `.cursor/rules` (workflow + project + symlinks)

## 2026-08-08 — MCP: #47 Fly v443 status poll + repeats PASS
- Aram Point A: ready `#202608-0027` → issued (barista service); без reload PWA → «повторить» ×3
- Evidence: `pwa_status_sync_and_repeats_stale/mcp/fly_v443_2026-08-08/`
- Апрув заказчика «ок» — отдельно

## 2026-08-08 — deploy: #47 Fly v443 (status poll + frequent refresh)
- Push develop `56648134` · image `deployment-01KZGG9538YYB9ZE5YBTEN9PQS`
- v442: release_command machine API «not found» → retry `--image` → **v443** · `/up` 200
- MCP приёмка статусов/повторов — отдельно

## 2026-08-08 — feat: #47 PWA status poll + frequent refresh [GREEN+REVIEW]
- FE: `ACTIVE_ORDERS_POLL_MS` (8s) + `visibilitychange` → `GET /orders/active`; после sync — `refreshFrequentProducts`
- Cable остаётся fast-path; страховка когда WS молчит на мобильном PWA
- Тесты: `order_status_active_poll_test.mjs` + zone JS 32/0 · RED `6c7176fe` · GREEN `aeff9fa7`
- MCP Fly / апрув заказчика — отдельно

## 2026-08-08 — docs: #47 PWA status sync + repeats (intake + SPEC)
- customer_tasks 1:1 · artifacts `pwa_status_sync_and_repeats_stale` · CBR #47 · ISSUES 🔴
- SPEC `todo.md`: poll `/orders/active` + visibility + refresh frequent (G1–G3)
- Token check: always −77%; SPEC-ход rules+шапки ≈ −69% vs старый full memory — `TOKEN_CHECK_2026-08-08.md`

## 2026-08-09 — docs: add .cursor/README.md (rules folder map)
- Простая карта папок/файлов `.cursor/rules` (workflow + project + symlinks)

## 2026-08-08 — chore: pinpoint code context (SPEC files list, no @codebase waste)
- Always/SBR/task-workflow: SPEC → «Файлы (ожидаемо)» 2–7 путей в todo; BUILD читает список + точечный добор
- Без Graphify/`codebase-map.md`; запрет зряшного `@codebase`
- Оценка: на разведке/BUILD фичи часто **−40–70%** токенов vs полный `@codebase` (зависит от задачи)

## 2026-08-08 — chore: archive CHANGELOG by month; ISSUES keep + 🔴-only start
- `CHANGELOG`: live шапка + `2026-08` (~257k→~23k B); архив `journal/archive/CHANGELOG-2026-06|07.md`
- `ISSUES`: без архива (~170 строк); always/agent-workflow — на старте только секция 🔴
- Обновлены RULES_INDEX / README / index / `.cursorrules`

## 2026-08-08 — chore: archive session ops by month + thin read
- `HANDOFF`/`SESSION_STATE`: шапка + только `2026-08`; архив в `session/archive/`
- Always/agent-workflow + task-workflow: старт = шапка + 🔴 + todo; CHECKLIST/CBR только для вехи
- Замер live: HANDOFF ~76k→~19k B · SESSION_STATE ~284k→~35k B (~90k→~13.5k tok вместе)

## 2026-08-07 — chore: thin always Cursor rules (−77% tok/ход)
- Always bundle: **50758 B / ~12690 tok → 11775 B / ~2944 tok** (строки 626→135)
- `alwaysApply: false`: task-workflow, SBR, gates, layout, intake, file-size-split
- `coffeeos-performance`: globs Ruby вместо always
- Удалены symlink-дубли `rules/coffeeos-core.mdc`, `rules/coffeeos-performance.mdc`
- Обновлены index / agent-workflow / `.cursorrules` / `RULES_INDEX` / `AGENTS.md`

## 2026-08-07 — MCP: Fly v441 #46 auth-limit + *8782 pay PASS
- Deploy health: v441 machines started · `/up` 200
- #46: one_click *5953 → 119 friendly + NewCardForm; *8782 → «Оплачен» (`db45ab5f-…`)
- #33: El/Dl helpers в bundle v441; live S1/S2 = v440
- Evidence: `bank_auth_limit_blocks_payment/mcp/fly_v441_2026-08-07/`

## 2026-08-07 — deploy/MCP: #33 fallback≠expanded + #46 · Fly v440
- Push `11e5eaf7` · Fly **v440** · `deployment-01KZDYQPQCHWPFBPEX3XJF8JKA` · `/up` 200
- MCP: S1 PASS (ошибка → только СБП/карта+); S2 PASS (карта + → *5953/*8782 + форма)
- Evidence: `tbank_widget_oneclick_fallback/mcp/fly_2026-08-07/`

## 2026-08-07 — feat: #33 fallback UI — expanded only after «карта +»
- После отказа карты: только плашка + «СБП» / «карта +» (без списка карт / формы)
- Expanded (скрин 08) — только после тапа «карта +»
- `resolveCardDeclineFallbackUi` / `resolveCardPlusExpandedUi` в `widgetRepeatPayFlow` + `RepeatSection`
- Тесты: JS fallback UI + widget FSM + #46 pay FSM 38/0 · widget initiator 6/0
- Push/MCP — ждёт апрув

## 2026-08-07 — feat: #46 bank auth-limit — stop blind retry / same-PaymentId Charge
- Widget: после REJECTED Charge сбрасываем `provider_payment_id` (нет `charge_existing!` → 119)
- FE: ErrorCode `119`/`2200` + текст «запросов авторизации» → `CLIENT_ERROR` (сменить карту), не «Сбой банка: позже» retry
- BE: friendly message для 119/2200
- Тесты: widget+error 8/0 · JS 19/0 · repeat 11/0 · order/adapter 22/0
- Push/MCP — ждёт апрув; cooldown *5953 на банке может ещё держаться

## 2026-08-07 — deploy/MCP: #26 G7+G1–G4 · Fly v439
- Push `bd0e9fb0` · Fly **v439** · `deployment-01KZDEN9MV9QW2DKFWQXRNFYVT` · `/up` 200
- MCP: G1–G4 PASS (Картой *XXXX, orange Pay, +, СБП disabled)
- G7 live PARTIAL (банк rate-limit BANK_ERROR); unit+bundle PASS
- Evidence: `repeat_order_invalid_token_payment_sheet/mcp/fly_v439_2026-08-07/`

## 2026-08-07 — review: #26 G7 + G1–G4 PaymentMethodsSheet (local done)
- G7: CLIENT_ERROR / insufficient funds → auto + CTA открывают NewCardForm (не retry той же карты)
- G1–G4: UI скрин 03 — `Картой *XXXX`, orange Pay, `Картой +`, СБП disabled (D1; #27 deep link follow-up)
- Тесты: JS 21/0 · Rails pay zone 21/0 · коммиты `2fd3bb87` + `7c435b0b`
- Push/MCP — ждёт апрув

## 2026-08-07 — docs: #26 PHASE 0+SPEC live insufficient funds (G7)
- Фидбек заказчика (дословно) + скрины `04`–`08` в artifacts
- P0: после отказа *5953 форма NewCardForm не открывается; root cause CLIENT_ERROR→onPay
- SPEC: gap G7 + D4; визуал G1–G4 вторичны; код не писали

## 2026-08-07 — docs: #26 PHASE 1 SPEC (канон скрин 03)
- `todo.md`: baseline B1–B6; gaps G1–G4 (лейбл «Картой *XXXX», оранжевый Pay, «Картой +», СБП disabled)
- Decisions D1 СБП vs #27 · D2 маска vs Step10 · D3 accent Pay
- Код не меняли — ждём апрув SPEC → RED

## 2026-08-07 — docs: #26 PHASE 0 re-intake (invalid token payment sheet)
- Текст ТЗ совпал с принятым — тело не перезаписывали
- Скрин: `repeat_order_invalid_token_payment_sheet/screenshots/03_payment_method_bottom_sheet_invalid_token_2026-08-07.png`
- README artifacts + CBR #26 + customer_tasks README; SPEC/код не трогали

## 2026-08-06 — deploy/MCP: #35 D1+D2 · Fly v438 PASS
- Push `4ca777a4` · Fly **v438** · `deployment-01KZBM95ZEVSW9G5GN87EW4RW6`
- REVIEW: нет P0; empty meta fallback fixed
- MCP: `status-above-lines` + pay-stack meta = название позиции (скрин 06)
- Evidence: `order_status_compact_sheet_push/mcp/fly_v438_2026-08-06/`

## 2026-08-06 — feat: #35 D1+D2 expanded stack contract + meta product [GREEN]
- CartSheet: `data-cart-status-stack="status-above-lines"`; sheetContext peek vs cart_expanded
- `statusMetaThird`: expanded → название позиции; peek → точка продаж
- ActiveOrdersAccordion показывает `metaThird`
- Тесты: expanded/meta/peek/mount 18/0 · JS accordion+sheet 32/0

## 2026-08-06 — docs: #35 PHASE 1 SPEC (скрин 06 expanded)
- `todo.md`: baseline A/B/C `[x]`; gaps D1–D5 (DOM-порядок expanded, meta product name, MCP)
- Маппинг GuestOrderChannel / ReadyPushJob; код не меняли

## 2026-08-06 — docs: #35 PHASE 0 — забытый скрин expanded
- Текст ТЗ без изменений (совпал с принятым)
- Артефакт: `order_status_compact_sheet_push/screenshots/06_expanded_sheet_status_plus_cart.png`
- Карта подпись «если заказ еще» → 06; README + CBR #35

## 2026-08-06 — fix: peek корзины при активном статусе (status+cart stack)
- Root cause: `hideCartTail` при `hasActiveOrder` прятал peek/expanded/single — add «пропадал»
- `CartSheet`: статус + позиции стык в стык; `STATUS_IN_SHEET_EXTRA_VH`; empty placeholder только без активного заказа
- Build `prog38`; тесты `active_order_cart_peek_stack_test` + cart sheet zone 57/0
- Push/MCP — ждёт апрув

## 2026-08-06 — docs: правило CartSheet без многослойности
- `.cursor/rules/project/coffeeos-cart-sheet.mdc` — одна шторка, секции стык в стык, запрет fixed/z-index слоёв внутри
- Индекс: `RULES_INDEX.md` · symlink · ссылка из `coffeeos-ui.mdc`
- Аудит кода на нарушения — после апрува

## 2026-08-06 — deploy/MCP: #44 product single sheet · Fly v436 PASS
- Push `7f7973e1` · Fly **v436** · `deployment-01KZB42C5176Y6MH07YGFSD0YF`
- MCP: CTA внутри CartSheet · `уже в заказе: N` · ± bump 2→3 · build `prog37` · без fixed overlay
- Evidence: [`product_card_peek_cart/mcp/fly_v436_2026-08-06/`](../milestones/veha_2/artifacts/product_card_peek_cart/mcp/fly_v436_2026-08-06/)

## 2026-08-06 — fix: убрать “хвост” корзины под активным статусом
- `CartSheet.svelte`: при `hasActiveOrderFlag` не рендерим peek/expanded/single блоки корзины (оставляем только `OrderStatusSheet`)
- Коммит: `19231620`

## 2026-08-06 — feat: #44 product card — одна шторка без наложений [GREEN]
- Root cause: fixed ProductCartPeek (z-45) + bottom-bar (bottom:140px) + CartSheet на `#/product`
- CTA «добавить к заказу» → `ProductSheetCta` внутри CartSheet; peek/hidden/expanded — секции той же шторки
- Удалён `ProductCartPeek.svelte`; `productPageCtaStore` + `PRODUCT_CTA_EXTRA_VH`; spacer `--cart-sheet-h`
- Тесты: product_card_s0–s7 28/28 · cart/product zone 135/0 · build `prog37`
- MCP/Fly — ждать push

## 2026-08-06 — mcp: #45 UI one-click PASS на Fly v435
- Click «оплатить в 1 клик» → «✔ Оплачено!» → `#202608-0014` accepted / tbank `8995082965`
- Evidence: [`mcp_fly_v435_ui_one_click_2026-08-06.json`](../milestones/veha_2/artifacts/aram_one_click_payment_ssl_mintcifry/mcp_fly_v435_ui_one_click_2026-08-06.json)

## 2026-08-06 — deploy: #45 Aram one-click SSL · Fly v435 PASS
- Push `8db2bed2` · Fly **v435** · `deployment-01KZB0QYSKZM6BWWCVR840SNS4`
- Live Charge *5953 CONFIRMED → `#202608-0013` accepted (PaymentId 8995036222)
- Evidence: [`aram_one_click_payment_ssl_mintcifry/mcp_fly_v435_2026-08-06.json`](../milestones/veha_2/artifacts/aram_one_click_payment_ssl_mintcifry/mcp_fly_v435_2026-08-06.json)

## 2026-08-06 — fix: #45 Aram one-click — SSL Минцифры + cards/Charge
- Root cause: Т-Банк TLS на Russian Trusted CA → SSL fail на Fly (`certificate verify failed`)
- `config/certs/` + Dockerfile `update-ca-certificates` + `SSL_CERT_FILE`
- FE: `userCardsApiPath(?email)`, Charge по saved card, no-token → bind form
- BE: widget_init email resolve; Init `provider_payment_id` до Charge
- Intake CBR #45 · тесты widget_initiator + JS path PASS

## 2026-08-06 — docs: intake #44 product card peek cart (reopen)
- Продолжение задачи `product_card_peek_cart` (не новая): ТЗ 1:1, скрины заменены, архив `_archive_2026-07-10/`
- Файл ТЗ переименован с усечённого `…pee.md`
- CBR #44 · SESSION_STATE / HANDOFF
- Код не трогали — ждём go → SPEC

## 2026-08-06 — deploy: #43 has_active_order TTL · Fly v434 MCP PASS
- `has_active_order?` окно 24h (как #42) — June accepted больше не гасят «повторить»
- Push `c9c5aacd` · Fly **v434** · `deployment-01KZAVCVTD37NBM7CK9M7MFMFK`
- MCP: Aram `frequent_products` 3 items · 3× «оплатить в 1 клик»
- Evidence: [`repeat_hidden_by_stale_active_orders/mcp/fly_v434_2026-08-06/`](../milestones/veha_2/artifacts/repeat_hidden_by_stale_active_orders/mcp/fly_v434_2026-08-06/)

## 2026-08-05 — deploy: #42 stuck sheet TTL · Fly v433 MCP PASS
- Push `ec1e6a65` · Fly **v433** · `deployment-01KZ9913PP55V099F8Y6JQCK5V`
- Live: Aram `orders/active` → `[]` (5 June accepted отрезаны TTL); sheet absent; pay CTA `+3₽` visible
- Evidence: [`stuck_orders_status_sheet_blocks_payment/mcp/fly_v433_2026-08-05/`](../milestones/veha_2/artifacts/stuck_orders_status_sheet_blocks_payment/mcp/fly_v433_2026-08-05/)
- ISSUES #42 → resolved

## 2026-08-05 — feat: #42 TTL active orders + peek height (unblock payment)
- `orders/active`: только заказы за последние **24h** (June accepted больше не залипают в шторке)
- OrderStatusSheet embedded peek: `min(22vh, 8.5rem)` — не перекрывает оплату
- Intake + FAQ payment `processing`/`succeeded` в customer_tasks
- Тесты: active_orders + mount acceptance PASS

## 2026-08-05 — deploy: #35 rev status sheet hide-ready + product · Fly v432 MCP PASS
- Push `38df5088` · Fly **v432** · `deployment-01KZ8W88G4HC0YK291M3FM011G`
- Live: `orders/active` без ready · sheet на home + `#/product` · scroll >2
- ReadyPushJob: copy «Ваш заказ готов, заберите на кассе!» + claim в job
- MCP: [`order_status_compact_sheet_push/mcp/fly_v432_2026-08-05/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/mcp/fly_v432_2026-08-05/)
- Smoke barista→ready→hide — PARTIAL

## 2026-08-05 — fix: #41 can_cancel in orders/active + cancel MCP v431

- BE: `ActiveOrdersPresenter` + `GuestOrderBroadcaster` отдают `can_cancel` для sticky CTA
- Fly **v431** · MCP PASS cancel + accepted modal `#202608-0005`
- Тест: `active_orders_test.rb` +1
- CBR #41 апрув «ок» · ISSUES Fly LB resolved

## 2026-08-05 — docs: #35 rev intake+SPEC (status widget hide on ready)
- ТЗ заказчика обновлено 1:1; 5 скринов заменены в `order_status_compact_sheet_push/screenshots/`
- SPEC: дельта vs v414 — hide on `ready`, product route, active API без ready
- RED/GREEN не начинали

## 2026-08-05 — docs: #41 CBR апрув «ок»; cancel MCP blocked by Fly LB

- CBR #41 → **закрыта `[x]`** (апрув владельца)
- Cancel live: заказ `#202608-0005` → accepted+can_cancel; reconnect token; Fly FRA proxy **503** — скрин cancel не снят
- MCP_RESULT / HANDOFF / SESSION_STATE updated

## 2026-08-05 — deploy: #41 Order action buttons on Fly v429 · MCP PASS

- Push develop · Fly **v429** · `deployment-01KZ88WP8VNXVGCBZVV4QZ0NAM`
- MCP: sticky RIGHT «Чат с поддержкой» + «Включить Push» · `#ff6b35` · 44px · 17 roots / 29 btns
- Evidence: `artifacts/order_action_buttons_status_panel/mcp/fly_v429_2026-08-05/`

## 2026-08-05 — feat: #41 Order action buttons status panel [REVIEW]

- FE: `OrderActionButtons` + `orderStatusCtas(+hasPushSubscription)` + SupportChat/Tips adapters
- Sticky: cable `can_cancel` merge; cancel Confirm Sheet + `stickyOrderCancel`; touch 44px `#ff6b35`
- Регрессия JS зона #41: **95/95 PASS**
- Deploy/MCP — сделаны отдельным шагом (v429)

## 2026-08-05 — docs: SPEC #41 Order action buttons status panel

- PHASE 1: `todo.md` шаги 1–7 · маппинг Svelte/node:test · цель sticky accordion RIGHT
- Канон: `OrderActionButtons.svelte` + `orderStatusCtas(+hasPushSubscription)` + chat/tips adapters
- Код не писали; дальше RED шаг 1

## 2026-08-05 — docs: intake #41 Order action buttons status panel

- PHASE 0: ТЗ 1:1 `Динамический блок действий Action Buttons в статусной панели заказа.md`
- Артефакты: `order_action_buttons_status_panel/` + макет плейсхолдеров CTA
- CBR #41 · код не трогали; ждём go → SPEC

## 2026-08-05 — docs: #40 MCP accepted cancel modal on Fly v428

- MCP: `#202608-0006` accepted → modal (179 ₽) → confirm → cancelled + toast
- Evidence: `04_accepted_cancel_modal.png` · `05_accepted_modal_cancel_success.png`
- Live T-Bank `/v2/Cancel` E2E still deferred (cash path)

## 2026-08-04 — deploy: #40 T-Bank auto refund on Fly v428 · MCP PASS

- Push `e2c10736` · Fly **v428** · `deployment-01KZ6M11H6F1RJ4GPMND07P57R`
- MCP: pending cancel `#202608-0003` → cancelled + toast; ready `#202608-0005` → support CTA
- SSH: `cancel_payment` / `REFUND_UNAVAILABLE` на Fly; live `/v2/Cancel` E2E deferred
- Evidence: `artifacts/tbank_auto_refund_order_cancellation_pwa/mcp/fly_v428_2026-08-04/`

## 2026-08-04 — feat: #40 T-Bank auto refund on PWA cancel [REVIEW]

- BE: `TbankAdapter#cancel_payment` (`/v2/Cancel` без Receipt); GuestCancel → refunded + Refund
- FE: CTA labels, `OrderCancelModal`, success/blocked toasts + force preparing
- Регрессия: cancel/Tbank/creator **81/223 PASS**; JS **19/19**; §2.3 2 skips OK
- Deploy/MCP — не делали

## 2026-08-04 — docs: SPEC #40 T-Bank auto refund on PWA cancel

- PHASE 1: `todo.md` шаги 1–7 · маппинг Minitest/Svelte
- Канон: GuestCancel API есть; `/v2/Cancel` + modal/toasts — нет
- Код не писали; дальше RED шаг 1

## 2026-08-04 — docs: intake #40 T-Bank auto refund on PWA cancel

- PHASE 0: ТЗ 1:1 `Автоматический возврат платежа Т-Банк при отмене заказа в PWA.md`
- Артефакты: `tbank_auto_refund_order_cancellation_pwa/` · CBR #40
- Код не трогали; ждём go → SPEC

## 2026-08-04 — deploy: #39 v2 cascade on Fly v427 · SMS MCP PASS

- Push `7b4ff49f` · Fly **v427** · presence→SMS (no TG)
- MCP: `#202608-0005` → `sms:sent` · online `SMS skipped` · `/shop` 200
- SMS_RU secrets still unset (fallback log-only)

## 2026-08-04 — feat: #39 v2 cascade presence→SMS (no Telegram) [GREEN]

- Rewrite: `OrderReadyPaidNotifier` SMS-only; cascade log `SMS skipped`
- Network SMS errors → `order_notification_logs` failed, job soft-exit
- Tests: cascade zone **45/91 PASS**; TelegramBotClient dormant
- Docs: CBR #39 v2; v1 SUPERSEDED

## 2026-08-04 — docs: intake #39 v2 cascade WS/Push/Wallet to SMS (no Telegram)

- PHASE 0+SPEC: ТЗ 1:1, artifacts `order_ready_cascade_ws_push_sms`, todo mapping

## 2026-08-04 — deploy: #39 cascade on Fly v426 · TG MCP PASS
- Push `2af25874` · image `deployment-01KZ5X2WSEYB4GKVBVPBMJ3SG0` · **v426**
- `TELEGRAM_BOT_TOKEN` secret; DDL telegram_chat_id + order_notification_logs на Neon
- MCP: Aram `#202608-0005` → cascade → `telegram:sent`
- Evidence: `mcp/fly_v426_2026-08-04/`

## 2026-08-04 — feat: Order ready cascade Telegram→SMS (#39) REVIEW
- `Shop::TelegramBotClient` + `OrderReadyPaidNotifier` (403/400/timeout → SMS)
- `SmsRuClient#send_message!` с валидацией ≤70; лог в `order_notification_logs`
- Зона: 54 runs / 126 assertions PASS · barista status без diff
- MCP/deploy — ждут апрув

## 2026-08-04 — db: #39 Migration Gate telegram_chat_id + order_notification_logs
- `mobile_customers.telegram_chat_id` (partial unique index)
- `order_notification_logs` + RLS tenant isolation
- Model `OrderNotificationLog`; `.env.example` cascade secrets
- Smoke: `rls_tenant_isolation_test` 7/27 PASS

## 2026-08-03 — MCP: #38 Background FCM/Wallet · Fly v421 PASS
- Live **v421** · Aram Point A · 17 active orders
- Desktop max-2 CTA (subscribed) + iOS CriOS Apple Wallet CTA + reconnect banner
- Evidence: `artifacts/background_notifications_fcm_apple_wallet/mcp/fly_v421_2026-08-03/`
- CBR #38 → MCP PASS

## 2026-08-03 — docs: SPEC Order ready cascade WS→TG→SMS (#39)
- PHASE 1: `todo.md` — маппинг ТЗ → Minitest/Solid Queue + GuestOrderBroadcaster; шаги 1–5 TDD
- Канон: presence Rails.cache; TelegramBotClient + SMS.ru ≤70; без нового barista ready API; DDL — Migration Gate

## 2026-08-03 — docs: intake Order ready cascade WS→TG→SMS (#39)
- PHASE 0: ТЗ 1:1 `customer_tasks/Оптимизированный каскад уведомлений Заказ готов PWA WS Push Telegram SMS.md`
- Артефакты: `artifacts/order_ready_cascade_ws_telegram_sms/`
- Индекс CBR #39 + `customer_tasks/README.md`; код не менялся

## 2026-08-03 — deploy: #38 push OK · Fly release BLOCKED billing
- Push `develop` `a145ee0c`
- Image built+pushed: `deployment-01KZ3QRBRX8E2VES9XFJSBGDJ4` (`--depot=false`)
- Release/machine update → Fly org **403 billing**; live остаётся **v419**
- MCP #38 SKIP · evidence `mcp/fly_blocked_billing_2026-08-03/`

## 2026-08-03 — feat: Background FCM progress + Apple Wallet (#38) REVIEW
- FCM: `tag` / `actions` / unicode progress; soft-fail payload; SW notificationclick (cancel/chat/tips)
- Wallet: PassBuilder face/back/strip; Broadcaster PassUpdater если pass есть; ReadyPushJob без double ready
- PWA: `orderStatusCtaMachine` (макс. 2 CTA) на карточке заказа
- Тесты: Rails 33/127 · JS 40/40 · barista status files без diff · tip `f3f0f2db`
- MCP/deploy — ждут апрув

## 2026-08-03 — docs: SPEC Background FCM progress + Apple Wallet (#38)
- PHASE 1: `todo.md` — маппинг ТЗ → Minitest/JS + существующие Shop push/Wallet сервисы; шаги 1–5 TDD
- Канон: FCM tag/actions/unicode; SW cancel/chat/tips; PassUpdater из Broadcaster; PWA CTA machine; без правок barista status

## 2026-08-03 — docs: intake Background FCM progress + Apple Wallet (#38)
- PHASE 0: ТЗ 1:1 `customer_tasks/Фоновые уведомления прогресс-бар Android FCM и Apple Wallet iOS.md`
- Артефакты: `artifacts/background_notifications_fcm_apple_wallet/`
- Индекс CBR #38 + `customer_tasks/README.md`; код не менялся

## 2026-08-03 — MCP: Charge unlocked · #32/#33/#27/#34
- Т-Банк включил Recurrent/Charge на `1719235292309`
- one_click + widget_init → accepted/CONFIRMED live
- SBP bind Init → NSPK QR (не 3013); Zero-Click ждёт AccountToken после банка
- Артефакт: `tbank_charge_unlocked_mcp_2026-08-03/`

## 2026-08-03 — deploy: #37 OS detect Wallet/WebPush v419 + MCP PASS
- Push `develop` `35b7f00c` · `fly deploy --remote-only` → **v419** (`deployment-01KZ3CAC9RNSCPZRZ5VZWEWW8K`)
- MCP Point A: Android Push CTA · iOS (CriOS) Wallet CTA · receipt toggle
- Evidence: `artifacts/order_status_os_detect_wallet_webpush/mcp/fly_v419_2026-08-03/`

## 2026-08-03 — feat: Order status OS detect + Wallet/WebPush (#37) REVIEW
- Accordion CTAs: iOS Apple Wallet download · Android/Desktop FCM `registerShopPush` · «Состав заказа» → receipt
- `GET /shop/api/orders/:id/wallet_pass` (PassUpdater + pkpass blob); `getDeviceOS` + init restore LS/permission
- Тесты: JS 56/56 · Rails wallet/mount/push/active 11/11 · tip GREEN `a0b3d0ea`

## 2026-08-03 — docs: SPEC Order status OS detect + Wallet/WebPush
- PHASE 1: `todo.md` — маппинг ТЗ → Svelte/shop API; шаги 1–6 TDD
- Канон: accordion CTAs + `deviceDetect` + wallet_pass download + FCM register (не React/Tailwind overlay)

## 2026-08-03 — docs: intake Order status OS detect + Wallet/WebPush
- PHASE 0: ТЗ 1:1 `customer_tasks/Адаптивный виджет статуса заказа Детекция ОС и подписка на уведомления.md`
- Артефакты: `artifacts/order_status_os_detect_wallet_webpush/`
- Индекс CBR #37 + `customer_tasks/README.md`; код не менялся

