# ISSUES

> Канон (`coffeeos-commit-ops.mdc`, `RULES_INDEX.md`): баг фиксируется здесь **сразу**; статус до **«решено»** + **чем закрыли** (код, тесты, миграции).

## 🔴 Блокеры

_нет_

## Решено недавно

[2026-07-15] — Checkout: нет шторки с заказами под оплатой (эталон заказчика)
Статус: **resolved** 2026-07-15 (код; MCP на Fly — после deploy по go)
Описание: на `#/checkout` CartSheet peek **под** PaymentMethodsSheet.
**Закрыли:** `isCartSheetRoute` catalog+checkout · `ensureCheckoutCartPeek` · `requestCheckoutPay`/`CHECKOUT_PAY_EVENT` · pad `pb-[32vh]` · z-index 56>50 · тест `shop_checkout_cart_sheet_ux_test` + B1.13-S2/S2b/S3 PASS.
Эталон: `artifacts/usercards_save_card/screenshots/` · ТЗ UserCards.


[2026-07-04] — B1.11-BUG-OVERNIGHT: нельзя создать точку с ночной сменой (`must be after opens_at`)
Статус: **resolved** 2026-07-05
**Закрыли:** F1–F4 код · Fly MCP PASS · **апрув заказчика 2026-07-05** — [`b111_customer_approval_2026-07-05.json`](milestones/veha_2/artifacts/demo-feedback/b111_customer_approval_2026-07-05.json)

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
