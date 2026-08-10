# HANDOFF — Веха 2

## Шапка (агент читает только это + todo + ISSUES «🔴 Открыто»)

**Дата:** 2026-08-10 (workflow audit: ISSUES/Entire/docs)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| Entire hooks ✅ · ISSUES «🔴 Открыто» · docs sync | UserCards / витрина · SBR |

**last_done:** workflow audit `6b5b5a51` + Entire Windows hook note `da772854`  
**next_step:** Entire checkpoint — agent-сессия + commit (Entire CLI в Windows PATH или WSL git)  

**Архив session:** [`archive/README.md`](archive/README.md)  
**Архив journal:** [`../journal/archive/README.md`](../journal/archive/README.md)

---

## Текущий месяц (2026-08)

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

