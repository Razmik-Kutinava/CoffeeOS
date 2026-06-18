# CHANGELOG

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
  - `mobile_payment_methods`.

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
