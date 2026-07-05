# ISSUES

> Канон (`coffeeos-commit-ops.mdc`, `RULES_INDEX.md`): баг фиксируется здесь **сразу**; статус до **«решено»** + **чем закрыли** (код, тесты, миграции).

## 🔴 Блокеры

[2026-07-04] — B1.11-BUG-OVERNIGHT: нельзя создать точку с ночной сменой (`must be after opens_at`)
Приоритет: 🔴 | Статус: **fixed Fly MCP PASS · ждёт апрув заказчика (A1)**
Описание: УК create точки, пн opens 09:23 / closes 01:24 → ошибка `Понедельник: must be after opens_at`. Блокирует создание точек с работой через полночь.
**Канон + текст заказчика + чеклист F1–A1:** [`B1_11_tenant_operating_hours.md`](milestones/veha_2/requirements/customer_tasks/B1_11_tenant_operating_hours.md) § B1.11-BUG-OVERNIGHT.
**Артефакты:** [`b111_bug_overnight_customer_2026-07-04.json`](milestones/veha_2/artifacts/demo-feedback/b111_bug_overnight_customer_2026-07-04.json) · [`b111_bug_overnight_mcp_2026-07-05.json`](milestones/veha_2/artifacts/demo-feedback/b111_bug_overnight_mcp_2026-07-05.json) · [`b111_bug_overnight_fly_post_deploy_2026-07-05.json`](milestones/veha_2/artifacts/demo-feedback/b111_bug_overnight_fly_post_deploy_2026-07-05.json)
**Root cause:** `TenantWeekdaySchedule#closes_after_opens` требует `closes_at > opens_at`; `TenantOperatingHours` тоже same-day only.
**Фикс (2026-07-05):** F1–F4 `[x]` — `overnight?` + `opens_and_closes_distinct` · `TenantOperatingHours` overnight · 36 tests PASS · MCP Chrome DevTools: create точки пн 09:23–01:24 → «Точка создана», DB `overnight: true`.
**Fly MCP (2026-07-05):** create пн 09:23–01:24 → «Точка создана» · tenant `af4f78d6-c66b-428e-8ee4-5a609c5c9131` · edit 09:23/01:24 сохранено.
**Дальше:** апрув заказчика «ок» → close ISSUES.
**Не путать с:** B1.12-BUG-SAVE (карта) — отдельный баг, ждёт живую оплату заказчика.

[2026-07-04] — B1.12-BUG-SAVE: карта не сохраняется после 1-й оплаты (тумблер on)
Приоритет: 🔴 | Статус: **fixed на Fly v328 — ждёт A1 (живая CONFIRMED оплата заказчика)**
Описание: заказчик — после успешной оплаты «Новая карта» с тумблером «Использовать карту для будущих заказов» на 2-м заказе карты нет; запись UserCards/`mobile_payment_methods` не создаётся.
**Текст дословно + чеклист D1–A1:** [`B1_12_recurrent_payments.md`](milestones/veha_2/requirements/customer_tasks/B1_12_recurrent_payments.md) § «Баг приёмки B1.12-BUG-SAVE».
**Скрин:** [`b112_save_card_toggle_on_customer_2026-07-04.png`](milestones/veha_2/artifacts/demo-feedback/screenshots/b112_save_card_toggle_on_customer_2026-07-04.png)
**Канон имён:** `mobile_payment_methods` / `customer_id` / `card_token` (= RebillId).
**D1:** PASS — Fly v327 содержал B1.12 R1–R3; баг **не** из-за деплоя.
**D2–F1 (2026-07-04):** ROOT CAUSE — `settle_confirmed!` проверял `raw["RebillId"]` из FinishAuthorize, а T-Bank nonPCI возвращает RebillId **только в webhook/GetState**. Фикс: fallback на `TbankPaymentSync.sync_order!` (GetState) если RebillId нет в raw. Тест добавлен. Коммит: **1081dac**. Deploy **v328**. MCP browser: flow до банка PASS; sandbox CLIENT_ERROR — A1 только живая оплата.
**Дальше:** A1 апрув заказчика после CONFIRMED.

## Решено недавно


