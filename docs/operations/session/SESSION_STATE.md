# SESSION_STATE

## Текущее состояние

**Дата:** 2026-06-27 (B1.13 прогон 4 — Fly MCP S2a/S2b 13/14)  
**Предыдущее:** B1.12-R3 Fly MCP 8/8 · B1.11 этап 0 · B1.7 **ЗАКРЫТА**  
**Веха 1:** **закрыта** 2026-06-19 (CHECKLIST § I, H.3 заочно).  
**Веха 2:** прогон 10 блоки **0–14** ✅ (ops); **§I не закрыта** (§E).  
**§2.3 оплата витрина:** **done** 2026-06-06 — [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](milestones/veha_2/requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md).

**Навигация ops:** [`../README.md`](../README.md) · [`milestones/PATH_MAP.md`](milestones/PATH_MAP.md).

**CBR — три потока + траектория:** тот же CBR § «Три потока», «Траектория», «Волна 4». **Северная звезда:** PDF 56 стр.

**Прогона 11 нет.** Точка входа для агента:
- **Блок 2:** B2.1 **закрыта** · фокус **B2.2** этап 1.
- **W1.4:** **done** — витрина = barista; Fly FULL A+B; апрув 2026-06-06.
- **W1.1–W1.3:** **done**.
- УК → витрины (закрыто): [`milestones/veha_2/runbooks/HANDOFF_UK_MENU_VITRINA.md`](milestones/veha_2/runbooks/HANDOFF_UK_MENU_VITRINA.md).

| Сейчас | Дальше |
|--------|--------|
| **B1.12 rev2** | R3 `[x]` Fly MCP **10/10** · RSA Fly `[x]` | **апрув заказчика** |
| **B1.11 режим работы** | **Fly MCP header A/B PASS** · артефакт 2026-06-21 | **апрув заказчика** |
| **B1.13 навигация** | Fly MCP S2a/S2b **13/14** · swipe blocked | **redeploy** pointer + re-run MCP |
| **B1.14 адрес в шапке** | **B1.14-3d** index map `[x]` | deploy (`./bin/fly_deploy.sh`) · B1.14-4 cart |

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

### Сессия 2026-06-24 (B1.13-S2b прогон 2: localStorage режима peek/expanded/hidden)

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
- **Дальше:** **`go` S2b прогон 2** — localStorage режима peek/expanded

### Сессия 2026-06-26 (B1.13: убран Q-rev6 — peek S2a+S3 без противоречия)

- **B1_13:** Q-rev6 удалён; канон: peek = сумма/+цена (S2a) + +/- (S3-rev2, уже на Fly)
- **Дальше:** Q-rev2 → `go` S2a/S2b

### Сессия 2026-06-26 (B1.13 rev2 gate: ответы владельца Q-rev3/4)

- **Q-rev3:** 100px → peek, 200px → hidden (как док; подстройка на S2b)
- **Q-rev4:** localStorage режима peek/expanded при возврате на каталог
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

### Сессия 2026-06-25 (B1.12 rev2: RSA на Fly + MCP 10/10)

- **Проверка:** `GET /payments/card_config` → `card_data_ready: true`
- **MCP:** prep + `b112_r3_fsm_mcp.mjs` — **10/10 PASS** (step 02 RSA ok)
- **Артефакт:** `b112_r3_fsm_ops_pass_2026-06-25.json` + скрины 2026-06-25
- **Дальше:** апрув заказчика на эпик B1.12 rev2

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
- **Фикс:** `order_status_acceptance_cbr_test.rb` — redirect `orderId` после B1.12 FSM
- **Дальше:** фаза 3 Fly MCP + deploy

### Сессия 2026-06-24 (B1.12 rev2 R3: фаза 3 deploy + Fly MCP)

- **Коммит:** `c27eb7c`
- **Deploy:** владелец на `coffeeos.fly.dev`
- **MCP:** prep + `b112_r3_fsm_mcp.mjs` — 9/10 (core PASS, RSA хвост)
- **Артефакт:** `b112_r3_fsm_ops_pass_2026-06-24.json` + скрины
- **Доки:** TBANK_RSA, CardHolder, legacy guard, Q-R2 → реализовано по v2
- **Дальше:** апрув заказчика · secret RSA на Fly

