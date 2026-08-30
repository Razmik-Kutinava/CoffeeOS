# HANDOFF — Веха 2

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-08-30 (shift close: ready refund + preparing carryover)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| SPEC shift close orders | `/sbr` RED |

**last_done:** /start исследование close wizard · refund · broadcast · Telegram  
**next_step:** `/sbr` — failing tests

**Архив session:** [`archive/README.md`](archive/README.md)  
**Архив journal:** [`../journal/archive/README.md`](../journal/archive/README.md)

---

## Текущий месяц (2026-08)

### Callbacks payments amount mismatch (2026-08-29)

| Что | Статус |
|-----|--------|
| optional amount vs payment/order | **local done** |
| Fly MCP | skip |

### Shop API order show customer_id (2026-08-28)

| Что | Статус |
|-----|--------|
| `show` scoped by `customer_id` + reconnect | **local done** |
| Fly MCP | skip |

### Fly v460 deploy + MCP #72/#73 (2026-08-28)

| Что | Статус |
|-----|--------|
| Deploy | **v460** · `deployment-01M13JTWPKPJBB3YCG2ZGMWP5P` |
| Webhook invalid Token | **PASS** 401 |
| #72 Receipt contact | **PARTIAL** (smoke+D PASS; live Init SKIP) |
| #73 Fiscal ЛК | **PARTIAL** (fiscal notify OFF / fr=0) |
| Артефакты | `…/mcp/fly_v460_2026-08-28/` |

### #72 + #73 closure prep (2026-08-28)

| Что | Статус |
|-----|--------|
| Intake заказчика 2026-08-28 | **`[x]`** #72 CONFIRMED · #73 Subtask 0/9а/`/callbacks/tbank` |
| CLOSURE_PREP + RECOVERY.md | **`[x]`** |
| /regress зона #72+#73 | **`[x]`** 31/0 |
| REVIEW | **`[x]`** bugbot · security · Entire · push |
| Deploy + Fly MCP live | **`[x]`** v460 PARTIAL | **`[x]`** PARTIAL (fiscal notify OFF) |

### Fly v459 deploy + MCP (2026-08-27)

| Что | Статус |
|-----|--------|
| Deploy | **v459** |
| Webhook plain OK | **PASS** |
| #72 Receipt contact | **PARTIAL** (live Init SKIP) |
| #73 Fiscal ЛК | **PARTIAL** (fiscal notify OFF / fr=0) |
| #74 card_hash | **PARTIAL** (schema+dry_run; E2E SKIP) |

### T-Bank webhook plain `OK` (2026-08-27)

| Что | Статус |
|-----|--------|
| SPEC (`todo.md`) | **`[x]`** |
| RED / GREEN | **`[x]`** `747b8e76` / `0ee54a9` · Entire `01M11PSG…` |
| /regress | **`[x]`** PASS 46/0 |
| REVIEW | **`[x]`** bugbot clean · security no medium+ · Entire · push |

**Канон:** офиц. Notification → HTTP 200 + тело `OK`  
**Файлы:** `tbank_controller.rb` · `tbank_controller_test.rb` · `docs/integrations/tbank.md`

### #74 Card binding unique hash (2026-08-27)

| Что | Статус |
|-----|--------|
| Intake + CBR #74 | **`[x]`** `6e88b962` |
| SPEC (`todo.md`) | **`[x]`** `bdda8687` |
| RED / GREEN | **`[x]`** `951a349b` / `37ae717c` · Entire `01M11NEP…` |
| /regress | **`[x]`** PASS 5+46+8 |
| REVIEW | **`[ ]`** |

**ТЗ:** [`customer_tasks/Устранение утечки данных чужой карты при привязке.md`](../milestones/veha_2/requirements/customer_tasks/Устранение%20утечки%20данных%20чужой%20карты%20при%20привязке.md)  
**Артефакты:** [`artifacts/card_binding_unique_hash/`](../milestones/veha_2/artifacts/card_binding_unique_hash/)  
**Серия:** security review · задача 1

### #73 Fiscal receipts в ЛК (2026-08-27)

| Что | Статус |
|-----|--------|
| Intake + CBR #73 | **`[x]`** `fb5334d8` |
| SPEC (`todo.md`) | **`[x]`** (этот шаг) |
| RED / GREEN | **`[x]`** `579f9468` / `8e923305` · Entire `01M11269…` |
| /regress | **`[x]`** PASS 46+3+6 |
| REVIEW | **`[x]`** bugbot fix fiscal_expected · security no medium+ · Entire · push |
| Блокер схемы | **закрыт** — SCHEMA.md (Status=RECEIPT) |

**ТЗ:** [`customer_tasks/Хранение и отображение фискальных чеков в личном кабинете.md`](../milestones/veha_2/requirements/customer_tasks/Хранение%20и%20отображение%20фискальных%20чеков%20в%20личном%20кабинете.md)  
**Артефакты:** [`artifacts/fiscal_receipts_personal_cabinet/`](../milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/)  
**Серия:** после #72; не путать с исходящим Receipt.Email