[2026-07-03] — Sentry RUBY-9: Manager::OrdersController#show 500
Статус: **resolved** 2026-07-03
Описание: `Association named 'product' was not found on OrderItem` — `@order.order_items.includes(:product)` при отсутствии `belongs_to :product` (снимок `product_name`/`product_id`).
**Sentry:** RUBY-9 · 1 event · `Manager::OrdersController#show` · 0 users.
**Закрыли:** убрали `.includes(:product)` · тест `manager_orders_show_test.rb` 1 run PASS.
**Archive в Sentry:** RUBY-9 (код) · RUBY-Q/M/N/K/P/R (Neon quota, квота оплачена 2026-07-03) · RUBY-S (pg_stat_statements) · RUBY-T/D (smoke rake).

[2026-06-25] — B1.13-S2 фаза 3: Fly MCP FAIL — S2 не задеплоен
Статус: **resolved** 2026-06-25
Описание: pre-deploy probe 2/9 — на Fly старая сборка (вкладка «Корзина»).
**Закрыли:** deploy владельца → `node bin/b113_s2_cart_popup_mcp.mjs` — **9/9 PASS** · [`b113_s2_post_deploy_2026-06-25.json`](milestones/veha_2/artifacts/demo-feedback/b113_s2_post_deploy_2026-06-25.json).

[2026-06-22] — B1.12: после deploy заказчика 2-я оплата снова Т-Банк (не one-click)
Статус: **resolved** local · **нужен повторный deploy**
Описание: заказчик после deploy — на 2-й оплате снова форма Т-Банка снизу + лишний экран; блок «Сохранённая карта» не виден.
**Причина:** RebillId не успевал в `saved_cards` → checkout шёл в `submitNewCard` · one-click при сбое открывал банк через `redirectToBankPayment` · нет кэша карты после finalize.
**Закрыли:** B1.12-R6 — жёсткий запрет банка в one-click · `shopSavedCardCache` · API recurrent без `payment_url` · тесты 21/21.

[2026-06-21] — B1.12: карта не привязалась после 1-й оплаты, 2-я снова форма банка + CVC
Статус: **resolved** · R6 local 2026-06-22 · deploy pending
Описание: tenant `2fdee1ac-…` · после первой оплаты `saved_cards` пуст · вторая попытка — iframe Т-Банка, CVC `000`, «Проверьте код».
**Причина:** webhook без Pan / задержка · finalize не backfill на accepted · race savedCardsLoading · one-click открывал iframe.
**Закрыли:** GetState sync всегда на finalize + saved_card в ответе · Charge→GetState · recurrent API без iframe · фронт race/retry · тесты 17/17 шага.

[2026-06-19] — B1.12: оплата не завершается после 3DS (репорт заказчика)
Статус: **resolved** 2026-06-20
Описание: tenant `2fdee1ac-…` · `#/payment` · UI зависал на форме Т-Банка после webhook.
**Шаг 0–1:** [`b112_customer_payment_investigate_2026-06-20.json`](milestones/veha_2/artifacts/demo-feedback/b112_customer_payment_investigate_2026-06-20.json) — 6× pending, R2 OK.
**Шаг 2:** [`b112_payment_settle_chain_2026-06-20.json`](milestones/veha_2/artifacts/demo-feedback/b112_payment_settle_chain_2026-06-20.json) — `beginSettlementWatch` + тест 2/2 local · коммит `14cdf12`.
**Post-deploy:** [`b112_payment_settle_post_deploy_2026-06-20.json`](milestones/veha_2/artifacts/demo-feedback/b112_payment_settle_post_deploy_2026-06-20.json) — Fly MCP tenant заказчика: callback→accepted→finalize `payment_settled` PASS.
**Закрыли:** polling finalize/cable в `Payment.svelte` + deploy владельца.
**Дальше:** апрув заказчика на эпик B1.12; при реальном списании без редиректа — `payment_id` + timestamp.

[2026-06-20] — B1.12 UX: 3 лишних экрана оплаты (scope gap, не баг webhook)
Статус: **resolved** local · deploy pending
Описание: заказчик — «всё в одной кнопке», без `#/payment`. R2/R3 сдали с `push("/payment")` и intro — **не было сделано вовремя**.
**Исправление:** R4 single-screen checkout · [`b112_checkout_single_screen_2026-06-20.json`](milestones/veha_2/artifacts/demo-feedback/b112_checkout_single_screen_2026-06-20.json).