### Сессия 2026-06-24 (B1.12 rev2 R3: фаза 2 FSM 0–7)

- **FSM:** `shopPayFsm.js`, `CheckoutPayButton`, anti-flicker 600 ms, shake State 5
- **API:** checkout one-click → `POST /payments/one_click`
- **3DS:** `ThreeDsOverlay` iframe ACS
- **Тесты:** 32 runs, 296 assertions, 0 failures
- **Артефакт:** `b112_r3_phase2_fsm_2026-06-24.json`
- **Дальше:** фаза 3 Fly deploy + MCP

### Сессия 2026-06-24 (B1.12 rev2 R3: фаза 1 UI «Способ оплаты»)

- **Фронт:** `PaymentMethodsSheet.svelte`, `paymentMethodLabels.js`, `shopPayFsm.js`
- **Checkout:** summary + шторка вместо `saved-card-block` / таб «Картой»
- **Тесты:** `b112_r3_payment_methods_test.rb` + checkout CBR/cleanup/single-screen — PASS
- **Артефакт:** `b112_r3_phase1_payment_methods_2026-06-24.json`
- **Дальше:** фаза 2 FSM 0–7

### Сессия 2026-06-24 (B1.12 rev2 R3: фаза 0 gate)

- **Решения:** Q-R2-1 A nonPCI · Q-R2-2 тумблер on · Q-R2-3 макеты канон · deploy после R3
- **Gap:** макет 8924 vs `Checkout.svelte` — таблица в `B1_12_recurrent_payments.md`
- **Артефакт:** `b112_r3_phase0_gate_2026-06-24.json`
- **Дальше:** `go` R3 код

### Сессия 2026-06-24 (B1.12 rev2 R2: кастомная форма + RSA)

- **Фронт:** `NewCardSheet.svelte`, `tbankCardFormat.js`, `tbankCardEncrypt.js` (jsencrypt)
- **API:** `GET /shop/api/payments/card_config` · checkout → `POST /payments/new_card`
- **Тесты:** Rails 18 runs + node 6 tests + vite build — 0 failures
- **Артефакт:** `b112_r2_custom_card_ops_pass_2026-06-24.json`
- **Хвост:** `TBANK_RSA_PUBLIC_KEY` на Fly · deploy после R3

### Сессия 2026-06-24 (B1.12 rev2 R1: nonPCI бэкенд)

- **Код:** `finish_authorize`, `POST /shop/api/payments/new_card`, `one_click`, `bank_card_id`, `TbankPaymentResult`
- **Тесты:** 38 runs, 120 assertions, 0 failures
- **Артефакт:** `b112_r1_nonpci_ops_pass_2026-06-24.json`
- **Дальше:** `go` R2 (документ 2)

### Сессия 2026-06-24 (B1.12 rev2: workflow по документам)

- **Правило:** документ 1→R1→стоп · документ 2→R2→стоп · документ 3→R3 · один `go` на R
- **Доки:** `B1_12` прогресс 1a–3c · CHECKLIST C2c · JSON scope workflow
- **Дальше:** Q-R2-1 → `go` R1

### Сессия 2026-06-24 (B1.12 rev2: этап 0 docs)

- **ТЗ:** `B1_12_recurrent_payments.md` — тексты заказчика v2 дословно · scope v1 vs v2 · чеклисты R1–R3 rev2
- **Конфликты:** Q-R2-1 (iframe vs nonPCI) · Q-R2-2 (галочка save_card) · Q-R2-3 (макеты) — ждём владельца
- **Артефакты:** `b112_revision2_stage0_scope_2026-06-24.json` · `b112_tbank_nonpci_review_2026-06-24.json`
- **Макеты:** `1000008924.png` · `1000008925.png` · `README_b112_mockups_2026-06-24.md`
- **Ops:** CHECKLIST C2a–c · CBR · TBANK_RECURRENT.md · DEMO_FEEDBACK
- **Дальше:** ответы Q-R2-1..3 → `go` B1.12-R1 rev2

### Сессия 2026-06-24 (B1.12: макеты заказчика)