### #72 Receipt.Email / Phone фискальные чеки (2026-08-27)

| Что | Статус |
|-----|--------|
| Intake + CBR #72 | **`[x]`** `750b488c` |
| SPEC (`todo.md`) | **`[x]`** `d99894dc` |
| RED / GREEN | **`[x]`** `d138c116` / `5f68efea` · Entire `01M11269…` |
| /regress | **`[x]`** PASS 48+24+12 |
| REVIEW | **`[x]`** bugbot+security · Entire · push/CI |

**ТЗ:** [`customer_tasks/Доработка бэкенда — передача email покупателя в Receipt для фискальных чеков.md`](../milestones/veha_2/requirements/customer_tasks/Доработка%20бэкенда%20—%20передача%20email%20покупателя%20в%20Receipt%20для%20фискальных%20чеков.md)  
**Артефакты:** [`artifacts/receipt_email_fiscal_checks/`](../milestones/veha_2/artifacts/receipt_email_fiscal_checks/)  
**Серия:** security review (задача 1); остальные — отдельно после #72

### Fly v458 + MCP пачка #69/#70/#71 (2026-08-26)

| CBR | Fly MCP | Артефакт |
|-----|---------|----------|
| #70 Telegram support ЛК | **PASS** | `artifacts/telegram_bot_support_lk/mcp/fly_v458_2026-08-26/` |
| #69 PWA ЛК | **PASS** | `artifacts/pwa_personal_account_lk/mcp/fly_v458_2026-08-26/` |
| #71 Email after pay | **PASS** (без live pay) | `artifacts/email_collection_after_payment/mcp/fly_v458_2026-08-26/` |

### #71 Email-сбор после оплаты / Callcheck (2026-08-26)

| Что | Статус |
|-----|--------|
| Intake + CBR #71 | **`[x]`** `0aed04f8` |
| SPEC (`todo.md`) | **`[x]`** |
| RED / GREEN | **`[x]`** `0eeaea77` / `31cf0e21` |
| `/regress` | **`[x]`** JS 31/0 · Rails 16/0 |
| REVIEW | **`[x]`** bugbot+security fixed `94f36822` · Entire attach CLI fail · push/CI |

**ТЗ:** [`customer_tasks/Email-сбор после оплаты (Callcheck-флоу).md`](../milestones/veha_2/requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md)  
**Артефакты:** [`artifacts/email_collection_after_payment/`](../milestones/veha_2/artifacts/email_collection_after_payment/)

### Rules/meta: уменьшение токенов always-подсказок (2026-08-18)

- Оценка: ≈6648 -> ≈4594 токенов на always applied rules (~-31%); ключевые триггеры/формат отчёта сохранены.

### #68 Telegram WebView UX / Performance (2026-08-15)

| Что | Статус |
|-----|--------|
| Intake + CBR #68 | **`[x]`** |
| SPEC (`todo.md`) | **`[x]`** |
| RED / GREEN | **`[x]`** `ff9374d1` |
| `/regress` | **`[x]`** JS 46/0 · Rails 8/0 |
| REVIEW | **`[x]`** PHASE 3 · CI [run 31878722151](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31878722151) |
| Entire backfill | **`[x]`** attach сессий на docs-коммит (GREEN SHA без trailer) |
| Fly deploy | **`[x]`** v456 · `/up` 200 · Point A shop 200 |
| Fly MCP Point A | **Chrome PASS** v456 · TG skip |
| Telegram устройство | `[ ]` |

**ТЗ:** [`customer_tasks/UX и Performance мобильной витрины CoffeeOS внутри Telegram WebView.md`](../milestones/veha_2/requirements/customer_tasks/UX%20и%20Performance%20мобильной%20витрины%20CoffeeOS%20внутри%20Telegram%20WebView.md)  
**Артефакты:** [`artifacts/mobile_storefront_telegram_webview_ux_perf/`](../milestones/veha_2/artifacts/mobile_storefront_telegram_webview_ux_perf/)  
Серия задача 5. Runtime #66 и UI #67 не переписывать. #67 deploy — не этот шаг.

### #67 Telegram WebView mobile UI (2026-08-15)

| Что | Статус |
|-----|--------|
| Intake + CBR #67 | **`[x]`** |
| SPEC (`todo.md`) | **`[x]`** |
| RED / GREEN | **`[x]`** `8daadddf` |
| REVIEW | **`[x]`** PHASE 3 · CI [run 31877829022](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31877829022) |
| Fly MCP Point A | **PARTIAL** v456 (S7 keyboard SKIP) · TG skip |
| Telegram устройство | `[ ]` |