[2026-06-19] — Fly deploy + Neon Launch
Статус: **resolved**
Описание: `DATABASE_URL` → Neon `coffeeos`; Launch plan; `fly deploy` release_command OK; `/up` + `/shop` 200.
Fly MPG `coffeeos-db` destroyed. CI deploy → `workflow_dispatch` only.
**Neon billing:** spending limit **$15** — включён владельцем в Console (2026-06-19).

## 🟡 Важно

[2026-05-30] — Kiosk: POST /kiosk/api/auth
Статус: resolved
Описание: Flutter/планшет нужен tenant по device_token; отдельного эндпоинта не было.
Решение: `Kiosk::Api::AuthController`, контракт [`FLUTTER_API.md`](milestones/veha_2/runbooks/FLUTTER_API.md); shop API без дублирования.
Проверка: 6 tests; curl smoke в FLUTTER_API.md.

[2026-05-28] — Fly: worker crash loop (DB pool < Solid Queue threads)
Статус: resolved
Описание: `bin/jobs` exit code 1 — «Solid Queue is configured to use 5 threads but the database connection pool is 3»; worker machine stopped, jobs не обрабатывались.
Решение: `DB_POOL=8` в `fly.toml`; `database.yml` — `ENV.fetch("DB_POOL")`; rake `fly:callback_smoke` для prod retest.
Проверка: worker `2871332` started; `TbankCallbackJob` Processed order `85bef120` через SolidQueue(critical), без perform_now fallback.

[2026-05-28] — Fly: Solid Queue worker + live табло без F5
Приоритет: 🟡 | Статус: **решено**
Описание: broadcast через async job не доходил до табло (worker/job lag).
Решение: sync `OrderBoardBroadcaster` из витрины и callback; worker для `TbankCallbackJob` retry; CI scale web=1 worker=1. Commits `a7f469e`, `97baa77`, `0bde33d`.
Проверка: MCP — barista открыт → cash LiveSmoke2 → ACCEPTED 5→6 без F5; `/cable` 101.

[2026-05-28] — Fly: Solid Queue/Cable schema не загружались → callback 500, barista broadcast 500
Приоритет: 🟡 | Статус: **решено**
Описание: `solid_queue_jobs` / `solid_cable_messages` отсутствовали; idempotency callback на SolidCache → RangeError.
Решение: idempotency → `Payments::CacheCounter`; callback `perform_now` fallback; `fly:release` → `DatabaseTasks.load_schema` для queue/cache/cable; barista broadcast rescue.
Проверка: E2E callback `f8427fc4-…` → `accepted`; barista `##202605-0008` на табло; 544/0 tests.

## 🟢 Потом

## Закрытые

[2026-05-28] — Shop card/sbp: 500 при Init Т-Банка на Fly (pre-prod smoke)
Приоритет: 🔴 | Статус: **решено**
Описание: Circuit breaker использовал `Rails.cache.increment` / SolidCache → `ActiveRecord::RangeError` (key_hash out of range) → 500 вместо 422.
Решение: `Payments::CacheCounter` на `MemoryStore` (как Rack::Attack); ApiError не трипит CB; `void_pending_online_order!` при ошибке Init; `rescue_from Shop::OrderCreator::Error` → 422. Коммиты `80e38be`, `884cdea`.
Проверка: smoke card → 200, `payment_url` `https://pay.tbank.ru/…`, 179₽ на форме Т-Банка; cash → 200 `accepted`. Prod terminal *(2026-05-28)*: Init `EJe3CaXH`, форма 179₽.

[2026-05-01] — SolidCache: No unique index found for key_hash
Приоритет: 🔴 | Статус: закрыта
Описание: ArgumentError при записи в SolidCache. upsert_all вызывается с unique_by: :key_hash, но в таблице solid_cache_entries нет уникального индекса на эту колонку.
Влияние: Все запросы к /shop/api/categories падали с 500 ошибкой. Rack::Attack не мог инкрементировать счетчик.
Решение: 1) Добавлен уникальный индекс на key_hash в таблицу solid_cache_entries. 2) Настроен Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new для rate limiting, так как SolidCache не поддерживает increment.
Агент: Backend