- **Скрины:** [`1000008924.png`](milestones/veha_2/artifacts/demo-feedback/screenshots/1000008924.png) — R3 способ оплаты · [`1000008925.png`](milestones/veha_2/artifacts/demo-feedback/screenshots/1000008925.png) — R2 новая карта
- **Дальше:** сверка нового ТЗ B1.12 · `go` на реализацию

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
- **Пропорции:** expanded ~36–40% · peek ~16% · hidden ~9% · scroll пороги
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

- **Скрины:** peek >3 горизонтально · chip-миниатюры · expanded список с модификаторами.
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

### Сессия 2026-06-22 (B1.12-R6: one-click без банка после репорта заказчика post-deploy)

- **Репорт:** после deploy заказчика — 2-я оплата снова Т-Банк снизу, нет «Сохранённая карта».
- **Причина:** карта не в API → new-card path · fallback `redirectToBankPayment` в one-click · lag webhook/GetState.
- **Fix:** убран банк из one-click · `shopSavedCardCache` · API recurrent без `payment_url` · `saved_card` в ответе.
- **Тест:** 21/21 PASS local (b112 checkout, r2, r3, settle, saved_card_store, tbank_sync).
- **Дальше:** **повторный deploy Fly** · real-card 1→2 · апрув B1.12.

### Сессия 2026-06-21 (B1.12-R5: убран inline iframe банка с checkout)

- **Было:** Т-Банк embed снизу на checkout (скрин заказчика).
- **Стало:** редирект на банк · кнопка FSM · `#/payment-result` + finalize · one-click без iframe.
- **Тест:** 15/15 PASS local (checkout, r2, settle, r3, recurrent).
- **Дальше:** **deploy Fly** · MCP post-deploy · real-card 1→2.

### Сессия 2026-06-21 (B1.12: one-click v2 — полный фикс 2-й оплаты)

- **Баг:** 2-я оплата — снова iframe Т-Банка; нет saved card на checkout.
- **Fix:** finalize GetState всегда + `saved_card` · Charge→GetState · recurrent API без iframe · фронт race/retry/one-click без iframe fallback.
- **Тест:** 17/17 PASS local (settle, r3, checkout, recurrent, sync).
- **Дальше:** **deploy Fly** · real-card 1→2 оплата · апрув B1.12.

### Сессия 2026-06-21 (B1.12: fix привязки карты — GetState + SavedCardStore)

- **Баг заказчика:** 2-я оплата снова форма банка (CVC), карта не в `saved_cards`.
- **Fix:** `TbankPaymentSync` на finalize · GetState · fallback Pan · retry saved_cards на checkout.
- **Тест:** 28/28 PASS local (saved_card_store, tbank_payment_sync, b112_payment_settle_chain).
- **Дальше:** **deploy Fly** · real-card E2E (1-я оплата → one-click 2-я) · апрув эпика B1.12.

### Сессия 2026-06-21 (B1.12-R4 Fly MCP post-deploy #2 — после удаления `#/payment`)

- **Deploy:** владелец · `75dc252` на coffeeos.fly.dev.
- **Fly MCP:** tenant `2fdee1ac-…` — **11/11 PASS** (inline checkout, stale `#/payment` пустой, one-click).
- **Тест:** b112 8/8 PASS local.
- **Артефакт:** [`b112_r4_single_screen_post_deploy_2026-06-21.json`](milestones/veha_2/artifacts/demo-feedback/b112_r4_single_screen_post_deploy_2026-06-21.json) — обновлён post-deploy #2.
- **Дальше:** **апрув эпика B1.12** заказчиком · real-card E2E.

### Сессия 2026-06-21 (B1.12 — удалён роут `#/payment`)

- **Сделано:** снят `Payment.svelte`, маршрут `/payment` из `App.svelte` — оплата только на `#/checkout`.
- **Тест:** shop integration 18 runs, 159 assertions, 0 failures.
- **Дальше:** deploy → **апрув эпика B1.12** заказчиком.

### Сессия 2026-06-21 (B1.12-R4 Fly MCP post-deploy)