**ТЗ:** [`customer_tasks/Адаптация Mobile UI витрины CoffeeOS под Telegram WebView.md`](../milestones/veha_2/requirements/customer_tasks/Адаптация%20Mobile%20UI%20витрины%20CoffeeOS%20под%20Telegram%20WebView.md)  
**Артефакты:** [`artifacts/mobile_storefront_telegram_webview_ui/`](../milestones/veha_2/artifacts/mobile_storefront_telegram_webview_ui/)  
Серия задача 4. Runtime #66 не переписывать. Задача 5 (perf) — вне scope.

### #66 Telegram WebView storefront runtime (2026-08-15)

| Что | Статус |
|-----|--------|
| Intake + CBR #66 | **`[x]`** |
| SPEC (`todo.md`) | **`[x]`** |
| RED / GREEN | **`[x]`** local `ca9c5834` |
| REVIEW | **`[x]`** PHASE 3 · CI [run 31876503882](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31876503882) |
| Fly MCP Point A | **Chrome PASS** v456 · TG skip |
| Telegram устройство | `[ ]` |

**ТЗ:** [`customer_tasks/Полноценная работа мобильной витрины…`](../milestones/veha_2/requirements/customer_tasks/Полноценная%20работа%20мобильной%20витрины%20CoffeeOS%20внутри%20Telegram%20In-App%20Browser.md)  
**Артефакты:** [`artifacts/mobile_storefront_telegram_webview/`](../milestones/veha_2/artifacts/mobile_storefront_telegram_webview/)  
Серия задача 3. Bot / UI#4 / perf#5 — вне scope.

### #65 Telegram/Instagram In-App → /shop linkage (2026-08-14)

| Что | Статус |
|-----|--------|
| Intake + CBR #65 | **`[x]`** |
| SPEC (`todo.md`) | **`[x]`** |
| RED / GREEN | **`[x]`** local |
| REVIEW | **`[x]`** manual |
| CI | **green** `c9b8f04d` · [run 31815909292](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/31815909292) |
| Fly MCP Point A | **Chrome PASS** v456 · TG/IG skip |
| TG/IG устройства | `[ ]` |

**ТЗ:** [`customer_tasks/Изменения в связке Telegram Instagram…`](../milestones/veha_2/requirements/customer_tasks/Изменения%20в%20связке%20Telegram%20Instagram%20In-App%20Browser%20к%20CoffeeOS%20shop.md)  
**Артефакты:** [`artifacts/telegram_instagram_inapp_shop_linkage/`](../milestones/veha_2/artifacts/telegram_instagram_inapp_shop_linkage/)  
**Фикс:** явный `tenant_id` key → без silent fallback; query > meta; docs § integrity

### #64 Shop Telegram/Instagram in-app open (2026-08-14)

| Что | Статус |
|-----|--------|
| Intake + CBR #64 | **`[x]`** |
| SPEC (`todo.md`) | **`[x]`** |
| Диагностика точки отказа | **`[x]`** Chrome Point A · TG/IG устройства `[ ]` |
| RED / GREEN | **`[x]`** local |
| Fly MCP Point A | **Chrome PASS** v456 · не закрывать `[x]` без TG |
| TG/IG реальные устройства | `[ ]` |
| Апрув заказчика | `[ ]` |

**ТЗ:** [`customer_tasks/Исправление открытия shop…`](../milestones/veha_2/requirements/customer_tasks/Исправление%20открытия%20shop%20во%20встроенных%20браузерах%20Telegram%20и%20Instagram.md)

### #63 Svelte 5 status widget reactivity UX (2026-08-13)

| Что | Статус |
|-----|--------|
| Intake + CBR #63 (доп к #35) | **`[x]`** |
| Immutable Cable/sync + dismiss + route hide | **`[x]`** |
| Local JS | **`[x]`** 22/0 |
| CI #32 | **`[x]`** green (`79d90704`) |
| Fly deploy | **`[x]`** v454 |
| Fly MCP Point A | **`[x]` PASS** v454 + **v455** |
| Апрув заказчика | `[ ]` |

**Evidence:** [`mcp/fly_v455_2026-08-14/`](../milestones/veha_2/artifacts/svelte5_status_widget_reactivity_ux/mcp/fly_v455_2026-08-14/) · v454: [`mcp/fly_v454_2026-08-13/`](../milestones/veha_2/artifacts/svelte5_status_widget_reactivity_ux/mcp/fly_v454_2026-08-13/)

### #62 SBP autopay checkbox default (2026-08-13)

| Что | Статус |
|-----|--------|
| ТЗ 1:1 + CBR #62 | **`[x]`** |
| Default checked + preserve + `save_sbp_account` | **`[x]`** |
| Local JS 39/0 | **`[x]`** |
| Fly MCP Point A | **`[x]` PASS** v450 checkbox ON + preserve |

### Payment error user messages (2026-08-13)

| Что | Статус |
|-----|--------|
| ТЗ 1:1 + CBR | **`[x]`** |
| Card / network labels + Retry CTA | **`[x]`** |
| Local tests | **`[x]`** |
| Fly MCP Point A | **`[x]`** CTA NET PASS · raw `Failed to fetch` FAIL → ISSUES |

