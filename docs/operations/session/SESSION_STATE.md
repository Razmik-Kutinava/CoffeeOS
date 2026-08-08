# SESSION_STATE

## Шапка (агент читает только это + todo + 🔴 ISSUES)

**Дата:** 2026-08-08 (#47 PWA status sync · SPEC)  
**Ветка:** `develop`

| Сейчас | Дальше |
|--------|--------|
| #47 intake + SPEC в `todo.md` | RED: poll/visibility + refresh frequent |
| 🔴 #47 open | — |

**Архив session:** [`archive/README.md`](archive/README.md)  
**Архив journal:** [`../journal/archive/README.md`](../journal/archive/README.md)

---

## Текущий месяц (2026-08)

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