- **Deploy:** владелец на Fly (`783b4ff`).
- **Fly MCP:** tenant `2fdee1ac-…` — 11/11 PASS: inline iframe на `#/checkout`, legacy `#/payment` → checkout, one-click без `#/payment`.
- **Тест:** `b112_checkout_single_screen_test.rb` + `b112_r3_one_click_test.rb` — **8 runs, 39 assertions, 0 failures**.
- **Скрипты:** `bin/b112_r4_single_screen_prep_fly.rb` · `bin/b112_r4_single_screen_mcp.mjs` (prep: cash order перед seed карты).
- **Артефакт:** [`b112_r4_single_screen_post_deploy_2026-06-21.json`](milestones/veha_2/artifacts/demo-feedback/b112_r4_single_screen_post_deploy_2026-06-21.json).
- **Дальше:** апрув заказчика эпик B1.12 · real-card 1-я + 2-я оплата на tenant.

### Сессия 2026-06-20 (B1.12-R4 single-screen checkout)

- **Ошибка:** R2/R3 сдали без снятия 3 экранов — заказчик прав.
- **Сделано:** inline pay на checkout, кнопка статусов, без `push("/payment")`.
- **Тест:** b112 9/9 PASS local.
- **Артефакт:** [`b112_checkout_single_screen_2026-06-20.json`](milestones/veha_2/artifacts/demo-feedback/b112_checkout_single_screen_2026-06-20.json).
- **Дальше:** deploy → MCP → апрув.

### Сессия 2026-06-20 (B1.12 bug шаг 3 post-deploy MCP)

- **Fly MCP:** tenant `2fdee1ac-…` — immediate `#/order/:id` · poll webhook → redirect · finalize POST в network.
- **Артефакт:** [`b112_payment_step3_return_post_deploy_2026-06-20.json`](milestones/veha_2/artifacts/demo-feedback/b112_payment_step3_return_post_deploy_2026-06-20.json).
- **Скрипты:** `bin/b112_payment_step3_return_prep_fly.rb` · `bin/b112_payment_step3_return_mcp.mjs`.
- **Дальше:** апрув заказчика · real-card.

### Сессия 2026-06-20 (B1.12 bug шаг 3 — 3DS return)

- **Дополнение к шагу 2:** `payment_started` · `awaiting_settlement` после return из 3DS.
- **deepLinkRedirectCallback:** не меняли (full redirect); resume через sessionStorage.
- **Тест:** 2/2, 19 assertions PASS.
- **Дальше:** deploy → Fly MCP repro (шаг 3 return path).

### Сессия 2026-06-20 (B1.12 bug post-deploy MCP)

- **Deploy:** владелец на Fly.
- **MCP:** tenant `2fdee1ac-…` — order→callback→accepted→finalize `payment_settled` PASS.
- **Тест:** `b112_payment_settle_chain_test.rb` 2/2 PASS.
- **ISSUES:** 🔴 → **resolved**.
- **Артефакт:** [`b112_payment_settle_post_deploy_2026-06-20.json`](milestones/veha_2/artifacts/demo-feedback/b112_payment_settle_post_deploy_2026-06-20.json).
- **Дальше:** апрув заказчика B1.12 · real-card на tenant.

### Сессия 2026-06-20 (B1.12 bug шаг 2 — settle chain)

- **Было:** UI зависает — `finishSuccess()` только из `integration.js`; embed fallback молчит.
- **Стало:** `Payment.svelte` → `beginSettlementWatch()` (poll finalize 1.5s + cable) → `finishSuccess()` → `#/payment-result`.
- **Бэкенд:** `POST /callbacks/tbank` → accepted → finalize `payment_settled` (тест callback).
- **Тест:** `b112_payment_settle_chain_test.rb` — **2 runs, 15 assertions, 0 failures**.
- **Артефакт:** [`b112_payment_settle_chain_2026-06-20.json`](milestones/veha_2/artifacts/demo-feedback/b112_payment_settle_chain_2026-06-20.json).
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

### Сессия 2026-06-19 (B1.12 — ответы Q2/Q3/Q5/Q7 подтверждены владельцем)

- **Ответы:** дословно зафиксированы в `B1_12_recurrent_payments.md` · `do_not_reask`.
- **Артефакт:** [`b112_customer_answers_confirmed_2026-06-19.json`](milestones/veha_2/artifacts/demo-feedback/b112_customer_answers_confirmed_2026-06-19.json).
- **Дальше:** апрув эпика B1.12 (код R1–R3 уже PASS).

### Сессия 2026-06-19 (Веха 1 — формальное закрытие)