### Invalid token + One-Click sheet UX (2026-08-13)

| Что | Статус |
|-----|--------|
| Скрины 09/10 в artifacts | **`[x]`** |
| `openRepeatPaymentSheet` + RepeatSection wiring | **`[x]`** |
| Local tests | **`[x]`** |
| Fly MCP Point A | **`[x]` PASS** sheet vs 09 + NewCard in sheet |

### SMS.ru Callcheck auth (2026-08-12)

| Что | Статус |
|-----|--------|
| `/code/call` убран из auth flow | **`[x]`** |
| init_callcheck / check_status / send_sms / verify_sms | **`[x]`** |
| PWA Callcheck→SMS | **`[x]`** |
| Local tests | **`[x]`** |
| Fly MCP Point A | **`[x]` PASS** Callcheck UI + `/code/call` 404 |

### Phone OTP Flash / SMS split (2026-08-12)

| Что | Статус |
|-----|--------|
| Ошибочный канон (равноправные каналы) | **superseded** → Callcheck BUG-REPORT |

### SBP enable PaymentMethodsSheet (2026-08-12)

| Что | Статус |
|-----|--------|
| Unlock СБП / счёт СБП → onSelectSbp | **`[x]`** local |
| Тесты UI/CBR | **`[x]`** 29/0 |
| Fly MCP Point A | **`[x]` PASS** v450 СБП кликабелен |
| Банк 3001 кабинет | отдельно (ISSUES) |

### Bugbot / security callbacks (2026-08-11)

| Что | Статус |
|-----|--------|
| Tbank claim release / Mutex / body 413 / Rails.cache | **`[x]`** |
| SMS.ru body dual-check + Rails.cache dedup | **`[x]`** GREEN `10774cfe` · review#2 OK |
| CI develop + Postgres | **`[x]`** |
| CI full suite vs legacy shop fails | backlog (не blocker callback) |
| Bugbot review#2 | **0 findings** |

### C. Legacy shop triage (2026-08-09)

| Что | Статус |
|-----|--------|
| Regression `:receipt` kwarg | **`[x]`** `1582f078`, зона 42/0 |
| Messenger OTP канал | **`[x]`** осознанно снесён (git log) — тесты → flash_call/sms, 17/17 green |
| Остальные 4-5 failures | отдельная итерация |

### Hot-path agent discipline (2026-08-09)

| Что | Статус |
|-----|--------|
| Не ломать + Проверка обязательны | **`[x]`** |
| DoD Local + Fly Point A | **`[x]`** |
| Anti-gem / MCP-safety / DEMO_LOGINS | **`[x]`** |
| Продукт: UserCards / витрина | очередь в `todo.md` |

### #47 PWA status sync + repeats (2026-08-08)

| Что | Статус |
|-----|--------|
| Intake + SPEC + RED + GREEN + REVIEW | **`[x]`** |
| Push + Fly **v443** | **`[x]`** |
| MCP Fly | **`[x]` PASS** |
| Апрув заказчика | `[ ]` |

**Evidence:** [`mcp/fly_v443_2026-08-08/`](../milestones/veha_2/artifacts/pwa_status_sync_and_repeats_stale/mcp/fly_v443_2026-08-08/)  
**ТЗ:** `customer_tasks/Статусы с табло не подтягиваются в PWA и повторы после заказа.md`

### Pinpoint code context (2026-08-08)

| Что | Статус |
|-----|--------|
| SPEC: «Файлы (ожидаемо)» 2–7 в todo | **`[x]`** |
| BUILD: только список + точечный добор; без `@codebase` зря | **`[x]`** |
| Без Graphify / codebase-map | **`[x]`** |

### Архив CHANGELOG (2026-08-08)

| Что | Статус |
|-----|--------|
| CHANGELOG live ~257k→~23k B; `journal/archive/` 06–07 | **`[x]`** |
| ISSUES без архива; старт = только 🔴 | **`[x]`** |

### Архив ops по месяцам (2026-08-08)

| Что | Статус |
|-----|--------|
| Живые файлы: шапка + только 2026-08 | **`[x]`** |
| Архив `session/archive/` (handoff 06–07, session_state 05–07) | **`[x]`** |
| Always/task-workflow: старт = шапка + 🔴 + todo; CHECKLIST/CBR только для вехи | **`[x]`** |

**Замер live:** HANDOFF ~76k→~19k B · SESSION_STATE ~284k→~35k B

**Дата:** 2026-08-07 (thin always-rules)  
**Ветка:** `develop`

### Thin always-rules (2026-08-07)

| Что | Статус |
|-----|--------|
| Always tok/ход ~12.7k → ~2.9k (−77%) | **`[x]`** |
| Дубли symlink core/performance сняты | **`[x]`** |
| Длинные workflow → on-demand / globs | **`[x]`** |

