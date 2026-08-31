# SESSION_STATE

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-08-31 (CI fix prep kitchen + brakeman)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| CI **green** (#33370517697) | deploy только по апруву · IB-P-05 Fly re-verify |

**Архив session:** [`archive/README.md`](archive/README.md)  
**Архив journal:** [`../journal/archive/README.md`](../journal/archive/README.md)

---

## Текущий месяц (2026-08)

### Fly IB приёмка Phase 5b (2026-08-30)

| Что | Статус |
|-----|--------|
| CI #33315924160 develop | **green** |
| Fly deploy release | **v468** |
| MCP Point A (`fly_v461_mcp_acceptance`) | **PASS** 7/7 — artifact `mcp/fly_v461_2026-08-30/` |
| Prog10 staff isolation 9 points | **PASS** 9/9 |
| Post-deploy pack (logs/Sentry/health) | **PASS** — `fly_post_deploy_2026-08-30/post_deploy_pack.json` |

### IB Phase 5b hardening (2026-08-30)

| Что | Статус |
|-----|--------|
| Devices::TokenResolver (kiosk/TV/cable) | **local done** |
| Platform Pundit + TenantPolicy open_as_manager UK-only | **local done** |
| Prog10 barista POS orders (не shop cash) | **local done** — Fly TBD |
| UserRole tenant_id validation point staff | **local done** |
| Tests platform + devices + user_role | **green** |

### IB master verification Phase 0–5 (2026-08-30)

| Что | Статус |
|-----|--------|
| `IB_MASTER_VERIFICATION_CHECKLIST.md` — docs + tests + smoke mapping | **local done** |
| Mega-regression WSL 309 runs | **0 failures, 3 skips** |
| `tenant_guc_inventory.rb` | exit 0 |
| Prog10 staff isolation | **SKIP** — cash 422 |
| Fly MCP / push | skip — апрув |

### IB Phase 5 ABAC-lite (2026-08-30)

| Что | Статус |
|-----|--------|
| ABAC_ATTRIBUTES + ABAC_POLICIES (58 rules) | **local done** |
| PolicyContext + 4 policies refactor | **local done** |
| ABAC tests 22/22 + regression 110/110 (WSL) | **local done** |
| Fly MCP / deploy | skip |

### IB Phase 4 DoD RBAC (2026-08-30)

| Что | Статус |
|-----|--------|
| ROLES_AND_PERMISSIONS.md + IB_ACCEPTANCE_CHECKLIST.md | **local done** |
| GAP REGISTER (12 items, 0 code fixes) | **local done** |
| Integration tests (WSL) | **285+ runs green** |
| Prog10 staff Fly | **SKIP** — cash payment 422 on Fly |
| Fly MCP / deploy | skip |

### IB Phase 3 tenant RLS (2026-08-30)

| Что | Статус |
|-----|--------|
| RLS_TENANT_AUDIT.md + DEVICE_TOKENS.md | **local done** |
| bin/audit/tenant_guc_inventory.rb | **local done** |
| tenant_rls_isolation_test (6 cases) | **local skip** — PG 127.0.0.1 down |
| NEED_MIGRATION | none |
| Fly MCP / deploy | skip |

### Fly v466 deploy (2026-08-30)

| Что | Статус |
|-----|--------|
| Push | 5 коммитов `e22cbff6..4496346d` → `origin/develop` |
| CI | **#33305782903** green (test/lint/system-test/scan) |
| Deploy | **v466** · `deployment-01M192HPGQK85J684EJ71XY5KS` · HEAD `4496346d` |
| Point A smoke | HTTP **200** |
| Fly MCP | skip — ссылка заказчику; полная пачка по запросу |

**В релизе:** T-Bank refund не блокирует закрытие смены · carryover accepted на табло · 01_Vision актуализация.

### Callbacks payments amount mismatch (2026-08-29)

| Что | Статус |
|-----|--------|
| `EventsController#payment` | optional amount / provider_data Amount vs payment.amount · order.final_amount |
| mismatch → 422 | payment status unchanged; `Rails.logger.error` + audit rejected |
| Тесты | `events_controller_test` 27/0 |
| Fly MCP | skip — local HMAC guard |

### Fly v465 deploy + MCP (2026-08-29)

| Что | Статус |
|-----|--------|
| Deploy | **v465** · `deployment-01M167Z816GPZYVX109PBWXQQD` · HEAD `4a416668` |
| P0–P7 MCP | **PASS** |
| Sentry 24h | **clean** |
| Артефакты | `…/mcp/fly_v465_2026-08-29/` |

### Shop API order show — customer_id (2026-08-28)

| Что | Статус |
|-----|--------|
| `OrdersController#show` | `try_reconnect_from_params!` → 401 без cid → `where(customer_id:)` |
| Тесты | `orders_controller_test` 12/0; регресс show/cancel/fiscal 11/0 (+1 skip T-Bank) |
| Fly MCP | skip — local IDOR, нет deploy |

### Fly v464 deploy + MCP (2026-08-28)

| Что | Статус |
|-----|--------|
| Deploy | **v464** · `deployment-01M143HBYRQB50Y04HZA1RVAZZ` · HEAD `20518d1f` |
| P0–P7 MCP | **PASS** (cash 422) |
| Артефакты | `…/mcp/fly_v464_2026-08-28/` |

### Fly v462 deploy + MCP (2026-08-28)

| Что | Статус |
|-----|--------|
| Deploy | **v462** · `deployment-01M13ZVNYK4Y3M75G9ZHN7RY2J` · HEAD `9f4f8ee0` |
| P0–P7 MCP | **PASS** |
| B2.1 barista | **PARTIAL** |
| Артефакты | `…/mcp/fly_v462_2026-08-28/` |

### Fly v461 deploy + MCP (2026-08-28)

| Что | Статус |
|-----|--------|
| Deploy | **v461** · `deployment-01M13YCKVJ4CDQBFQFKTHM1NZC` · HEAD `f5ce8118` |
| Push | `3e476f66..f5ce8118` |
| P0–P7 MCP | **PASS** (cash 422, simulate=0, card pending, fail-redirect) |
| B2.1 barista | **PARTIAL** (b21_cancel marker — pre-existing) |
| Артефакты | `…/mcp/fly_v461_2026-08-28/` |

### Сессия 2026-08-28 — block cash on public shop API

- `PaymentConfig.validate_online_payment_method!` — card/sbp/apple_pay/google_pay; cash → 422
- `OrderCreator#payment_flow` — убран cash→accepted; barista POS без изменений
- shop UI: убран label «Наличные» из `tbankPayment.js`
- тесты shop: default `card`; cash 422 + barista cash OK

- Default 0; `PaymentConfig.simulate?` raise in production if enabled
- Единая точка: OrderCreator, NewCard, Recurrent → PaymentConfig
- test_helper: explicit `SHOP_SIMULATE_PAYMENT=1` для legacy shop-тестов

### Сессия 2026-08-28 — fail-redirect ownership

- PaymentReturns: GuestOrderReconnect.owned_by_session? перед PaymentFailureJournal
- TbankAdapter FailURL/SuccessURL: reconnect_token (MessageVerifier)
- Тесты: payment_returns_controller, guest_order_reconnect, tbank_adapter

### Сессия 2026-08-28 — OTP tests + DEAD CODE legacy clients

- email_otp_test: fallback при ошибке Brevo + SHOP_OTP_LOG_FALLBACK
- brevo_client_test: deliver_otp! в test env, код не в логе
- sms_client / messenger_client / flash_call_client: grep app+config — вызовов нет, пометка DEAD CODE
- OTP suite: 73 runs, 170 assertions, 0 failures

### Сессия 2026-08-28 — OTP log leak fix

- Убраны OTP-коды из Rails.logger в shop delivery clients (Brevo, SMS, Messenger, FlashCall, EmailOtp, SmsRu flash_call)
- Тесты email/phone OTP: green

### Сессия 2026-08-28 — #72 + #73 REVIEW

- Local regress 31/0 · bugbot clean · security no medium+
- Entire `01M13J1QDE9SHEEARP15VV3P1H` на `8437244b` (attach session `8eebd79a…`)
- push develop · **CI green** [33149337416](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/33149337416)
- Следующий: deploy апрув → fiscal notify ON → live MCP

### Сессия 2026-08-28 — Fly v460 deploy + MCP #72/#73

- Deploy **v460** (`deployment-01M13JTWPKPJBB3YCG2ZGMWP5P`) с develop `3e476f66`
- MCP: P0/P1 PASS · webhook 401 PASS · #72 PARTIAL · #73 PARTIAL (fr=0, fiscal notify OFF)
- Артефакты: `receipt_email_fiscal_checks/mcp/fly_v460_2026-08-28/` · `fiscal_receipts_personal_cabinet/mcp/fly_v460_2026-08-28/`

### Сессия 2026-08-28 — #72 + #73 REVIEW

- Intake заказчика 2026-08-28: #72 CONFIRMED для SendClosing; #73 Subtask 0, 9а, endpoint `/callbacks/tbank`
- `CLOSURE_PREP.md` + `RECOVERY.md` (Subtask 23)
- `todo.md` — единая пачка до REVIEW
- Local regress: tbank_receipt + fiscal_handler + tbank_controller + order_fiscal_api **31/0**
- Следующий: `/review` отдельно; deploy + fiscal notify ON — апрув

### Сессия 2026-08-27 — Fly v459 deploy + MCP пачка

- Deploy **v459** (`deployment-01M11RD5W850BADA7T5CS7C5Q5`) с develop `0609ae6b`
- Local: tbank+adapter+fiscal+saved_card zones PASS
- Webhook plain OK на Fly: Rack `[200,"OK","text/plain"]` · invalid Token 401
- #72 PARTIAL (smoke+D PASS; live Init SKIP) · #73 PARTIAL (fiscal notify OFF / fr=0) · #74 PARTIAL (schema+dry_run; E2E SKIP)
- Артефакты: `…/mcp/fly_v459_2026-08-27/`

### Сессия 2026-08-27 — T-Bank webhook plain `OK` REVIEW

- bugbot: no bugs · security: no medium+ · Entire `01M11PSGEBSPNB7VMM6MFKDWG3` на `0ee54a97`
- CI: stale JSON assert → `86ead973` plain OK · watch green
- Local 46/0 · Fly MCP после deploy

### Сессия 2026-08-27 — #74 REVIEW

- bugbot High: legacy bank_card_id + pepper; pan+exp extreme сохранён
- security medium: CardId absent остаётся best-effort (SPEC)
- Entire `01M11NEP02FPMW463C1RK4A1T5` · push develop

---

## Текущий месяц (2026-08)

### Сессия 2026-08-27 — T-Bank webhook plain `OK` /regress PASS

- tbank callback+adapter **46/0**
- Fly MCP Point A — после deploy (апрув); hot-path оплата

### Сессия 2026-08-27 — T-Bank webhook plain `OK` SPEC

- Цель: не-fiscal success → `render plain: "OK"` (дока банка; иначе ретраи)
- Файлы 3 + blast 2 · Не ломать/Проверка в `todo.md`
- #74 REVIEW на паузе

### Сессия 2026-08-27 — #74 /regress PASS

- saved_card_store **5/0**
- tbank callback+adapter **46/0**
- step5+step6 save_card **8/0**
- Fly MCP Point A — после deploy (апрув)

### Сессия 2026-08-27 — #74 SPEC card binding unique hash

- Gap: `card_hash` ← keyed hash `CardId`/`bank_card_id`; Minitest не RSpec
- Файлы 5 + blast 3 · Не ломать/Проверка в `todo.md`
- Migration Gate на DDL/data-migration apply

### Сессия 2026-08-27 — #74 intake card binding unique hash

- ТЗ 1:1: `customer_tasks/Устранение утечки данных чужой карты при привязке.md`
- Артефакты: `artifacts/card_binding_unique_hash/`
- CBR строка #74 · статус intake · ждёт `/spec`
- Группа: security review (задача 1)
- Заметка: в ТЗ `rspec/spec` → в репо Minitest `test/`

### Сессия 2026-08-27 — #73 /regress PASS

- T-Bank callback+adapter **46/0**
- pwa_lk_api **3/0**
- fiscal handler+API **6/0**
- Fly MCP Point A — после deploy (апрув)

### Сессия 2026-08-27 — #73 SPEC fiscal receipts ЛК

- Gap: inbound fiscal greenfield; reuse `FiscalReceipt`; webhook `/callbacks/tbank`; UI `OrderReceipt.svelte`
- Файлы 6 + blast 3 · Не ломать/Проверка в `todo.md`
- Блокер: схема+пример payload до GREEN

### Сессия 2026-08-27 — #73 intake fiscal receipts ЛК

- ТЗ 1:1: `customer_tasks/Хранение и отображение фискальных чеков в личном кабинете.md`
- Артефакты: `artifacts/fiscal_receipts_personal_cabinet/`
- CBR строка #73 · статус intake · ждёт `/spec`
- Блокер: Subtask 1 — схема/пример fiscal notification до GREEN

### Сессия 2026-08-27 — CI flake get_payment_state

- Root: `payment_status_confirm_test` `remove_method :get_payment_state` + prepend Override → super NoMethodError в parallel
- Fix: flag-gated prepend stub (как usercards phase1)

### Сессия 2026-08-27 — #72 MCP checklist (без deploy)

- Deploy **не** делаем (экономия владельца)
- Чеклист для агента: `artifacts/receipt_email_fiscal_checks/MCP_DEPLOY_CHECKLIST.md`
- Копипаст промпта — в файле

### Сессия 2026-08-27 — #72 REVIEW

- Local: builder+adapter+sbp+order_creator **70/0**
- Bugbot: findings вне #72 (webhook claim / bounce #71) — backlog, не блокер Receipt
- Security: **no medium+** на Receipt Init
- Entire: `01M11269FD48FXF42NCW98AG0X` на `5f68efea` (не пустой)
- Push develop → CI

### Сессия 2026-08-27 — #72 /regress PASS

- Зона оплаты: builder+adapter+sbp **48/0** · order_creator+qa_2.3 **24/0** (2 skip) · widget+inline **12/0**
- GREEN `5f68efea` · Entire `01M11269FD48FXF42NCW98AG0X`
- Next: `/review` (bugbot+security · push/CI); Fly MCP Point A после deploy

### Сессия 2026-08-27 — #72 SPEC (Receipt.Email)

- Gap: Receipt только на SBP Init; card/widget/new_card Init без Receipt; Confirm/Cancel без Receipt (ожидаемо)
- SendClosingReceipt / prepayment — NOT FOUND → SKIP + docs
- Политика: Email>Phone из MobileCustomer; не возвращать email-гейт #71
- todo: `docs/operations/session/todo.md`

### Сессия 2026-08-27 — #72 Receipt.Email intake (PHASE 0)

- Серия security review: старт с #72 (остальные задачи серии — отдельно)
- ТЗ 1:1 → `customer_tasks/Доработка бэкенда — передача email покупателя в Receipt для фискальных чеков.md`
- Артефакты → `artifacts/receipt_email_fiscal_checks/`
- CBR строка #72 · статус **intake** · ждёт `/spec`
- Open decisions: полный Cancel без Receipt; триггер SendClosingReceipt
- Напряжение с #71: не возвращать email-OTP гейт; Callcheck phone → Receipt.Phone fallback

### Сессия 2026-08-26 — #71 MCP API догон (без live pay)

- D1 HTTP 200 + reconnect_token + `tenant_id` query · D2 404 · D4 HMAC bounce → `bounced`
- A3: `save_card` в Fly JS bundle; UI после Callcheck
- D5: EmailService не трогает FiscalReceipt; Point A fiscal_receipts=0 (demo)
- Вердикт: **PASS (без live pay)**; B5/B6 SKIP

### Сессия 2026-08-26 — Deploy v458 + MCP #69/#70/#71

- Deploy: v457 fail (advisory lock после `CreateOrderEmails`) → retry **v458** OK
- `#70` Telegram support ЛК: **Fly MCP PASS** → `artifacts/telegram_bot_support_lk/mcp/fly_v458_2026-08-26/`
- `#69` PWA ЛК: **Fly MCP PASS** → `artifacts/pwa_personal_account_lk/mcp/fly_v458_2026-08-26/`
- `#71` Email after pay: **Fly MCP PARTIAL** (A1/B1–B4 UI PASS; B5/B6 live pay SKIP) → `artifacts/email_collection_after_payment/mcp/fly_v458_2026-08-26/`
- Bounce: `CALLBACK_SHARED_SECRET` set; POST без подписи → 401
- Sentry/УК: SKIP в этом прогоне

### Сессия 2026-08-26 — #71 Entire backfill

- Symlink WSL `~/.cursor` → Windows Cursor projects (иначе attach transcript-not-found)
- `entire session attach 5a70b841… --force` → checkpoint `01M0Z3E52ZCDTRECJT1F22G954` на `2e551ea7`
- `explain` не пустой (Intent + Transcript)

### Сессия 2026-08-26 — #71 REVIEW

- Bugbot: API path `/orders/:id/email` · `waitingForBank=false` на success
- Security: bounce HMAC ENV · visibility = OrdersController · reconnect_token
- Entire: attach transcript-not-found (CLI) — backfill later
- Next: push → CI → deploy апрув · Fly MCP

### Сессия 2026-08-26 — #71 regress PASS

- JS: email_collection 12/0 · shop_personal_account_lk 6/0 · telegram_support 13/0
- Rails: orders_email 6/0 · checkout_acceptance_cbr 10/0
- Next: /review (Entire attach + push); Fly MCP Point A — после deploy

### Сессия 2026-08-26 — #71 Email after pay GREEN slice 1

- RED `0eeaea77` · GREEN `31cf0e21`: PaymentResult показывает email-блок; `::Orders::EmailService`; Checkout без «Имя»
- Tests: JS 12/0 · Rails orders_email 6/0
- Entire: attach CLI transcript-not-found → pending /review
- Next: /regress

### Сессия 2026-08-26 — #71 Email after pay (intake+SPEC)

- Канон ТЗ: `customer_tasks/Email-сбор после оплаты (Callcheck-флоу).md` · CBR #71 · artifacts `email_collection_after_payment/`
- Gap: Cloud Code `c73308ae`/`18968c05` каркас есть; happy-path email-блок, Minitest вместо RSpec stubs, INTEGRATIONS
- Next: RED

### Сессия 2026-08-26 — #70 REVIEW

- Bugbot: убран fallback `VITE_SHOP_TELEGRAM_URL` → `f2cfceb2`
- Security: #70 OK; email bounce webhook — вне #70 (backlog)
- Entire: `01M0YNQZGQSNJ5Z6XSNGHGHHZB` на `f2cfceb2`

### Сессия 2026-08-26 — #70 regress PASS

- JS: telegram_support 13/0 · shop_personal_account_lk 6/0
- Rails: pwa_personal_account_lk + profile_ui_contract 6/0
- Next: /review (Entire attach + push)

### Сессия 2026-08-26 — #70 Telegram bot support ЛК (intake+SPEC)

- Канон ТЗ: `customer_tasks/Связь через Telegram-бота поддержки в ЛК.md` · CBR #70 · artifacts `telegram_bot_support_lk/`
- GREEN `7cfc3736`: единый `SUPPORT_TELEGRAM_URL`

### Сессия 2026-08-26 — #69 regress local PASS

- Ruby 24/0 · Node 6/0 · fix profile_ui_contract «Подтвердить»

### Сессия 2026-08-26 — #69 PWA ЛК GREEN slice 1

- Intake + SPEC + hub/settings/about/receipt + logout API
- Local: Ruby 6/0 · Node 6/0 по зоне #69

### Сессия 2026-08-18 — rules: уменьшение токенов always-подсказок

- Оценка: ≈6648 токенов -> ≈4594 токенов (~-31%) на always applied rules; ключевые триггеры/формат отчёта сохранены.

### Сессия 2026-08-15 (MCP Point A Chrome #64–#68)

- Entire trailer: `01M02FTNFTCX13ZSPHDGCNC292` на `7f5925e` (`explain HEAD` не пустой)
- Fly **v456**. Point A: skeleton снят, Ленина 10, `categories?tenant_id=` 200
- #64 Chrome PASS · #65 PASS (unknown 404, blank 422, restore Point A)
- #66 Chrome PASS (hash product, cache key scoped, нет telegram.org)
- #67 PARTIAL (S7 keyboard SKIP)
- #68 PASS (offline баннер один, корзина +5₽ жива)
- TG/IG устройства skip. CBR не `[x]`
- Пачка: Sentry skip (нет MCP) · Fly logs poll 8с 200, 404/422 #65 ожидаемы · Neon skip · УК skip (не логинились /manager)

### Сессия 2026-08-15 (push + fly deploy v456)

- Push `develop` `d8e61821`
- `fly deploy -a coffeeos --remote-only --depot=false` → **v456** `deployment-01M02H0BQ0HYY6AFTRNWCS8RS5`
- `/up` 200 · Point A `/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` 200
- MCP Point A выполнен 2026-08-15 (см. сессию выше)

### Сессия 2026-08-15 (#64–#68 pre-deploy suite)

- JS 50/0: webview ux/perf + catalog + webview + ui + tenant query
- Rails 34/0 (211 assert): webview + boot + linkage + categories + S2a CartSheet
- + tenant isolation API 2/0
- Полный `test/integration/shop/` на Windows не гоняли (канон)
- Deploy не делали

### Сессия 2026-08-15 (Entire: обогащать обязательно)

- Закон в `ENTIRE.md`: пустой `explain` / «spec OK» без checkpoint id — не ревью
- PHASE 3 шаг 3 стоп до attach; отчёт `Entire: <id> на <sha>`
- Указатели: spec-build-review, commit-ops GREEN, agent-workflow, `.cursorrules`, `/sbr` `/review`

### Сессия 2026-08-15 (#64–#68 Entire backfill)

- GREEN SHA не переписывали (`ed324b20` `89ecfaf7` `ca9c5834` `8daadddf` `ff9374d1`)
- Why-context: `entire session attach` → checkpoint `01M02FTNFTCX13ZSPHDGCNC292` на `54e79d1a` (push + git-ref)
- Сессии: #64 `f6ad5bfa` · #65 `f141e171` · #66 `8b384332` · #67 `7b9bead5` · backfill `fc6715de`; #68 `7851e58b` на `d01b1ac`
- Новых endpoints нет · spec vs `shop-api.md` § Embedded/WebView OK
- Дальше: deploy апрув · MCP Point A + TG/IG устройство

### Сессия 2026-08-15 (#68 Entire Windows CLI)

- Gap: GREEN `ff9374d1` без trailer (commit из PowerShell, `entire` не был в PATH)
- Фикс: `scoop install entire/cli` 0.8.42 · git hook находит `entire`
- SHA GREEN не переписываем (уже на origin). Checkpoint — этот коммит + attach Cursor-сессии
- Deploy по-прежнему апрув

### Сессия 2026-08-15 (#68 PHASE 3 /review CI)

- Local JS 46/0 · Rails 8/0
- bugbot+security-review: Cursor Task usage limit → manual, блокеров нет
- Entire: нет checkpoint `ff9374d1` (hook skip Windows) · spec vs todo/shop-api WebView UX/perf OK
- CI 5/5 [run 31878722151](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31878722151)
- Push develop · стоп: deploy апрув

### Сессия 2026-08-15 (#68 PHASE 3 /review)

- Local JS 46/0 · Rails 8/0
- bugbot+security-review: Cursor Task usage limit → manual review, блокеров нет (кэш по tenant, не auth; retry inflight; storage try/catch; layout #67 не трогали)
- Entire: `explain ff9374d1` no trailer (hook skip Windows) · spec vs todo/shop-api WebView UX/perf OK
- Push develop · стоп до CI green · deploy апрув

### Сессия 2026-08-15 (#68 /regress shop WebView UX/perf)

- Зона shop WebView: JS 46/0 · Rails webview+boot 8/0
- Полный `test/integration/shop/` на Windows не гоняли (канон)
- Fly MCP Point A — skip, только local; «готово заказчику» после deploy + MCP

### Сессия 2026-08-15 (#68 intake + SPEC Telegram WebView UX/perf)

- CBR #68 · ТЗ 1:1 · artifacts `mobile_storefront_telegram_webview_ux_perf/`
- SPEC: SWR catalog + lazy images + retry/offline kinds; тесты `shop_telegram_webview_ux_perf_test.mjs`
- Стоп до RED. #67 deploy не этот шаг. #64–#67 runtime/layout не трогаем.

### Сессия 2026-08-15 (#67 PHASE 3 /review CI)

- Local JS 27/0 · Rails 8/0 · S2a 12/0
- bugbot+security-review: Cursor Task usage limit → manual, блокеров нет
- Entire: нет checkpoint (hook skip Windows) · spec vs todo/shop-api OK
- CI 1 fail S2a CART_SHEET_BOTTOM_REM → фикс `--shop-safe-bottom` `cbcb58f9` · [ci-investigator](54659a3f-734e-4465-b282-e290decf642d)
- Push · CI green 5/5 [run 31877829022](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31877829022)
- Стоп: deploy апрув

### Сессия 2026-08-15 (#67 PHASE 3 /review)

- Local JS 27/0 · Rails 8/0
- bugbot+security-review: Cursor Task usage limit → manual review, блокеров нет (нет auth/UA/secrets; tenant/API не трогали)
- Entire: нет checkpoint (hook skip Windows · `explain 8daadddf` no trailer) · spec vs todo/shop-api WebView UI OK
- Push develop · стоп до CI green · deploy апрув

### Сессия 2026-08-15 (#67 /regress shop WebView UI)

- Зона shop WebView: JS 27/0 · Rails webview+boot 8/0
- Полный `test/integration/shop/` на Windows не гоняли (канон)
- Fly MCP Point A — skip, только local; «готово заказчику» после deploy + MCP

### Сессия 2026-08-15 (#67 intake + SPEC Telegram WebView UI)

- CBR #67 · ТЗ 1:1 · artifacts `mobile_storefront_telegram_webview_ui/`
- SPEC: `shopWebViewLayout.js` + CartSheet/Header/Catalog на `--shop-vvh`; тесты `shop_telegram_webview_ui_test.mjs`
- Стоп до апрува RED. #66 deploy не этот шаг. Задача 5 (perf) вне scope.

### Сессия 2026-08-15 (#66 PHASE 3 /review)

- Local JS 23/0 · Rails 12/0
- bugbot+security-review: Cursor Task usage limit → manual review, блокеров нет
- Entire: нет checkpoint (hook skip Windows) · spec vs todo/shop-api OK
- Push `044f3130` · CI green 5/5 · --log-failed пусто
- Стоп: deploy апрув

### Сессия 2026-08-15 (канон PHASE 3 REVIEW)

- Единый порядок в `spec-build-review` § PHASE 3
- Push в фазе `/review` без «пушить?»; deploy — только апрув
- Остальные файлы — указатели, без дубля таблицы

### Сессия 2026-08-15 (#66 GREEN+REVIEW Telegram WebView)

- Layer `shopWebView.js`; guest sessionStorage throw; catalog cache by tenant; viewport-fit
- Local JS 23/0 · Rails webview 5/0 · boot+linkage 7/0
- bugbot skip (Cursor usage limit) · Entire checkpoint нет (hook skip Windows)
- Fly MCP / TG устройство — после deploy

### Сессия 2026-08-15 (#66 SPEC Telegram WebView)

- Compatibility layer `shopWebView.js`; guest session try/catch; catalog cache by tenant; viewport-fit
- Дальше RED

### Сессия 2026-08-15 (#66 intake Telegram WebView)

- CBR #66 · задача 3 серии TG/IG → `/shop`
- ТЗ 1:1 + artifacts `mobile_storefront_telegram_webview/`
- Bot / payments / Instagram-specific / UI#4 / perf#5 — вне scope
- Дальше SPEC

### Сессия 2026-08-14 (#65 REVIEW / CI Vite)

- Local зона: JS 9/0 · categories 7/0 · linkage 4/0 · boot 3/0
- REVIEW manual (bugbot/security — лимит Cursor): без CSRF/CORS/UA-auth OK
- CI `f861048d` FAIL Vite на GET /shop → linkage tests без layout
- Deploy не делали

### Сессия 2026-08-14 (CI Tbank enqueue flake)

- Run https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31797599803 · job `test`
- `CONFIRMED performs TbankCallbackJob inline`: 0 jobs expected, 1 enqueued
- Причина: CONFIRMED без RebillId → GetState/`retry_on`; RLS ENABLE соседним worker
- Фикс теста: `save_card:false` · disable RLS каждый setup · clear queue
- Local WSL: `bin/rails test test/controllers/callbacks/tbank_controller_test.rb` → 16/0

### Сессия 2026-08-14 (#65 GREEN linkage)

- Явный `?tenant_id=` (даже blank) → без silent fallback; query > meta
- FE: export `resolvedShopTenantId` / `withTenantQuery`; blank key → `tenant_id=` в API URL
- Rails: `params.key?(:tenant_id)` short-circuit
- Local: JS 9/0 · categories 7/0 · linkage 3/0 · boot 3/0
- Fly MCP / TG-IG — после deploy

### Сессия 2026-08-14 (#65 SPEC)

- todo: целостность `tenant_id` link→HTML→API; identity без TG/UA auth; errors/cache; без forced redirect
- Файлы: `api.js` · `tenant_resolution` · shop base/pages · `catalog.js` · `shop-api.md`
- Дальше RED по намерению; #64 MCP не смешивать

### Сессия 2026-08-14 (#65 intake linkage)

- CBR **#65** · ТЗ 1:1 связка Telegram/Instagram In-App → CoffeeOS `/shop`
- Артефакты: `artifacts/telegram_instagram_inapp_shop_linkage/`
- Не смешивать с недозакрытым #64 (Fly MCP / TG-IG устройства)
- Код / SPEC не трогали — ждём `go`

### Сессия 2026-08-14 (push develop)

- `git push origin develop` `4daa2a36..41b22c12`
- Включает: MCP v455 · #64 intake/RED/GREEN · пайплайн стенд в rules
- Deploy не делали

### Сессия 2026-08-14 (пайплайн стенд → rules)

- Канон: local → review → commit → push → CI green → deploy → пачка Sentry 24ч + Fly logs + Neon + УК **вместе с** MCP Point A
- Файл: `coffeeos-dev-gates.mdc` § пайплайн; указатели в index / RULES_INDEX / agent-workflow / .cursorrules
- #64 не деплоили

### Сессия 2026-08-14 (#64 GREEN boot watchdog)

- Chrome Point A: HTML+module+mount+каталог PASS; cookie не нужен для меню
- Точка отказа: единственный boot = `type=module`; без classic fallback вечный skeleton
- GREEN: `shop-boot-watchdog` · try/catch mount · Catalog «Повторить» · loadCatalog storage/API tests
- Local: JS 5/0 · boot structural 3/0 · Fly MCP / TG/IG устройства — после deploy
- Без UA-веток и без redirect «открой в Chrome»

### Сессия 2026-08-14 (#64 intake+SPEC)

- ТЗ 1:1: `customer_tasks/Исправление открытия shop во встроенных браузерах Telegram и Instagram.md`
- CBR #64 · artifacts `shop_telegram_instagram_inapp_browser/`
- SPEC в `todo.md`: 7 файлов · Не ломать Chrome/Safari/cart/CSRF · Проверка `node --test` + 2 shop tests
- Код не меняли; причина не доказана; задачи 2–5 серии — другие диалоги

### Сессия 2026-08-14 (MCP Point A v455)

- Point A: каталог / product / checkout / pay stack / profile — **PASS**
- Статусный sheet скрыт на product/checkout/profile; pay: СБП + `*8782`/`*5953` + «Картой +», без Failed to fetch
- Dismiss X skip (нет активного заказа; карту Арама не чарджили)
- Косяков на правку не найдено
- Evidence: `mcp/fly_v455_2026-08-14/`

### Сессия 2026-08-14 (Fly v455 Sentry)

- Deploy `coffeeos` v455 `deployment-01KZZXM710GG6FWTXYN47PBBHC`
- release: OK, без ConcurrentMigrationError; migrate:cache 1 file; queue/cable skip
- `/up` 200 · health passing · Point A API 200 в логах

### Сессия 2026-08-14 (Sentry triage)

- RUBY-19: `ModifierGroupsPresenter` — active options из preload, без `.active.ordered`
- RUBY-V: `CartService#json_lines` — available из пачки settings, без EXISTS на строку
- Filter: ConcurrentMigrationError / SystemExit / CLI NameError… — не HTTP гостя
- Local: presenter+cart+sentry+mount 34/0 · products API отдельно
- Push `75e9d91e` · CI https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31792302569 — 5/5 green

### Сессия 2026-08-14 (WSL full shop suite + CI flake)

- WSL `test/integration/shop/`: **506 runs, 0 failures, 3 skips** (`scripts/scratch/run_shop_suite_wsl.sh`)
- CI #33: Tbank `assert_no_enqueued_jobs` flake — unique `provider_payment_id` per test (parallel idempotency cache)

### Сессия 2026-08-14 (legacy triage + dismissedIds)

- Legacy 4 + mount acceptance: 27 runs green (CBR b11_02, UserCards E7)
- JS suite: 294/294 (Wallet label i18n)
- `orderStatusSheet`: terminal cable не `delete dismissedIds` — dismiss сохраняется при stale re-sync

### Сессия 2026-08-13 (#63 deploy + MCP Point A)

- Fly **v454** `deployment-01KZXTPAA7K1YQ8RNHWW6K4BBA`
- MCP Point A: catalog sheet+X · dismiss · product/profile hide · checkout hide · pay `#202608-0042` → cancel cleanup
- Evidence: `artifacts/svelte5_status_widget_reactivity_ux/mcp/fly_v454_2026-08-13/`

### Сессия 2026-08-13 (#63 Svelte 5 status widget UX)

- Доп к #35: `orderStatusSheet` — map/filter без in-place; `dismissOrder`/`userDismissed`; `shouldShowStatusSheetUi` (product/profile/checkout/pay)
- UI: X на accordion row; Cable живёт после dismiss; ready не поднимает закрытый виджет
- Local: `node --test test/javascript/order_status_sheet_test.mjs` → 22/0

### Сессия 2026-08-13 (CI #31 green)

- Подтверждено Actions #31 `success` на `353c5a7a` (все 5 jobs)

### Сессия 2026-08-13 (CI #30 — 7 fail + 1 error)

- J1: Rack::Attack — global disable+clear в `test_helper`; `sessions_controller_test` teardown не включает лимит; `login_as!` не восстанавливает enabled
- J2: onboarding UK — `weekday_schedules` + city/address в `franchise_platform_admin_test` · `platform_uk_rbac_test`
- J3: `manager_volume_test` — `count-accepted` 250 (total, не cap колонки)
- J4: `payment_status_confirm_test` teardown — `remove_method` вместо restore prepended `super`
- Local: 8 target files PASS (75 runs)

### Сессия 2026-08-13 (CI test clusters A–I)

- A: `setup-node` + `npm ci` в jobs `test` / `system-test`
- B: FakeTbank `init_payment` + `pay_type`/`data`
- C: `include TestFactories` в 3 service tests (+ OpenStruct / roles_summary count)
- D: B21 push body `🟩🟩⬜ …`
- E: shop orders — email + `verify_shop_email!`
- F: onboarding — `weekday_schedules` в payload (+ teardown schedules)
- G/H: turbo board replace · `count-accepted`
- I: RLS role CREATE race rescue
- Local sample: 41 runs PASS

### Сессия 2026-08-13 (CI после bin/+x — реальные fails)

- «Стало больше» = exit 126 ушёл, видны настоящие jobs
- lint: trailing whitespace + StringLiterals (3 файла)
- scan_ruby: brakeman `--ensure-latest` 8.0.4→8.0.6 + `config/brakeman.ignore` (3 FP) + bundler-audit (rails 8.1.3.1, puma 8.0.2, nokogiri, …)
- system-test: skip если нет `test/system/*`
- test: без публичных логов; вероятно legacy shop / suite — triage отдельно

### Сессия 2026-08-13 (CI exit 126 → bin/+x)

- Все jobs CI падали за ~40s с **exit 126** (Permission denied на `bin/rails` / brakeman / rubocop / importmap)
- Причина: в git index mode **100644** вместо **100755** (Windows)
- Fix: `git update-index --chmod=+x` на скрипты `bin/**` (без README/.cmd/.ps1)

### Сессия 2026-08-13 (push+deploy+MCP recheck NET+A6)

- Push `7d4e9c2c` → Fly **v451** · NET MCP PASS (нет Failed to fetch)
- A6 на v451 ещё race → `refresh_cache!` `c17c67cd` → Fly **v452** · cancel→повторить PASS без reload
- Evidence: `mcp/fly_2026-08-13_recheck/MCP_RESULT.md` · ISSUES закрыты

### Сессия 2026-08-13 (фикс MCP FAIL: NET raw + A6 frequent)

- NET: `resolveCheckoutSheetInlineError` → null для NET/CLIENT/BANK
- A6: сначала bust, затем refresh_cache! (bust+write) против race poll

### Сессия 2026-08-13 (push+deploy v450 + MCP Point A пакет)

- Push `develop` `8f51deba` · `fly deploy --remote-only --depot=false` → **v450** `deployment-01KZXCYNBPG9CVXJGTKG0BSXDS` · `/up` 200
- MCP Point A: evidence [`sbp_autopay_checkbox_default_checked/mcp/fly_2026-08-13/MCP_RESULT.md`](../../milestones/veha_2/artifacts/sbp_autopay_checkbox_default_checked/mcp/fly_2026-08-13/MCP_RESULT.md)
- PASS: #62 checkbox ON · SBP enable · sheet 09 · NewCard in sheet · Callcheck · status in sheet · Repeat peek
- FAIL: NET alert сырой `Failed to fetch` · A6 frequent `has_active_order` после cancel → ISSUES
- OTP в профиль Арама не писали (mint MobileSession)

### Сессия 2026-08-13 (#62 предустановленный чекбокс автоплатежа СБП)

- ТЗ 1:1: `customer_tasks/Предустановленный чекбокс автоплатежа СБП.md`
- CBR #62 · artifacts `sbp_autopay_checkbox_default_checked/`
- UI: `DEFAULT_SAVE_SBP_ACCOUNT=true` + `saveSbpAccountTouched` + `resolveSaveSbpAccountForSbpMode`
- Backend/AccountToken/#34 не трогали; CHARGE_DECLINED fallback по-прежнему `saveSbpAccount: false`
- Local: JS SBP zone **39/0 PASS** · Fly MCP: skip (ждёт push/deploy)
- Коммиты: intake `2c1c6bf2` · RED `e22d3afa` · GREEN `c35a5098`

### Сессия 2026-08-13 (понятные сообщения при ошибке оплаты)

- ТЗ 1:1: `customer_tasks/Понятные сообщения пользователю при ошибке оплаты.md`
- Карта → длинный текст; сеть/timeout → «Нет связи. Повторить» + CTA `inline-pay-retry`
- Повтор = тот же `onPayCardClick` (без нового payment flow)
- Local: JS **17/0** · `repeat_invalid_token` **12/0** · `shop_pay_fsm_3ds` PASS · Fly MCP: skip

### Сессия 2026-08-13 (invalid token + One-Click → PaymentMethodsSheet)

- Скрины заказчика: `09_…canon`, `10_…new_card`, `09_…clipped` в artifacts
- `openRepeatPaymentSheet`: markOpen + checkout pay-stack; addToCart только если cart empty
- RepeatSection: fail → `setTokenInvalid`; «карта +» → полная шторка (не peek expand)
- Local: JS UX + `repeat_invalid_token_payment` **12/0** · Fly MCP: skip

### Сессия 2026-08-12 (BUG-REPORT Callcheck not FlashCall)

- Канон: Callcheck primary + SMS fallback; `/code/call` вне auth
- API: init_callcheck / check_status / send_sms / verify_sms; session-bound check_id
- PWA: poll 3s, timeout 40s → SMS; PIN только на SMS
- Local: phone_otp + auth_funnel + profile_merge + CBR + JS → PASS
- Fly MCP: skip

### Сессия 2026-08-12 (Phone OTP: Flash Call / SMS раздельно)

- **SUPERSEDED** ошибочным каноном равноправных каналов → Callcheck BUG-REPORT

### Сессия 2026-08-12 (enable SBP in checkout sheet)

- Root cause: #26 G4 hardcoded disabled (не кабинет)
- `PaymentMethodsSheet` → onSelectSbp / onSelectSbpAccount
- Local: 29 runs, 0 failures (sbp UI + CBR + invalid token + cleanup + sbp accounts)
- Fly MCP: skip (нет push/deploy)

### Сессия 2026-08-11 (push + fly deploy v448 + MCP)

- push develop → `1c53a065`
- `fly deploy` coffeeos **v448** web+worker started
- Smoke: `/up` 200 · tbank 401 · tbank body 413 · sms_ru 401 · Point A shop 200
- MCP browser Point A: витрина + корзина OK

### Сессия 2026-08-11 (PHASE 3 /review #2 residual)

- Bugbot: **no bugs**
- Security: SMS.ru + Tbank mediums **все CLOSED**; medium+ в callback hot-path нет
- Entire: `10774cfe` — см. лог (часто no trailer)
- Local regress: 23/0 · Fly MCP: skip

### Сессия 2026-08-11 (/regress SMS.ru + Tbank residual)

- `ruby bin/rails test …sms_ru_controller… tbank_controller…` → **23 runs, 0 failures PASS**
- Fly MCP: skip (regress только local)

### Сессия 2026-08-11 (PHASE 3 /review)

- Bugbot + Security на branch changes
- Tbank: body 413 + Rails.cache claim — **security CLOSED**
- Остаток: SMS.ru body/dedup · CI full suite (legacy red) · Entire checkpoint missing на `d26acf09`
- Local regress: 49/0 · Fly MCP: skip

### Сессия 2026-08-11 (/regress Tbank body+cache)

- Зона: Tbank callback / adapter / CacheCounter
- `ruby bin/rails test …tbank_controller… tbank_adapter… cache_counter…` → **49 runs, 0 failures PASS**
- Fly MCP: skip (regress только local)

### Сессия 2026-08-11 (Bugbot: Tbank idempotency + CI)

- Tbank callback: release claim на 500 → bank retry не залипает
- CacheCounter: Mutex на claim/increment/delete/clear (same-pod)
- CI: push `develop`+`main`, Postgres 16 service для test/system-test
- Local: `ruby bin/rails test` tbank_controller + cache_counter + tbank_adapter → **47/0**

### Сессия 2026-08-11 (push + fly deploy v447)

- push develop → `858821af`
- `fly deploy` coffeeos **v447** web+worker · /up 200 · webhook 401 invalid hash · Point A shop 200
- Secrets: `SMS_RU_API_ID`, `SMS_RU_FROM`, `SHOP_OTP_LOG_FALLBACK` уже на Fly

### Сессия 2026-08-11 (#61 webhooks)

- `POST /callbacks/sms_ru` · hash SHA256(api_id+data) · sms_status → payload · callcheck → cache

### Сессия 2026-08-11 (#60 stoplist/get)

- `SmsRuClient.stoplist_get!` → `StoplistGetResult#stoplist` (Hash)

### Сессия 2026-08-11 (#59 stoplist/del)

- `SmsRuClient.stoplist_del!(phone:)` → `StoplistDelResult`

### Сессия 2026-08-11 (#58 stoplist/add)

- `SmsRuClient.stoplist_add!(phone:, text:)` → `StoplistAddResult`

### Сессия 2026-08-11 (#57 auth/check)

- `SmsRuClient.auth_check!` → `AuthCheckResult`; login/password SKIP

### Сессия 2026-08-11 (#56 my/senders)

- `SmsRuClient.senders!` → `SendersResult#senders`

### Сессия 2026-08-11 (#55 my/free)

- `SmsRuClient.free!` → `FreeResult` (total_free, used_today)

### Сессия 2026-08-11 (#54 my/limit)

- `SmsRuClient.limit!` → `LimitResult` (total_limit, used_today)

### Сессия 2026-08-11 (#53 my/balance)

- `SmsRuClient.balance!` → `BalanceResult`; не shop-прокси

### Сессия 2026-08-11 (#52 callcheck)

- `callcheck_add!` / `callcheck_status!`; PWA funnel **не** меняли (flash_call канон)

### Сессия 2026-08-11 (#51/#50/#49/#48)

- cost · status · email2sms SKIP · send

### Сессия 2026-08-10 (push + fly deploy v445 + MCP)

- `git push` develop → `4e52ac6e` (G1–G4)
- `fly deploy` coffeeos **v445** web+worker started · /up ok
- MCP Point A: session Aram · repeats · PaymentMethods *5953/*8782 · pay-stack **без** OrderStatusSheet
- Skip: live barista→ready push/SMS; UserCards E2E real MIR

### Сессия 2026-08-10 (Group 4 уведомления)

- SMS: skip if `order_notification_logs` already `sent`; cascade `SMS_GRACE=15s` before presence re-check
- FE: `pushRegisteredStorageKey` — permission alone ≠ subscribed; CTA labels = #37 MCP
- Local notify Rails 39/0 + JS 42/0; live Fly push/SMS — после deploy

### Сессия 2026-08-10 (Group 3 шторка / статусы / повторы)

- ready остаётся в `/orders/active` + Cable (не пусто +0₽); «повторить» всё ещё hide до issued
- Cable: `activeOrderIdsKey` — poll не reconnect каждый тик
- pay-stack: OrderStatusSheet не монтируется (`!payStackActive`)
- Local 45/0 + JS 42/0; MCP: repeats на каталоге PASS; FE на Fly ещё старый (нужен deploy)

### Сессия 2026-08-10 (Group 2 payments / cards / SBP)

- `PaymentStatusPresenter` → `error_code` из provider_data (1051 inline)
- `TbankPaymentSync` больше не выкидывает ErrorCode/Message из GetState
- Cancel ApiError → `GuestOrderCancellationService::Error` (422 + REFUND_UNAVAILABLE)
- `1051` убран из INVALID_REBILL_CODES (не «мёртвый» токен)
- Local 70/0 + JS 27; MCP Point A: *8782/*5953, СБП disabled; FE needs deploy

### Сессия 2026-08-10 (Group 1 session/auth/merge)

- Bug: parallel `restoreGuestSession` (App+CartSheet) → 2nd 401 wiped rotated `shop_refresh_token`
- Fix: `silentRefreshSession` inflight + clear-only-if-same-token; JS tests race/inflight
- Structural silent-refresh test aligned to camelCase `refreshToken` contract
- Local Group 1 rails+js PASS; MCP Point A profile email+phone Подтвержден
- FE fix **needs deploy** to land on Fly v444+

### Сессия 2026-08-10 (UserCards 3.5 MCP Point A)

- Local: UserCards зона **61/0** PASS
- Fly v444 worker started · diagnose `usercards_fly_diagnose_2026-08-10.json` — *5953 + *8782 + RebillId
- MCP PaymentMethodsSheet vs 8925 **PASS** — скрин `usercards_phase35_mcp_2026-08-10_payment_sheet_two_cards.png`
- E2E «Новая карта» real PAN — **BLOCKED** (prod test PAN → ACTIVATION_ERROR); не гоняли
- ISSUES UserCards → 🟡; апрув 3.5 ждёт владельца

### Сессия 2026-08-10 (integration bridge audit)

- **Gap matrix:** `docs/integrations/gap-matrix-pwa-payments.md` (17 задач + hot-path endpoints)
- **Bridge:** `shop-api.md`, `pwa-realtime.md`; расширены `tbank`, `sms-auth`, `notify-loyalty`, `INTEGRATIONS.md`
- **Runbook:** `docs/operations/runbooks/DEPLOY_PWA_PAYMENTS_BATCH.md` (preflight → deploy → MCP matrix)
- Код не менялся; продукт UserCards — следующий SBR (закрыто сессией 3.5 MCP ниже по шапке)

### Сессия 2026-08-10 (workflow audit)

- ISSUES: `## 🔴 Открыто` — таблица на старте; Entire git hooks через WSL enable
- AGENTS.md → slash-команды; удалён CURSOR_RULES_REPORT; Windows + дисциплина отчёта в rules

### Сессия 2026-08-09 (hot-path agent discipline)

- «Не ломать» + «Проверка» — обязательны на hot-path (снята отложка)
- DoD: Local + Fly MCP Point A; отчёт Local | Fly MCP
- Запрет gem’ов Tinkoff/Stripe / skills без просьбы; TbankAdapter канон
- MCP: не OTP на профиле заказчика; приёмка не Fly Test
- `DEMO_LOGINS` канон Point A; очередь продукта в `todo.md`

### Сессия 2026-08-09 (commands)

- `.cursor/commands/` + `.cursor/skills/` (human-only): start/spec/sbr/regress/review
- Умный /start (узкий vs PHASE 0); каждая команда печатает `Next: /…`

### Сессия 2026-08-09 (субагенты)

- Политика: фича/SBR → субагент по этапу; мелочь → отказ с пометкой
- Таблица: SPEC explore · RED/GREEN shell · REVIEW bugbot (+ security hot-path) · CI ci-investigator
- Отчёт: строка `Субагент: …`; карта `docs/agents/SUBAGENTS.md`

### Сессия 2026-08-09 (rules anti-noise)

- Шапка-only жёстко (limit до `---`; запрет глотать тело SESSION/HANDOFF/CHANGELOG/PRACTICES/QA)
- README не читать при Glob/дереве; ce-*/skills без роя на мелочь; субагент 1–2 по делу
- Мягкий blast-radius (+1–3); блоки «Не ломать»/«Проверка» — **включены** 2026-08-09 (hot-path)
- commit-ops > User Rule «commit only on ask» (лучше удалить User Rule в Cursor Settings)

### Сессия 2026-08-09 (docs cleanup)

- Удалено: `LIVE_DEMO_SCENARIOS.md` (v1+v2 tech), `qa/CODE_REVIEW.md` (v1+v2), `docs/agents/AGENTS/*`, `docs/product/core/*.sql.md` (+ README)
- Оставлены: PLAIN live-demo, `AGENTS.md`, product 01–03, archives/artifacts
- Живые ссылки: PATH_MAP, README вех, CHECKLIST, QA_ACCEPTANCE_RUN, PRACTICES, runbooks

### Сессия 2026-08-09 (bin reorg)

- Перенос: acceptance (58), prog10 (12), fly-tools (12); корень ~39 stubs
- Исправлены ROOT/`cd` в подпапках; обновлены ссылки в docs

### Сессия 2026-08-09 (folder READMEs)

- Сгенерированы короткие README по дереву репо для владельца/заказчика
- gitignore: разрешены README в log/tmp/storage/uploads/scratch/node_modules/coverage/…

### Сессия 2026-08-09 (`.cursor/README`)

- Добавлен `.cursor/README.md` — что в `rules/workflow`, `rules/project`, symlinks

### Сессия 2026-08-08 (#47 MCP)

- Browser: Aram Point A · до: frequent `has_active_order:true` пусто; POS ready→issued; без F5 → «повторить» ×3
- Evidence: `pwa_status_sync_and_repeats_stale/mcp/fly_v443_2026-08-08/`

### Сессия 2026-08-08 (#47 push/deploy)

- Push develop `56648134`
- Build image `deployment-01KZGG9538YYB9ZE5YBTEN9PQS`; v442 release machine API fail; retry `--image` → **v443** machines started · `/up` 200

### Сессия 2026-08-08 (#47 REVIEW)

- SBR закрыт локально: poll 8s + visibility + frequent after sync; Cable сохранён
- RED `6c7176fe` · GREEN `aeff9fa7` · JS 32/0
- MCP/push — ждут явный апрув

### Сессия 2026-08-08 (#47 intake + SPEC)

- PHASE 0: customer_tasks + artifacts `pwa_status_sync_and_repeats_stale` + CBR #47 + ISSUES 🔴
- SPEC: poll `/orders/active` + visibility + `refreshFrequentProducts`; файлы 2–5 в todo
- Token check: always ~2.9k vs ~12.7k (−77%); SPEC-ход rules+шапки ≪ старый full HANDOFF/SESSION

### Сессия 2026-08-08 (pinpoint code context)

- Правила: agent-workflow / SBR / task-workflow — список 2–7 файлов, без зряшного `@codebase`
- Graphify/`codebase-map.md` не заводили

### Сессия 2026-08-08 (архив CHANGELOG)

- CHANGELOG: ~257k→~23k B; июнь–июль → `journal/archive/`
- ISSUES: не архивировали; always — на старте только секция 🔴

### Сессия 2026-08-08 (архив ops)

- HANDOFF/SESSION_STATE: вынесены месяцы до августа в `session/archive/`
- Always + task-workflow: старт = шапка + 🔴 + todo; CHECKLIST/CBR только если веха
- Замер live B: HANDOFF ~76k→~19k · SESSION_STATE ~284k→~35k

**Дата:** 2026-08-07 (thin always-rules)

| Сейчас | Дальше |
|--------|--------|
| Always-правила сжаты: **~12.7k → ~2.9k tok/ход (−77%)** | Проверить на 1 мелочи + 1 фиче, что agent тянет on-demand |
| Дубли symlink core/performance удалены | Опционально: ужать HANDOFF/SESSION_STATE историю |

### Сессия 2026-08-07 (rules: thin always)

- **ДО:** 14 always-кусков · 626 lines · 50758 B · ~12690 tok
- **ПОСЛЕ:** 5 always (index, commit-ops, agent-workflow, core, `.cursorrules`) · 135 lines · 11775 B · ~2944 tok
- On-demand: task-workflow, SBR, gates, layout, intake, file-size-split; performance → globs Ruby
- Удалены symlink-дубли: `.cursor/rules/coffeeos-core.mdc`, `coffeeos-performance.mdc`
- Обновлены: `RULES_INDEX.md`, `AGENTS.md`, `.cursorrules`

**Дата:** 2026-08-07 (MCP Fly **v441** · #46+#33)

| Сейчас | Дальше |
|--------|--------|
| Fly **v441** · MCP #46 PASS (119→NewCard + *8782→Оплачен) | апрув заказчика «ок» |
| #33 helpers v441 · S1/S2 live v440 | — |

### Сессия 2026-08-07 (MCP · Fly v441)

- Deploy владельца: **v441** `01KZDZ59Z9113BYEWRVEHF3QBT` — machines started, `/up` 200
- #46 live: *5953 → 422 `119` friendly + NewCardForm; *8782 → order `db45ab5f-…` «Оплачен»
- Evidence: `bank_auth_limit_blocks_payment/mcp/fly_v441_2026-08-07/`

### Сессия 2026-08-07 (push/deploy/MCP · #33+#46)

- Push develop `11e5eaf7` · Fly **v440** · `deployment-01KZDYQPQCHWPFBPEX3XJF8JKA` · `/up` 200
- MCP: S1 отказ → только СБП/карта+; S2 «карта +» → *5953/*8782 + форма
- Evidence: `artifacts/tbank_widget_oneclick_fallback/mcp/fly_2026-08-07/`

**Дата:** 2026-08-07 (push/deploy/MCP · #33+#46 · Fly **v440**)

| Сейчас | Дальше |
|--------|--------|
| Fly **v440** · MCP S1/S2 **PASS** · push `11e5eaf7` | апрув заказчика «ок» |
| #46 в том же релизе | optional live checkout CTA после 119 |

### Сессия 2026-08-07 (PHASE 3 REVIEW · #33 fallback vs expanded)

- Helpers `resolveCardDeclineFallbackUi` / `resolveCardPlusExpandedUi`
- Тесты: JS 38/0 · widget_payment_initiator 6/0

**Дата:** 2026-08-07 (push/deploy/MCP · #26 · Fly **v439**)

| Сейчас | Дальше |
|--------|--------|
| Fly **v439** · MCP G1–G4 **PASS** · G7 live PARTIAL | апрув заказчика «ок» |
| Push `bd0e9fb0` | optional re-MCP insufficient когда нет rate-limit |

### Сессия 2026-08-07 (push/deploy/MCP · #26)

- Push develop `bd0e9fb0` · Fly **v439** · `/up` 200
- MCP Point A: sheet «Картой *5953/*8782», orange Pay, «Картой +», СБП disabled
- Live pay *5953 → BANK_ERROR rate-limit (не CLIENT_ERROR) — G7 unit+bundle
- Evidence: `artifacts/…/mcp/fly_v439_2026-08-07/`

### Сессия 2026-08-07 (PHASE 3 REVIEW · #26)

- Sanity: нет DDL/RLS; auth store не меняли; N+1 n/a (FE)
- Exit: G7 + G1–G4 `[x]`; MCP/push `[ ]`
- Residual: СБП disabled расходится с эпиком #27 (зафиксировано D1); live MCP insufficient на Fly

### Сессия 2026-08-07 (PHASE 2 GREEN · #26 G1–G4)

- i18n: `formatCardRowLabel` → `Картой *1594`; `formatMaskedPan` остаётся `****` (Step10)
- Sheet: prefix orange + mask; accent «Картой +»; SBP `disabled`; Pay `accent=orange`
- Тесты #26/#CBR/#27 flip under D1; cbr_08 → sheetCanPay

### Сессия 2026-08-07 (PHASE 2 GREEN · #26 G7)

- `resolvePayFsmCtaAction` / auto-open NewCardForm; CLIENT_ERROR → onChangeCard

### Сессия 2026-08-07 (PHASE 2 RED · #26 G7)

- Падающие тесты G7 (helpers / onChangeCard / Checkout wiring)
- Коммит `[RED]` `50419a0a`

### Сессия 2026-08-07 (PHASE 0+SPEC · live *5953 insufficient)

- Текст заказчика (дословно) + 5 скринов в artifacts
- Проблема: нет денег на *5953 → оплата → текст ошибки есть, форма новой карты **не** открывается
- Канон Then: скрин `05`; As-is: `04`/`08`
- SPEC: gap **G7** P0; D4 default = C; G1–G4 макет 03 вторичны к блокеру

### Сессия 2026-08-07 (PHASE 1 SPEC · #26)

- As-is: peek CTA + sheet + NewCard + errors уже есть (MCP v393)
- Gaps vs скрин 03: `Картой *XXXX` (не MIR/****), оранжевый «Оплатить», «+» вместо ⌄, СБП disabled
- Decisions: D1 СБП vs #27 · D2 маска vs Step10 · D3 accent Pay
- `todo.md` переписан; затем дополнен live G7

### Сессия 2026-08-07 (PHASE 0 · #26 re-intake)

- Текст заказчика совпал с ТЗ — тело не трогали
- Скрин → `screenshots/03_payment_method_bottom_sheet_invalid_token_2026-08-07.png`
- README + CBR #26 обновлены

### Сессия 2026-08-06 (push/deploy/MCP · #35 D1+D2)

- Push `4ca777a4` · Fly **v438** · `deployment-01KZBM95ZEVSW9G5GN87EW4RW6`
- MCP: `status-above-lines` · prog38 · status before lines · checkout pay-stack meta = «Фильтр-кофе… Гватемала»
- Evidence: `artifacts/order_status_compact_sheet_push/mcp/fly_v438_2026-08-06/`

### Сессия 2026-08-06 (PHASE 3 REVIEW · #35 D1+D2)

- Correctness/Kieran: нет critical; important — silent sales-point fallback → **fixed**
- Residual: stringly sheetContext / MCP visual (D4)
- Дальше: push + deploy + MCP по апруву владельца

### Сессия 2026-08-06 (PHASE 2 GREEN · #35 D1+D2)

- `data-cart-status-stack="status-above-lines"` на CartSheet
- `statusMetaThird` / `metaThird`: peek→точка, `cart_expanded`→первая позиция
- Wire: CartSheet sheetContext → OrderStatusSheet → ActiveOrdersAccordion
- Тесты: expanded/meta/peek/mount 18/0 · JS 32/0

### Сессия 2026-08-06 (PHASE 2 RED · #35 D1+D2)

- Тесты: `order_status_expanded_stack_canon_test` (1F/3P) · `order_status_meta_product_name_canon_test` (2F) · JS accordion import `statusMetaThird` FAIL
- Код реализации не писали

### Сессия 2026-08-06 (PHASE 1 SPEC · #35 + скрин 06)

- Маппинг: GuestOrderChannel / ReadyPushJob / ReadyPushClaim / embedded CartSheet (не React/RSpec)
- Baseline A1–A3, B1–B2, C1 = уже в коде + Fly v432 (01–05)
- Остаток: **D1** DOM-порядок expanded · **D2** мета = название позиции · **D3** регрессия · **D4** MCP 06 · **D5** optional ready→push
- Soft: toast A3 / model after_update — не блокер
- `todo.md` переписан; код не писали

### Сессия 2026-08-06 (PHASE 0 · #35 доп. скрин expanded)

- Сверка: тело ТЗ заказчика **=** уже принятый док — не перезаписывали
- Забытый скрин (стикер `expanded`) → `artifacts/order_status_compact_sheet_push/screenshots/06_expanded_sheet_status_plus_cart.png`
- Подпись чата «если заказ еще» → карта к `06`; README + CBR #35 обновлены
- Канон UI со скрина: статус *внутри* expanded-шторки над позициями + оплата; мета «…название позиции (только продукта)»

### Сессия 2026-08-06 (fix: status+cart peek stack)

- Баг: при активном заказе add на карточке — peek корзины не виден (только статус)
- Root cause: follow-up `hideCartTail` (`19231620`)
- Фикс: убрать гейт; `STATUS_IN_SHEET_EXTRA_VH`; empty placeholder скрыт при active+empty; `prog38`
- Тесты: `active_order_cart_peek_stack_test` + cart sheet zone **57/0**

### Сессия 2026-08-06 (правило: CartSheet без многослойности)

- Добавлен `.cursor/rules/project/coffeeos-cart-sheet.mdc` (+ symlink) — канон «секции стык в стык, не слои»
- Индекс: `RULES_INDEX.md`, ссылка из `coffeeos-ui.mdc`, `coffeeos-index.mdc`
- Поиск нарушений в коде — **после апрува владельца**

### Сессия 2026-08-06 (#44 · push/deploy/MCP)

- Push `7f7973e1` · Fly **v436** · `deployment-01KZB42C5176Y6MH07YGFSD0YF`
- MCP Point A: product in cart · `уже в заказе: 2` · CTA inside sheet · ± → 3 · build prog37
- Evidence: `artifacts/product_card_peek_cart/mcp/fly_v436_2026-08-06/`

### Сессия 2026-08-06 (#44 · GREEN single sheet)

- Root cause: ProductCartPeek + fixed bottom-bar + CartSheet на product
- `ProductSheetCta` + `productPageCtaStore` внутри CartSheet; удалён ProductCartPeek
- peek/hidden/expanded — секции одной шторки; `--cart-sheet-h` spacer; `PRODUCT_CTA_EXTRA_VH`
- Тесты product_card 28/28 · cart/product zone 135/0 · build prog37
- Push/MCP — не делали

### Сессия 2026-08-06 (#45 · MCP UI one-click)

- Сняли `#202608-0013` accepted→issued (иначе HIDE_REPEAT), очистили cart
- MCP click «оплатить в 1 клик» → `data-fsm=SUCCESS` «✔ Оплачено!»
- Order `#202608-0014` accepted · payment succeeded/tbank/`8995082965`
- Evidence: `mcp_fly_v435_ui_one_click_2026-08-06.json` + screenshot

### Сессия 2026-08-06 (#46 · UI follow-up: убираем хвост корзины)

- Наблюдение заказчика: при статусе активного заказа виден “хвост” строк корзины под статусом
- Фикс: в `app/frontend/components/CartSheet.svelte` при `hasActiveOrderFlag` не рендерятся peek/expanded/single блоки корзины (оставляем только `OrderStatusSheet`)
- Тесты: `quick_repeat_section_test` + `b113_s2a_cart_sheet_acceptance_test` + `cart_sheet_empty_orders_placeholder_test` (PASS)

### Сессия 2026-08-06 (#45 · deploy/MCP)

- Push `8db2bed2` · Fly **v435** · `deployment-01KZB0QYSKZM6BWWCVR840SNS4`
- Live Charge CONFIRMED PaymentId=8995036222 · order `#202608-0013` accepted
- Evidence: `artifacts/aram_one_click_payment_ssl_mintcifry/mcp_fly_v435_2026-08-06.json`

### Сессия 2026-08-06 (#45 · Aram 1-click pay broken)

- Root cause live: SSL к Т-Банку — Russian Trusted Root CA (НУЦ Минцифры); без CA → `certificate verify failed` → pid=nil
- У Арама RebillId *5953/*8782 есть; заказы #202608-0007…0011 failed/pending без provider_payment_id
- Фикс: `config/certs/` + Dockerfile `update-ca-certificates` + `SSL_CERT_FILE`
- FE: `userCardsApiPath` (?email), Charge по saved card, no-token → bind form
- BE: widget_init email → GuestCustomerResolver; Init pid до Charge
- Тесты: widget_payment_initiator  + payment_widget_init + JS user_cards_api_path — PASS

### Сессия 2026-08-06 (PHASE 0 · #44 product card peek cart reopen)

- Заказчик снова: не видит набранные позиции на карточке; peek без scroll / ±1
- **Не новая задача** — продолжение `product_card_peek_cart` (волна 2026-07-10 код есть, MCP/апрув не было, в CBR не было)
- ТЗ 1:1 перезаписан; файл переименован с `…pee.md`; скрины заменены (старые → `_archive_2026-07-10/`)
- CBR #44 · статус reopen intake
- Код/todo не трогали

### Сессия 2026-08-06 (push/deploy/MCP · #43)

- Push `c9c5aacd` · Fly **v434** · `deployment-01KZAVCVTD37NBM7CK9M7MFMFK`
- Server: Aram `has_active_order=false` · 3 frequent items
- MCP: 3× «оплатить в 1 клик» в шторке
- Evidence: `artifacts/repeat_hidden_by_stale_active_orders/mcp/fly_v434_2026-08-06/`

### Сессия 2026-08-06 (intake · #43)

- Арам: нет повторов / кнопок / истории после #42
- Root cause: `has_active_order?` без TTL (June accepted)
- ТЗ + artifacts `repeat_hidden_by_stale_active_orders/`

### Сессия 2026-08-05 (push/deploy/MCP · #42)

- Push `ec1e6a65` · Fly **v433** · `deployment-01KZ9913PP55V099F8Y6JQCK5V`
- Server: Aram 5 June accepted → 0 в 24h window
- MCP: reconnect → `orders/active=[]` · no sheet · `+3₽` visible
- Evidence: `artifacts/stuck_orders_status_sheet_blocks_payment/mcp/fly_v433_2026-08-05/`

### Сессия 2026-08-05 (GREEN · #42 stuck orders sheet)

- Intake: `Зависшие заказы в статусной шторке…` + CBR #42
- BE: `ACTIVE_ORDERS_WINDOW = 24.hours` на `#active`
- FE: peek `min(22vh, 8.5rem)`
- Тесты 11/11 PASS

### Сессия 2026-08-05 (push/deploy/MCP · #35 rev)

- Push develop `38df5088` · Fly **v432** · image `deployment-01KZ8W88G4HC0YK291M3FM011G`
- MCP Point A: sheet home + product `#/product/…` · 6 rows scrollable · cancel CTA на accepted (не ready)
- Evidence: `artifacts/order_status_compact_sheet_push/mcp/fly_v432_2026-08-05/`
- Smoke ready→hide+push — не гоняли

### Сессия 2026-08-05 (PHASE 0 + SPEC · #35 rev)

- ТЗ 1:1: виджет только accepted/paid/preparing; исчезает на `ready`; home + product; scroll >2
- Скрины `01–05` заменены в `artifacts/order_status_compact_sheet_push/screenshots/`
- SPEC: 8 дельт vs код v414 (главное: `orders/active` без ready; mount на `#/product`)
- Код не трогали

### Сессия 2026-08-05 (cancel MCP + fix can_cancel · #41)

- **Фикс:** `ActiveOrdersPresenter` + `GuestOrderBroadcaster` → `can_cancel`
- Fly **v431** deploy · MCP PASS: cancel CTA `#ff6b35`/44px + Confirm Sheet «Вернём 179 ₽…»
- Тест: `test/integration/shop/api/active_orders_test.rb` — **3/3 PASS**
- ISSUES Fly LB 503 → **resolved**

### Сессия 2026-08-05 (CBR ок + cancel MCP attempt · #41)

- CBR #41 → **закрыта `[x]`** по апруву владельца
- Cancel: `#202608-0005` → `accepted`+`can_cancel`; reconnect token; Fly edge **503** (`load balancing`) — UI cancel не снят
- Evidence note in `mcp/fly_v429_2026-08-05/MCP_RESULT.md`

### Сессия 2026-08-05 (push / deploy / MCP · #41)

- Push develop · Fly **v429** · image `deployment-01KZ88WP8VNXVGCBZVV4QZ0NAM`
- MCP Aram Point A: 17× `order-action-buttons` · 29× btn · kinds chat/push · 44px · `#ff6b35`
- Evidence: `artifacts/order_action_buttons_status_panel/mcp/fly_v429_2026-08-05/`

### Сессия 2026-08-05 (PHASE 3 REVIEW · #41)

- Регрессия FE зона #41: **95 runs / 0 fail PASS**
- CHANGELOG/HANDOFF/todo sync; затем push/deploy/MCP

### Сессия 2026-08-05 (GREEN шаг 7 · #41 mobile 44px)

- `ACTION_CTA_STYLE.heightPx = 44` + CSS min-height / media
- #41 FE зона → **51/51 PASS**

### Сессия 2026-08-05 (RED шаг 7 · #41 mobile touch)

- `order_action_buttons_mobile_test.mjs` — `heightPx >= 44` fail (got 36)
- CHANGELOG/HANDOFF не трогали

### Сессия 2026-08-05 (GREEN шаг 6 · #41 sticky cancel)

- `stickyOrderCancel.js` + OrderCancelModal в OrderStatusSheet + paid modal gate
- cancel/cable/action → **27/27 PASS**

### Сессия 2026-08-05 (RED шаг 6 · #41 sticky cancel)

- `order_action_buttons_cancel_test.mjs` — modal paid, applyStickyCancelSuccess, OrderStatusSheet wire
- `node --test …` → **FAIL** `ERR_MODULE_NOT_FOUND` `stickyOrderCancel.js` (намеренно)

### Сессия 2026-08-05 (GREEN шаг 5 · #41 Cable CTA)

- `applyCableEvent` мержит `can_cancel` из payload
- cable + sheet + order_action → **25/25 PASS**

### Сессия 2026-08-05 (RED шаг 5 · #41 Cable CTA)

- `order_action_buttons_cable_test.mjs`: swap kinds OK; **fail** `can_cancel` merge в `applyCableEvent`
- CHANGELOG/HANDOFF не трогали

### Сессия 2026-08-05 (GREEN шаг 4 · #41 OrderActionButtons)

- `orderActionButtons.js` (`#ff6b35`) + `OrderActionButtons.svelte` + accordion RIGHT wire
- Регрессия FE зона → **57/57 PASS**

### Сессия 2026-08-05 (RED шаг 4 · #41 OrderActionButtons)

- `test/javascript/order_action_buttons_test.mjs` — style `#ff6b35`, matrix paid+ios, svelte markup, accordion wire
- `node --test …` → **FAIL** `ERR_MODULE_NOT_FOUND` `orderActionButtons.js` (намеренно)

### Сессия 2026-08-05 (GREEN шаг 3 · #41 ButtonMapper)

- `orderStatusCtaMachine.js`: labels #41, `paid`→accepted, `hasPushSubscription` edge
- cta+adapters+cancel → **PASS**

### Сессия 2026-08-05 (RED шаг 3 · #41 ButtonMapper)

- `order_status_cta_machine_test.mjs`: labels #41, `paid` alias, `hasPushSubscription` edge
- `node --test …` → **10 fail / 6 pass** (намеренно); CHANGELOG/HANDOFF не трогали

### Сессия 2026-08-05 (GREEN шаг 2 · #41 TipsAdapter)

- `app/frontend/lib/tipsAdapter.js` — `openTipsService`
- tips+chat adapters → **6/6 PASS**

### Сессия 2026-08-05 (RED шаг 2 · #41 TipsAdapter)

- `test/javascript/tips_adapter_test.mjs` — URL / pending log / empty URL
- `node --test …` → **FAIL** `ERR_MODULE_NOT_FOUND` `tipsAdapter.js` (намеренно)
- CHANGELOG/HANDOFF не трогали

### Сессия 2026-08-05 (GREEN шаг 1 · #41 SupportChatAdapter)

- `app/frontend/lib/supportChatAdapter.js` — `openSupportChat`
- `node --test test/javascript/support_chat_adapter_test.mjs` → **3/3 PASS**

### Сессия 2026-08-05 (RED шаг 1 · #41 SupportChatAdapter)

- `test/javascript/support_chat_adapter_test.mjs` — open URL / pending log / empty URL
- `node --test …` → **FAIL** `ERR_MODULE_NOT_FOUND` `supportChatAdapter.js` (намеренно)
- CHANGELOG/HANDOFF не трогали

### Сессия 2026-08-05 (PHASE 1 SPEC · #41)

- `todo.md`: маппинг React/TS/Jest → Svelte + node:test; целевая поверхность = sticky `ActiveOrdersAccordion` RIGHT
- Канон: новый `OrderActionButtons.svelte`; mapper = расширить `orderStatusCtaMachine` (+ `hasPushSubscription`); адаптеры chat/tips
- Конфликт #40/#41 labels + edge push — зафиксирован в todo
- Код не писали; дальше RED шаг 1

### Сессия 2026-08-05 (PHASE 0 intake · #41 Action Buttons)

- ТЗ 1:1: `customer_tasks/Динамический блок действий Action Buttons в статусной панели заказа.md`
- Артефакты: `order_action_buttons_status_panel/` + макет `screenshots/01_mockup_…png`
- CBR #41 · customer_tasks README · код не трогали
- Дальше: PHASE 1 SPEC (маппинг React/TS/Jest → Svelte + node:test; шаги 1–7)

### Сессия 2026-08-05 (MCP accepted modal · #40)

- Order `#202608-0006` cash accepted · reconnect session
- CTA + hint 100% → modal (сумма 179 ₽) → confirm → cancelled + toast
- Evidence: `04_accepted_cancel_modal.png` · `05_accepted_modal_cancel_success.png`
- Live `/v2/Cancel` по-прежнему deferred (cash без PaymentId)

### Сессия 2026-08-04 (deploy + MCP · #40)

- Push `e2c10736` · Fly **v428** · image `deployment-01KZ6M11H6F1RJ4GPMND07P57R`
- HTTP `/up`+`/shop` 200 · SSH `cancel_payment`+`REFUND_UNAVAILABLE` true
- MCP: `#202608-0003` pending cancel → cancelled/failed + success toast
- MCP: `#202608-0005` ready → «Написать в поддержку», без cancel
- Live `/v2/Cancel` E2E deferred (нет accepted+PaymentId в сессии)
- Evidence: `artifacts/…/mcp/fly_v428_2026-08-04/`

### Сессия 2026-08-04 (PHASE 3 REVIEW · #40)

- Регрессия: adapter+guest cancel+API+callback+creator **81/223 PASS**
- §2.3: **2 runs / 5 assert / 2 skips** · JS **19/19 PASS**
- CHANGELOG/HANDOFF/todo sync; MCP/deploy ждут апрув

### Сессия 2026-08-04 (GREEN шаг 7 · #40 cancel toasts)

- `resolveCancelSuccess/ErrorResult`; OrderStatus toast + force preparing на 422/500
- JS cancel+cta **19/19 PASS**

### Сессия 2026-08-04 (RED шаг 7 · #40 cancel toasts)

- `order_cancel_flow_test.mjs` step 7 — нет CANCEL_* / resolveCancel* (намеренно)

### Сессия 2026-08-04 (GREEN шаг 6 · #40 cancel modal)

- `orderCancelFlow.js` + `OrderCancelModal.svelte`; OrderStatus без window.confirm
- JS cancel+cta **15/15 PASS**

### Сессия 2026-08-04 (RED шаг 6 · #40 cancel modal)

- `order_cancel_flow_test.mjs` — ERR_MODULE_NOT_FOUND `orderCancelFlow.js` (намеренно)

### Сессия 2026-08-04 (GREEN шаг 5 · #40 UI CTA)

- `orderStatusCtaMachine`: «Отменить заказ» + hint 100%; pending cancel; «Написать в поддержку»
- OrderStatus: render `btn.hint`; JS **10/10 PASS**

### Сессия 2026-08-04 (RED шаг 5 · #40 UI CTA)

- `order_status_cta_machine_test.mjs`: «Отменить заказ» + hint 100%; pending cancel; «Написать в поддержку» — 6 fail (намеренно)

### Сессия 2026-08-04 (шаг 4 · #40 block preparing/ready/issued)

- Контракт unit+API: 422, payment freeze, no Cancel — **PASS сразу** (guest_can_cancel? был)
- RED vacuous → закрыт как GREEN

### Сессия 2026-08-04 (GREEN шаг 3 · #40 accepted auto-refund)

- `GuestOrderCancellationService`: Cancel → refunded + Refund; reject failed/refunded; cash без PaymentId — local
- Тесты: guest cancel **9/39** · регрессия cancel+adapter **42/126 PASS**

### Сессия 2026-08-04 (RED шаг 3 · #40 accepted auto-refund)

- 4 теста `[TDD] accepted cancel*` — намеренный RED (нет Cancel/refund в GuestCancel)
- CHANGELOG/HANDOFF не трогали

### Сессия 2026-08-04 (шаг 2 · #40 pending_payment local)

- Контрактные тесты: no `cancel_payment`, payment→failed, order cancelled — **PASS сразу** (код был)
- RED vacuous → закрыт как GREEN без правки сервиса

### Сессия 2026-08-04 (GREEN шаг 1 · #40 cancel_payment)

- `Payments::TbankAdapter#cancel_payment` → `POST /v2/Cancel` без Receipt
- Тесты cancel: **3/14 PASS**; адаптер+callback: PASS
- CHANGELOG/HANDOFF — в REVIEW

### Сессия 2026-08-04 (RED шаг 1 · #40 cancel_payment)

- Тесты `[TDD] cancel_payment*` в `tbank_adapter_test.rb` — 3 runs, NoMethodError (ожидаемо)
- CHANGELOG/HANDOFF не трогали (RED-substep)

### Сессия 2026-08-04 (PHASE 1 SPEC · #40)

- `todo.md` — маппинг RSpec/React → Minitest/Svelte; есть GuestCancel API без `/v2/Cancel`
- Отклонения: pending journal→failed; CTA «Чат»→«Написать в поддержку»; adapter 260 строк
- Код не писали; дальше RED шаг 1

### Сессия 2026-08-04 (PHASE 0 intake · #40 T-Bank auto refund)

- ТЗ 1:1: `customer_tasks/Автоматический возврат платежа Т-Банк при отмене заказа в PWA.md`
- Артефакты: `artifacts/tbank_auto_refund_order_cancellation_pwa/`
- CBR #40 · customer_tasks README
- Код/todo не трогали; ждём go → SPEC

### Сессия 2026-08-04 (deploy/MCP · #39 v2)

- Push `7b4ff49f` · image `deployment-01KZ695P61B8GEC9CVZ0AA8GDD` · **v427**
- Smoke: `#202608-0005` offline → `sms:sent` (TG path нет); online → `SMS skipped`
- `/shop` 200 · меню OK · SMS_RU не на Fly → fallback log
- Evidence: `artifacts/order_ready_cascade_ws_push_sms/mcp/fly_v427_2026-08-04/`

### Сессия 2026-08-04 (GREEN+REVIEW · #39 v2)

- `OrderReadyPaidNotifier` — только SMS; лог `SMS.ru delivery failed`
- `OrderReadyCascadeJob` — presence → `SMS skipped`
- Тесты cascade/presence/sms/broadcaster/channel: **45/91 PASS**
- TelegramBotClient оставлен dormant (не в cascade)

### Сессия 2026-08-04 (PHASE 0+SPEC · #39 v2 без Telegram)

- ТЗ 1:1: `customer_tasks/Каскад уведомлений Заказ готов PWA WS Push WebPush Apple Wallet SMS.md`
- Артефакты: `artifacts/order_ready_cascade_ws_push_sms/`
- CBR #39 → v2; v1 marked SUPERSEDED
- `todo.md` — маппинг: presence → SMS only; FCM/Wallet reuse; без TG

### Сессия 2026-08-04 (deploy/MCP · #39)

- Push `2af25874` · image `deployment-01KZ5X2WSEYB4GKVBVPBMJ3SG0` · **v426**
- Secrets: `TELEGRAM_BOT_TOKEN`; SMS_RU не в .env — не ставили
- Release: ConcurrentMigrationError после DDL → `--skip-release-command` (DDL уже в Neon)
- Aram chat id на Fly; cascade smoke `#202608-0005` → `telegram:sent`
- Evidence: `artifacts/order_ready_cascade_ws_telegram_sms/mcp/fly_v426_2026-08-04/`

### Сессия 2026-08-04 (PHASE 3 REVIEW · #39)

- TG client + PaidNotifier + SMS send_message! ≤70 + logs
- Зона: **54/126 PASS**; barista без diff
- MCP/deploy ждут апрув

### Сессия 2026-08-04 (Migration Gate · #39)

- `mobile_customers.telegram_chat_id` + `order_notification_logs` (+ RLS)
- Models: `OrderNotificationLog`; validation на `MobileCustomer`
- `db:migrate` dev+test OK · RLS smoke **7/27 PASS**
- `.env.example`: TELEGRAM_BOT_TOKEN / SMS_RU_*

### Сессия 2026-08-03 (GREEN шаг 2 · #39 presence)

- `Shop::OrderReadyPresence` (Rails.cache `order:{id}:online`)
- Channel subscribe/unsubscribe mark/clear; Cascade skip paid если online; cache error re-raise
- Тесты: 27/52 PASS (presence + channel + cascade + broadcaster)

### Сессия 2026-08-03 (GREEN шаг 1 · #39 cascade enqueue)

- `Shop::OrderReadyCascadeJob` skeleton; Broadcaster enqueue на `ready`
- Тесты: 18/52 PASS · регрессия notifier+ready+broadcaster+cascade **26/87 PASS**
- Barista controller/service — без diff

### Сессия 2026-08-03 (MCP · #38 Fly v421)

- Aram OTP login Point A · 17 active orders
- Desktop: max-2 CTA `✓ Уведомления включены` + `Состав заказа`
- iPhone CriOS: `Карта в Apple Wallet` + `Состав заказа`
- Reconnect banner + progress stepper + SW `/firebase-messaging-sw.js` 200
- PNG: `artifacts/…/mcp/fly_v421_2026-08-03/`

### Сессия 2026-08-03 (PHASE 1 SPEC · #39 Order ready cascade)

- `todo.md` — маппинг ТЗ → Minitest/Solid Queue/GuestOrderBroadcaster; шаги 1–5 TDD
- Presence = Rails.cache; TG+SMS = новые клиенты; DDL = Migration Gate
- Код не писали; дальше RED шаг 1

### Сессия 2026-08-03 (PHASE 0 intake · #39 Order ready cascade)

- ТЗ 1:1: `customer_tasks/Оптимизированный каскад уведомлений Заказ готов PWA WS Push Telegram SMS.md`
- Артефакты: `artifacts/order_ready_cascade_ws_telegram_sms/`
- Индекс CBR #39 + `customer_tasks/README.md`
- Код не менялся; SPEC/todo — после go


### Сессия 2026-08-03 (push/deploy attempt · #38)

- Push `develop` → `a145ee0c` OK
- `fly deploy --depot=false`: image `deployment-01KZ3QRBRX8E2VES9XFJSBGDJ4` pushed
- Release + `machine update` → **403 billing** (https://fly.io/dashboard/razmik-kutinava/billing)
- MCP #38 SKIP; evidence `artifacts/…/mcp/fly_blocked_billing_2026-08-03/`

### Сессия 2026-08-03 (PHASE 3 REVIEW · #38)

- Sanity: Rails 33/127 PASS · JS 40/40 PASS · barista status без diff
- Warn: OrderStatus.svelte 754 / Accordion 322 (legacy); PKCS7 + chat/tips UI backlog
- MCP/deploy не запускали

### Сессия 2026-08-03 (GREEN шаг 5 · #38 PWA CTA machine)

- `orderStatusCtaMachine.js` + wire `OrderStatus.svelte` (max 2 CTAs, reconnect banner)
- JS: cta + notify + sw → 29/29 PASS
- Дальше: PHASE 3 REVIEW (CHANGELOG/HANDOFF/CBR)

### Сессия 2026-08-03 (RED шаг 5 · #38 PWA CTA machine)

- Тест: `order_status_cta_machine_test.mjs` — ERR_MODULE_NOT_FOUND (`orderStatusCtaMachine.js`)
- Контракт: accepted cancel+push/wallet; preparing/ready chat+tips/wallet; max 2; reconnect banner
- Дальше: GREEN — lib + wire OrderStatus.svelte

### Сессия 2026-08-03 (GREEN шаг 4 · #38 Broadcaster wallet update)

- Broadcaster: PassUpdater if `OrderWalletPass` exists; soft-fail Generation/Unavailable
- ReadyPushJob: skip PassUpdater when `status_label` already `ready`
- Тесты: 24 runs / 89 assertions PASS
- Дальше: RED шаг 5 PWA CTA machine

### Сессия 2026-08-03 (RED шаг 4 · #38 Broadcaster wallet update)

- Тесты: pass revision не обновляется; ReadyPushJob всё ещё bump revision если pass already ready
- Дальше: GREEN — Broadcaster `PassUpdater` if exists + soft-fail; ReadyPushJob skip if status_label already ready

### Сессия 2026-08-03 (GREEN шаг 3 · #38 pkpass enrich)

- `PassBuilder` simulate: face status/QR, back chat/tips, strip progress+fill_percent
- Тесты: pass_builder + wallet_pass + ready → 13/58 PASS
- Дальше: RED шаг 4 Broadcaster → PassUpdater если pass есть

### Сессия 2026-08-03 (RED шаг 3 · #38 pkpass enrich)

- Тесты: `pass_builder_test` — нет `face`/`back`/`strip` (3 fail); API 500 gen error уже PASS
- Дальше: GREEN — enrich PassBuilder (+ strip из progress matrix)

### Сессия 2026-08-03 (GREEN шаг 2 · #38 SW notificationclick)

- `swNotificationActions.js` + зеркало в `firebase_sw/show.js.erb` (notificationclick)
- `FcmClient` stringify Array/Hash → JSON для data
- JS 11/11 · Rails push 18/70 PASS
- Дальше: RED шаг 3 `.pkpass`

### Сессия 2026-08-03 (RED шаг 2 · #38 SW notificationclick)

- Тест: `test/javascript/sw_notification_actions_test.mjs` — ERR_MODULE_NOT_FOUND (`swNotificationActions.js`)
- Контракт: cancel POST + error toast; chat/tips deep link; tag/actions в showNotification
- Дальше: GREEN — lib + wire `firebase_sw/show.js.erb`

### Сессия 2026-08-03 (GREEN шаг 1 · #38 FCM payload)

- `Shop::OrderStatusPushPayload` — tag/actions/progress; soft-fail `PUSH_PAYLOAD_FORCE_ERROR`
- Wire: notifier + ReadyPushJob; body `🟩… текст`
- Тесты: 22 runs / 84 assertions PASS (payload+notifier+ready+broadcaster+pipeline)
- Barista status files — не трогали
- Дальше: RED шаг 2 SW actions

### Сессия 2026-08-03 (RED шаг 1 · #38 FCM payload)

- Тесты: `order_status_push_payload_test` (NameError) · notifier tag/actions/unicode · ready job · soft-fail `defined?`
- Намеренный RED `[TDD]` — не ISSUES
- Дальше: GREEN — `Shop::OrderStatusPushPayload` + wire notifier/ReadyPushJob

### Сессия 2026-08-03 (PHASE 1 SPEC · #38 Background FCM progress + Apple Wallet)

- `todo.md` переписан под #38: маппинг RSpec/Vitest → Minitest/JS; PassUpdater namespace; матрица CTAs; Chat/Tips deep-link gap
- Канон: enrich FCM в notifier + SW actions; Wallet APNs из Broadcaster если pass есть; UI machine на OrderStatus
- Код не писали; дальше RED шаг 1

### Сессия 2026-08-03 (PHASE 0 intake · #38 Background FCM progress + Apple Wallet)

- Док ТЗ 1:1: `customer_tasks/Фоновые уведомления прогресс-бар Android FCM и Apple Wallet iOS.md`
- Артефакты: `artifacts/background_notifications_fcm_apple_wallet/`
- CBR + `customer_tasks/README.md` — строка #38 / backlog

### Сессия 2026-08-03 (MCP · Charge unlocked package)

- ТП: Recurrent+Charge+ChargeQr на `1719235292309`
- one_click MIR *5953 → `#202608-0001` accepted `recurrent_charge=true`
- widget_init → `#202608-0005` CONFIRMED settled
- sbp/init `save_sbp_account:true` 179₽ → QR NSPK (не 3013); &lt;10₽ → 3016
- `has_sbp_account=false` — Zero-Click ChargeQr после оплаты в банке
- Артефакт: `artifacts/tbank_charge_unlocked_mcp_2026-08-03/`

### Сессия 2026-08-03 (push/deploy/MCP · #37 OS detect + Wallet/WebPush)

- Push `develop` → `35b7f00c`; `fly deploy --remote-only` → **v419** · image `deployment-01KZ3CAC9RNSCPZRZ5VZWEWW8K`
- `/up` 200
- MCP Point A (Aram, 14 active): Android UA → `🔔 Уведомление о готовности`; iPhone CriOS → `Карта в Apple Wallet`; «Состав заказа» → receipt PASS
- Evidence: `artifacts/order_status_os_detect_wallet_webpush/mcp/fly_v419_2026-08-03/`
- NOTE: чистый Safari UA → 406 (edge); CriOS iPhone OK для детекта

### Сессия 2026-08-03 (PHASE 3 REVIEW · #37)

- Шаги 1–6 GREEN: `deviceDetect`, accordion CTAs, receipt, `wallet_pass` API, FCM `subscribeOrderPush`, init restore
- Регрессия: JS 56/56 · Rails 11/11 (wallet/mount/push/active)
- Sanity: session visibility; no N+1; Accordion 309 warn; PKCS7 backlog
- MCP/deploy — закрыто в сессии выше

### Сессия 2026-08-03 (PHASE 1 SPEC · OS detect Wallet/WebPush)

- Канон: кнопки в `ActiveOrdersAccordion` stubs; `deviceDetect.js`; Wallet `GET /shop/api/orders/:id/wallet_pass` (новый); Push = FCM `registerShopPush` (не raw WebPush); чек = accordion expand
- `todo.md` переписан под #37; шаги 1–6 TDD; код не писали
- Дальше: RED шаг 1 при намерении («го / ебашь / сделай»)

### Сессия 2026-08-03 (PHASE 0 intake · OS detect Wallet/WebPush)

- Док ТЗ 1:1: `customer_tasks/Адаптивный виджет статуса заказа Детекция ОС и подписка на уведомления.md`
- Артефакты: `artifacts/order_status_os_detect_wallet_webpush/`
- CBR + `customer_tasks/README.md` — строка #37 / backlog