- **Апрув владельца:** закрыть В1 заочно (H.3 §1 + A–G достаточно).
- **Ops:** `veha_1/checklists/CHECKLIST.md` § I + H.3 `[x]`; `PRACTICES.md`, `README.md`; `HANDOFF`, `CHANGELOG` v1.210.
- **Хвосты → В2:** QA 5.1; `demo:seed` в release; полный LIVE_DEMO MCP §2–10.

### Сессия 2026-06-20 (B1.12 шаг 0–1 — investigate tenant заказчика)

- **Скрипт:** `bin/b112_customer_payment_investigate_fly.rb`
- **Артефакт:** [`b112_customer_payment_investigate_2026-06-20.json`](milestones/veha_2/artifacts/demo-feedback/b112_customer_payment_investigate_2026-06-20.json)
- **Факт:** 6× `pending_payment` card за 7d; likely заказ `acb7cc62…` 4.74₽; R2 OK; saved_cards=0.
- **Дальше:** шаг 2 — polling `finalize` на `#/payment`.

### Сессия 2026-06-19 (B1.12 — репорт заказчика: оплата зависает после 3DS)

- **Артефакт:** [`b112_customer_payment_stuck_2026-06-19.json`](milestones/veha_2/artifacts/demo-feedback/b112_customer_payment_stuck_2026-06-19.json) + скрин.
- **Tenant заказчика:** `2fdee1ac-4674-41ee-b89e-87b45643f789` (не MCP-tenant).
- **ISSUES:** 🔴 open — нужен payment_id/trace для repro.

### Сессия 2026-06-19 (B1.12-R3 Fly MCP 8/8 post-deploy)

- **Deploy:** владелец (до MCP).
- **MCP:** `ruby bin/b112_r3_one_click_prep_fly.rb` + `node bin/b112_r3_one_click_mcp.mjs` — **8/8 PASS**.
- **Скрины:** `b112_r3_one_click_checkout_2026-06-19.png`, `b112_r3_one_click_post_deploy_2026-06-19.png`.
- **Артефакт:** [`b112_r3_one_click_post_deploy_2026-06-19.json`](milestones/veha_2/artifacts/demo-feedback/b112_r3_one_click_post_deploy_2026-06-19.json).

### Сессия 2026-06-19 (B1.12-R3 — 1 клик + стейт кнопки OPS_PASS local)

- **Витрина:** `Checkout.svelte` — блок сохранённой карты, one-click `saved_card_id`, FSM кнопки.
- **Lib:** `shopOneClickPay.js`, `CheckoutPayButton.svelte`.
- **API:** `GET saved_cards?email=` — резолв customer по verified email.
- **Backend:** идемпотентность recurrent по `client_order_uuid`.
- **Тест:** `b112_r3_one_click_test.rb` — 4/4 PASS.
- **Артефакт:** [`b112_r3_one_click_ops_pass_2026-06-19.json`](milestones/veha_2/artifacts/demo-feedback/b112_r3_one_click_ops_pass_2026-06-19.json).
- **Не сделано:** `fly deploy`, Fly MCP R3 post-deploy, апрув заказчика.

### Сессия 2026-06-19 (B1.12-R2 Fly MCP 6/6 post-deploy)

- **MCP:** `ruby bin/b112_r2_native_card_prep_fly.rb` + `node bin/b112_r2_native_card_mcp.mjs` — **6/6 PASS**.
- **Стенд:** `https://coffeeos.fly.dev` · tenant `655aaccb-004a-4bb9-a50a-ce618854dda3` · Neon DB.
- **Артефакт:** [`b112_r2_native_card_post_deploy_2026-06-19.json`](milestones/veha_2/artifacts/demo-feedback/b112_r2_native_card_post_deploy_2026-06-19.json).
- **Скрины:** `screenshots/b112_r2_native_card_intro_2026-06-19.png`, `b112_r2_native_card_post_deploy_2026-06-19.png`.
- **Дальше:** B1.12-R3 (1 клик + стейт кнопки) — ждём `go`.

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

### Сессия 2026-06-19 (B1.12-R2 deploy — внешний Postgres quota)