**Дальше:** смоук на мелочи + фиче (агент читает on-demand); опционально ужать историю HANDOFF/SESSION_STATE.

### MCP Fly v441 (2026-08-07)

**Дата:** 2026-08-07 (MCP Fly **v441** · #46+#33)  
**Прод:** https://coffeeos.fly.dev (**v441**)

| Что | Статус |
|-----|--------|
| Deploy health (machines 441, `/up` 200) | **PASS** |
| #46 Checkout chunk 119/2200 + live *5953 → NewCardForm | **PASS** |
| #46 live *8782 → order accepted / «Оплачен» | **PASS** `db45ab5f-…` |
| #33 El/Dl helpers в bundle | **PASS** (live S1/S2 = v440) |

**Evidence:** [`bank_auth_limit…/mcp/fly_v441_2026-08-07/`](../milestones/veha_2/artifacts/bank_auth_limit_blocks_payment/mcp/fly_v441_2026-08-07/) · [`tbank_widget…/mcp/fly_v441_2026-08-07/`](../milestones/veha_2/artifacts/tbank_widget_oneclick_fallback/mcp/fly_v441_2026-08-07/)  
**Дальше:** апрув заказчика «ок».

### #33+#46 push/deploy/MCP (2026-08-07)

| Что | Статус |
|-----|--------|
| Push `11e5eaf7` | **`[x]`** |
| Fly **v440** | **`[x]`** `deployment-01KZDYQPQCHWPFBPEX3XJF8JKA` |
| Fly **v441** (re-deploy владельца) | **`[x]`** `deployment-01KZDZ59Z9113BYEWRVEHF3QBT` |
| MCP S1/S2 (#33) | **PASS** v440 · helpers v441 |
| MCP #46 119 + *8782 pay | **PASS** v441 |

**Evidence:** [`mcp/fly_2026-08-07/`](../milestones/veha_2/artifacts/tbank_widget_oneclick_fallback/mcp/fly_2026-08-07/) · [`mcp/fly_v441…`](../milestones/veha_2/artifacts/bank_auth_limit_blocks_payment/mcp/fly_v441_2026-08-07/)  
**Дальше:** апрув заказчика «ок».

### #33 fallback vs expanded (2026-08-07)

| Что | Статус |
|-----|--------|
| SPEC канон S0→S1→S2 · скрины 07/08 | **`[x]`** |
| GREEN: decline → только СБП/карта+; expanded после «карта +» | **`[x]`** |
| Push / Fly / MCP | **`[x]`** v440/v441 |

### #46 bank auth limit blocks payment (2026-08-07)

| Что | Статус |
|-----|--------|
| GREEN: clear pid + CLIENT_ERROR 119/2200 | **`[x]`** `327e8767` |
| Push / Fly | **`[x]`** v440/v441 |
| MCP checkout 119 → NewCardForm; *8782 → статусы | **`[x]`** v441 |
| СБП enable | **out** (3001 + #26) |

### #26 push/deploy/MCP (2026-08-07)

| Что | Статус |
|-----|--------|
| Push `bd0e9fb0` | **`[x]`** |
| Fly **v439** | **`[x]`** `deployment-01KZDEN9MV9QW2DKFWQXRNFYVT` |
| MCP G1–G4 (labels / orange Pay / + / SBP disabled) | **PASS** |
| MCP G7 live insufficient | **PARTIAL** (банк rate-limit BANK_ERROR; unit+bundle PASS) |

**Evidence:** [`mcp/fly_v439_2026-08-07/`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/mcp/fly_v439_2026-08-07/)  
**Дальше:** апрув заказчика «ок»; optional live re-check insufficient когда банк не rate-limit.

### PHASE 3 REVIEW: #26 G7 + G1–G4 (2026-08-07)

| Что | Статус |
|-----|--------|
| G7 + G1–G4 local GREEN | **`[x]`** |
| REVIEW sanity | **`[x]`** |
| Push / MCP | **`[x]`** v439 |

| Что | Статус |
|-----|--------|
| REVIEW (нет P0; fix empty meta) | **`[x]`** |
| Push `4ca777a4` | **`[x]`** |
| Fly **v438** | **`[x]`** `deployment-01KZBM95ZEVSW9G5GN87EW4RW6` |
| MCP D4 vs скрин 06 (pay-stack meta=позиция) | **PASS** |

**Evidence:** [`mcp/fly_v438_2026-08-06/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/mcp/fly_v438_2026-08-06/)  
**Дальше:** апрув заказчика «ок»; D5 barista→ready optional.

### PHASE 2 GREEN: #35 D1+D2 expanded stack + meta (2026-08-06)

| Что | Статус |
|-----|--------|
| `data-cart-status-stack="status-above-lines"` | **`[x]`** |
| `statusMetaThird` / UI `metaThird` | **`[x]`** |
| Тесты D1+D2 + zone | **`[x]`** 18/0 · JS 32/0 |
| Push / MCP vs скрин 06 | **`[ ]`** ждёт апрув |

**Дальше:** push → Fly → MCP D4 (expanded: статус над корзиной, meta=позиция).

### PHASE 1 SPEC: #35 + скрин 06 (2026-08-06)

| Что | Статус |
|-----|--------|
| SPEC / `todo.md` (baseline A–C + gaps D1–D5) | **`[x]`** |
| RED D1+D2 (порядок expanded + meta product) | **`[ ]`** |
| GREEN / MCP vs скрин 06 | **`[ ]`** |

**Канон:** [`todo.md`](todo.md) · скрин [`06_expanded…`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/screenshots/06_expanded_sheet_status_plus_cart.png)  
**Дальше:** намерение → RED D1+D2.

### PHASE 0: #35 доп. скрин expanded (2026-08-06)

| Что | Статус |
|-----|--------|
| Сверка текста ТЗ с существующим доком | **совпал** — тело не трогали |
| Скрин `06_expanded_sheet_status_plus_cart.png` | **`[x]`** в artifacts |
| Карта подписей + README + CBR | **`[x]`** |
| SPEC / код | **`[ ]`** ждать `go` |

**ТЗ:** [`Интеграция статусной модели…`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md)  
**Скрин:** [`screenshots/06_…`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/screenshots/06_expanded_sheet_status_plus_cart.png) — **канон** expanded: статус над корзиной + оплата.  
**Дальше:** `go` → SPEC (сверка live/prog38 со скрином 06) или апрув «ок» по #35.

### Fix: status + cart peek stack (2026-08-06)

| Что | Статус |
|-----|--------|
| Убран `hideCartTail` mutex | **`[x]`** |
| `STATUS_IN_SHEET_EXTRA_VH` + `prog38` | **`[x]`** |
| Тесты cart sheet zone | **`[x]`** 57/0 |
| Push / Fly / MCP | **`[ ]`** ждёт апрув |

**Суть:** при активном заказе снова видны позиции корзины (стык под статусом); empty placeholder не рисуется под статусом без позиций.  
**Дальше:** push → deploy → MCP (каталог с active order → add → peek «уже в заказе»).

### Правило: CartSheet без многослойности (2026-08-06)

| Что | Статус |
|-----|--------|
| Правило `coffeeos-cart-sheet.mdc` | **`[x]`** |
| Индекс / symlink / ui cross-ref | **`[x]`** |
| Аудит кода на слои внутри шторки | **`[ ]`** ждёт апрув |

**Суть:** внутри шторки — секции стык в стык; запрещены второй fixed / overlay / z-index поверх соседних блоков.  
**Дальше:** апрув → пройтись по `app/frontend` и найти нарушения.

### Product card peek cart (#44) — GREEN + MCP 2026-08-06

| Что | Статус |
|-----|--------|
| PHASE 0 intake | **`[x]`** |
| SPEC / RED / GREEN | **`[x]`** `7f7973e1` |
| Push / Fly / MCP | **`[x]`** **v436** PASS |

**ТЗ:** [`Карточка товара отображение набранных позиций…`](../milestones/veha_2/requirements/customer_tasks/Карточка%20товара%20отображение%20набранных%20позиций%20и%20функциональность%20в%20режиме%20peek.md)  
**Evidence:** [`mcp/fly_v436_2026-08-06/`](../milestones/veha_2/artifacts/product_card_peek_cart/mcp/fly_v436_2026-08-06/)  
**Суть:** одна CartSheet на `#/product` — CTA + peek/hidden/expanded стыками; без fixed overlay.  
**Live:** `prog37` · `уже в заказе: 2` · ± → 3 · CTA внутри шторки.  
**Дальше:** апрув заказчика «ок».

### Follow-up: убрать “хвост” корзины под статусом — **откатан mutex**
- Было: `hideCartTail` прятал весь peek при active order (`19231620`) → add «пропадал»
- Теперь: статус + корзина стык; пустой placeholder скрыт только без позиций

### Repeat hidden by stale active orders (#43) — 2026-08-06

| Что | Статус |
|-----|--------|
| Intake | **`[x]`** |
| TTL на `has_active_order?` | **`[x]`** |
| Push / Fly / MCP | **`[x]`** **v434** PASS |

**ТЗ:** [`После 42 пропали повторы…`](../milestones/veha_2/requirements/customer_tasks/После%2042%20пропали%20повторы%20в%20шторке%20и%20история%20покупок.md)  
**Evidence:** [`mcp/fly_v434_2026-08-06/`](../milestones/veha_2/artifacts/repeat_hidden_by_stale_active_orders/mcp/fly_v434_2026-08-06/)  
**Суть:** June accepted → `has_active_order` навечно → нет «повторить».  
**Фикс live:** TTL 24h; Aram 3 frequent + 3× «оплатить в 1 клик».  
**Дальше:** апрув «ок»; Араму hard refresh.

### Stuck orders sheet blocks payment (#42) — 2026-08-05

| Что | Статус |
|-----|--------|
| Intake | **`[x]`** |
| TTL 24h + peek height | **`[x]`** |
| Push / Fly / MCP | **`[x]`** **v433** PASS |

**ТЗ:** [`Зависшие заказы…`](../milestones/veha_2/requirements/customer_tasks/Зависшие%20заказы%20в%20статусной%20шторке%20PWA%20блокируют%20оплату.md)  
**Evidence:** [`mcp/fly_v433_2026-08-05/`](../milestones/veha_2/artifacts/stuck_orders_status_sheet_blocks_payment/mcp/fly_v433_2026-08-05/)  
**Суть:** June `#202606-*` вечно в шторке → пол экрана; на табло нет (фильтр смены).  
**Фикс live:** `orders/active` TTL 24h → Aram `[]`; peek `min(22vh,8.5rem)`; pay CTA видна.  
**Дальше:** апрув заказчика «ок»; backlog SM NULL-shift / payment sync.

### Order status compact sheet + Push #35 — ревизия ТЗ (2026-08-05)

| Что | Статус |
|-----|--------|
| PHASE 0 intake (ТЗ 1:1 + скрины) | **`[x]`** |
| PHASE 1 SPEC (`todo.md`) | **`[x]`** |
| RED/GREEN A/B/C | **`[x]`** tip `38df5088` |
| Push develop | **`[x]`** `8ffabc86..38df5088` |
| Fly deploy | **`[x]`** **v432** · `deployment-01KZ8W88G4HC0YK291M3FM011G` |
| MCP home/product/scroll | **PASS** |
| MCP barista → ready → hide + push | **PARTIAL** (не гоняли) |

**ТЗ:** [`Интеграция статусной модели…`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md)  
**Скрины:** [`order_status_compact_sheet_push/screenshots/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/screenshots/) (обновлены 2026-08-05)  
**Evidence:** [`mcp/fly_v432_2026-08-05/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/mcp/fly_v432_2026-08-05/)  
**Дельта live:** hide `ready` · sheet на `#/product` · scroll >2 · ReadyPushJob copy/claim.  
**Дальше:** апрув заказчика; optional MCP smoke barista→ready.

### Order action buttons status panel (#41) — 2026-08-05

| Что | Статус |
|-----|--------|
| Intake / SPEC / RED-GREEN 1–7 / REVIEW | **`[x]`** |
| Push develop | **`[x]`** |
| Fly deploy | **`[x]`** **v431** · `deployment-01KZ8J3QC9JAKDRAZZMG16K6KP` |
| MCP chat+push | **PASS** v429 |
| MCP cancel CTA + modal | **PASS** v431 · `#202608-0005` |
| CBR апрув «ок» | **`[x]`** 2026-08-05 |

**Evidence:** [`mcp/fly_v429_2026-08-05/`](../milestones/veha_2/artifacts/order_action_buttons_status_panel/mcp/fly_v429_2026-08-05/) · [`mcp/fly_v431_2026-08-05/`](../milestones/veha_2/artifacts/order_action_buttons_status_panel/mcp/fly_v431_2026-08-05/)  
**Дальше:** — (#41 закрыта)

### T-Bank auto refund on PWA cancel (#40) — 2026-08-04

| Что | Статус |
|-----|--------|
| Intake / SPEC / RED-GREEN 1–7 / REVIEW | **`[x]`** tip REVIEW `e2c10736` |
| Push develop | **`[x]`** `e2c10736` |
| Fly deploy | **`[x]`** **v428** · `deployment-01KZ6M11H6F1RJ4GPMND07P57R` |
| MCP | **PASS** · pending `#202608-0003` · ready `#202608-0005` · **accepted modal `#202608-0006`** · live `/v2/Cancel` E2E deferred |

**ТЗ:** [`Автоматический возврат платежа Т-Банк при отмене заказа в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Автоматический%20возврат%20платежа%20Т-Банк%20при%20отмене%20заказа%20в%20PWA.md)  
**Evidence:** [`mcp/fly_v428_2026-08-04/`](../milestones/veha_2/artifacts/tbank_auto_refund_order_cancellation_pwa/mcp/fly_v428_2026-08-04/)  
**Канон:** `/v2/Cancel` без Receipt; accepted+succeeded → refunded; preparing+ → 422; FE modal/toasts.  
**Дальше:** апрув заказчика «ок»; опционально live Cancel на card `accepted`+PaymentId.

### Order ready cascade WS/Push/Wallet→SMS (#39 v2) — 2026-08-04

| Что | Статус |
|-----|--------|
| Intake / SPEC / GREEN rewrite / REVIEW | **`[x]`** |
| Push develop | **`[x]`** `7b4ff49f` |
| Fly deploy | **`[x]`** **v427** (superseded by v428 for #40) |
| MCP cascade SMS | **PASS** · `#202608-0005` → `sms:sent` · TG=0 · presence skip OK |
| SMS_RU secrets on Fly | **`[ ]`** (fallback log-only) |

**ТЗ:** [`Каскад уведомлений… SMS.md`](../milestones/veha_2/requirements/customer_tasks/Каскад%20уведомлений%20Заказ%20готов%20PWA%20WS%20Push%20WebPush%20Apple%20Wallet%20SMS.md)  
**Evidence:** [`mcp/fly_v427_2026-08-04/`](../milestones/veha_2/artifacts/order_ready_cascade_ws_push_sms/mcp/fly_v427_2026-08-04/)  
**Дальше:** апрув заказчика «ок»; опционально `SMS_RU_API_ID`/`SMS_RU_FROM` для реального SMS.

### Order ready cascade WS→TG→SMS (#39 v1) — SUPERSEDED

Fly v426 · TG MCP PASS · superseded by v2. Evidence: [`…telegram_sms/mcp/fly_v426_2026-08-04/`](../milestones/veha_2/artifacts/order_ready_cascade_ws_telegram_sms/mcp/fly_v426_2026-08-04/)

### Background FCM progress + Apple Wallet (#38) — 2026-08-03

| Что | Статус |
|-----|--------|
| Intake / SPEC / RED-GREEN 1–5 / REVIEW | **`[x]`** tip `f3f0f2db` · REVIEW `a145ee0c` |
| Fly deploy | **`[x]`** **v421** · `deployment-01KZ3T8HZMBBGBMH2GD7Z20J37` |
| MCP #38 Aram Point A | **PASS** |

**Evidence:** [`mcp/fly_v421_2026-08-03/`](../milestones/veha_2/artifacts/background_notifications_fcm_apple_wallet/mcp/fly_v421_2026-08-03/)  
**Скрины:** `02_*` max-2 CTA subscribed · `03_*` iOS Wallet CTA  
**Дальше:** апрув заказчика «ок» → `[x]` в CBR; или #39 RED шаг 1.

### T-Bank Charge unlocked — пакет MCP (2026-08-03)

ТП: рекуррент + Charge + ChargeQr на терминале `1719235292309`.

| Задача | MCP |
|--------|-----|
| **#32** inline / widget Charge SUCCESS | **PASS** · order `#202608-0005` CONFIRMED |
| **#33** One-Click card Charge | **PASS** · `#202608-0001` `recurrent_charge=true` |
| **#27** SBP Deep Link + card tokenization | **PASS** · QR NSPK + card Charge |
| **#34** SBP Autopay bind Init | **PASS** · `save_sbp_account` → QR (не 3013) |
| **#34** Zero-Click ChargeQr | **ждёт** одну оплату с привязкой в банке (нет AccountToken) |

**Артефакт:** [`tbank_charge_unlocked_mcp_2026-08-03/`](../milestones/veha_2/artifacts/tbank_charge_unlocked_mcp_2026-08-03/)  
**Заказчику:** можно проверять оплату картой в 1 клик + СБП с галочкой привязки (≥10₽).  
**Note:** SBP Recurrent сумма &lt; 10₽ → T-Bank **3016**.

### Order status OS detect + Wallet/WebPush (2026-08-03)

| Что | Статус |
|-----|--------|
| Intake (PHASE 0) | **`[x]`** |
| PHASE 1 SPEC | **`[x]`** |
| RED/GREEN шаги 1–6 | **`[x]`** tip `a0b3d0ea` |
| PHASE 3 REVIEW | **`[x]`** · JS 56 · Rails 11 |
| Push / Fly deploy / MCP | **`[x]`** v419 · MCP **PASS** |

**ТЗ:** [`Адаптивный виджет статуса заказа Детекция ОС и подписка на уведомления.md`](../milestones/veha_2/requirements/customer_tasks/Адаптивный%20виджет%20статуса%20заказа%20Детекция%20ОС%20и%20подписка%20на%20уведомления.md)  
**Артефакты:** [`order_status_os_detect_wallet_webpush/`](../milestones/veha_2/artifacts/order_status_os_detect_wallet_webpush/) · MCP [`mcp/fly_v419_2026-08-03/`](../milestones/veha_2/artifacts/order_status_os_detect_wallet_webpush/mcp/fly_v419_2026-08-03/)  
**Канон:** CTAs в `ActiveOrdersAccordion`; `deviceDetect`; `GET …/wallet_pass`; FCM `subscribeOrderPush`; init LS/permission.  
**Deploy:** push `35b7f00c` · Fly **v419** · `deployment-01KZ3CAC9RNSCPZRZ5VZWEWW8K`  
**MCP:** Android → Push CTA · iPhone CriOS → Wallet CTA · receipt toggle PASS (Point A Aram).  
**Дальше:** апрув заказчика. PKCS7 prod — PRACTICES.