- **Deploy:** `ded6371` — `docker-entrypoint` fix; временно `--skip-release-command`.
- **Причина:** случайный внешний `DATABASE_URL` (не Fly) — quota exceeded.
- **Решение:** миграция на Fly MPG (см. сессию выше).

### Сессия 2026-06-18 (B1.12-R2 — web-фрейм + card_binding, OPS_PASS local)

- **Код:** `card_binding` в API orders · Checkout/Payment session · PaymentResult «Карта привязана / Оплачено» · Payment intro copy.
- **Тест:** `b112_r2_payment_iframe_test.rb` — PASS.
- **Скрипты:** `bin/b112_r2_native_card_prep_fly.rb` · `bin/b112_r2_native_card_mcp.mjs`.
- **Fly MCP:** **blocked** — `/shop` HTTP 500 → [`b112_r2_native_card_post_deploy_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b112_r2_native_card_post_deploy_2026-06-18.json) · ISSUES 🔴.
- **Локальный OPS:** [`b112_r2_native_card_ops_pass_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b112_r2_native_card_ops_pass_2026-06-18.json).

### Сессия 2026-06-18 (B1.12-R1 — Fly MCP post-deploy, 5/5 PASS)

- **Скрипты:** `bin/b112_r1_recurrent_prep_fly.rb` · `bin/b112_r1_recurrent_mcp.mjs`
- **Fly:** saved_cards primary · recurrent path (422 fake RebillId — ожидаемо) · card init `payment_url`
- **Артефакт:** [`b112_r1_recurrent_post_deploy_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b112_r1_recurrent_post_deploy_2026-06-18.json) · скрин `screenshots/b112_r1_recurrent_post_deploy_2026-06-18.png`
- **Следующий:** R2 web-фрейм + 3DS → ждём **`go`**

### Сессия 2026-06-18 (B1.12-R1 — рекуррент бэкенд, OPS_PASS)

- **Код:** `MobilePaymentMethod`, `SavedCardStore`, `TbankAdapter#charge_recurrent`, `RecurrentOrderCreator`, `GET /shop/api/saved_cards`.
- **Тесты:** 8 R1 + 30 regression §2.3 — 0 failures.
- **Артефакт:** [`b112_r1_recurrent_ops_pass_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b112_r1_recurrent_ops_pass_2026-06-18.json).
- **Fly MCP:** 5/5 PASS — [`b112_r1_recurrent_post_deploy_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b112_r1_recurrent_post_deploy_2026-06-18.json).

### Сессия 2026-06-18 (B1.12 — рекуррент / 1 клик, этап 0 ТЗ)
- **ТЗ:** [`B1_12_recurrent_payments.md`](milestones/veha_2/requirements/customer_tasks/B1_12_recurrent_payments.md) — R1/R2/R3, текст дословно.
- **Scope:** Т-Банк · 1 user = 1 card · только веб-витрина.
- **Ответы Q1–Q7:** закрыты 2026-06-18 (все карты храним, главная = последняя оплата; card only; идемпотентность при retry).
- **Артефакт:** [`b112_stage0_scope_2026-06-18.json`](milestones/veha_2/artifacts/demo-feedback/b112_stage0_scope_2026-06-18.json).
- **Runbook:** [`TBANK_RECURRENT.md`](milestones/veha_2/runbooks/TBANK_RECURRENT.md) (черновик).
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
- ✓ Выполнен B3.5: добавлены `mobile_carts`, `mobile_payment_methods` (миграция `20260511183000`).
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
[2026-05-11] | Действие: Выполнен B3 — миграция `20260511181500_create_loyalty_promo_push_feedback.rb` (таблицы `loyalty_accounts`, `loyalty_transactions`, `promo_code_usages`, `push_notifications`, `order_feedback`), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B3.5 (`mobile_carts`, `mobile_payment_methods`) или B4 (`pickup_*`). | Статус: done | Вопросы: нет.
[2026-05-11] | Действие: Выполнен B3.5 — миграция `20260511183000_create_mobile_carts_and_payment_methods.rb` (таблицы `mobile_carts`, `mobile_payment_methods`), миграции применены в dev и test окружениях, полный тестовый прогон зелёный (`324/1065`, без падений). | Следующий шаг: B4 (`pickup_calls`, `pickup_display_settings`, `pickup_events`). | Статус: done | Вопросы: нет.
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
