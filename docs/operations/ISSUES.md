# ISSUES

> Канон (`coffeeos-commit-ops.mdc`, `RULES_INDEX.md`): баг фиксируется здесь **сразу**; статус до **«решено»** + **чем закрыли** (код, тесты, миграции).

## 🔴 Блокеры

[2026-07-16] — UserCards: карта не сохранилась после оплаты с save_card ON (bug_13-23)
**Статус:** 🔴 **открыт** · deploy v366 **[x]** · MCP 2 карты **[x]** · апрув 3.5 **[ ]**
**Источник:** заказчик · [`bug_13-23_repeat_purchase_card_missing.png`](../milestones/veha_2/artifacts/usercards_save_card/screenshots/bug_13-23_repeat_purchase_card_missing.png)
**Root cause (Фаза 0):** webhook RebillId enqueued, worker stopped → SavedCardStore не вызван.
**Root cause (Фаза 3.2, платёж 8866531465 / 09:56):** FA CONFIRMED **без RebillId/Pan** → settle + однократный GetState не дожали; банк прислал RebillId *8782 только **2026-07-17** (delayed webhook). Init Recurrent=Y ожидаем при save_card=true. **Наш баг:** нет retry GetState / delayed sync — карта не в 8925 в день оплаты.
**Артефакт:** [`usercards_fly_payment_root_cause_2026-07-18.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_payment_root_cause_2026-07-18.json)
**Фикс Фаза 1 (код + deploy v362):** `TbankController` perform_now · `SOLID_QUEUE_IN_PUMA` · `OrderCreator` recurrent save_card — **не закрывает** кейс FA без RebillId.
**Приёмка Fly 2026-07-16 (частичная):**
- Replay webhook 0₽ → [`usercards_fly_phase1_verify_2026-07-16.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_phase1_verify_2026-07-16.json) — aramfifa **MIR *5953** (replay, не E2E 2-й карты)
- MCP: [`usercards_phase1_mcp_2026-07-16.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_phase1_mcp_2026-07-16.json) — *5953 в списке
**Живая оплата 2026-07-18:** MCP «Новая карта» 4300*0777 → payment `8878842078` **failed**, Pan/RebillId nil (prod отклоняет test PAN).
**Осталось:** апрув скрина 8925 (шаг 3.5) · E2E fix 3.3 — реальная MIR карта заказчика ≠ *5953
**Deploy Fly v366 (2026-07-18):** release `deployment-01KXT8NR80HW40FKBRKFJCMDT7` · 3.3 retry GetState на prod
**Приёмка 3.4:** MCP 2 карты (*5953 + *8782) — [`usercards_phase34_mcp_2026-07-18.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_phase34_mcp_2026-07-18.json)

[2026-07-16] — Checkout Фаза 2 UX: нет одной шторки (peek сверху + PaymentMethodsSheet expanded снизу)
**Статус:** **код done** · **MCP Fly [ ]** · **апрув заказчика [ ]**
**Источник:** заказчик · [`Исправление сохранения карты…`](../milestones/veha_2/requirements/customer_tasks/Исправление%20сохранения%20карты%20в%20UserCards%20после%20успешной%20оплаты.md) § **Канон UX checkout** · макеты **1000008924/8925**
**Фикс Фаза 2 (код):** `openCheckoutPayStack` + stacked UX · `prog25`
**Расследование 2026-07-16:** [`usercards_fly_payment_investigate_2026-07-16.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_payment_investigate_2026-07-16.json) — 2× succeeded; **09:56** без Pan/RebillId в момент FA.
**Root cause 3.2:** [`usercards_fly_payment_root_cause_2026-07-18.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_payment_root_cause_2026-07-18.json) — см. 🔴 UserCards (общий поток).
**Осталось:** MCP stacked · апрув заказчика (после UserCards 3.4).

## Решено недавно

[2026-07-15] — Checkout CartSheet (промежуточный код, не приёмка)
**Статус:** **superseded** 2026-07-16 — см. 🔴 выше
**Было:** `isCartSheetRoute` catalog+checkout · deploy v359 · grep-тесты PASS — **заказчик не принял**.

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
**Neon billing:** spending limit **$15** — поднять заказчиком в Console (2026-06-19).

## 🟡 Жёлтые

[2026-05-30] — Kiosk: POST /kiosk/api/auth
Статус: resolved
Описание: Flutter/киоск нужен tenant по device_token; отдельного контроллера не было.
Решение: `Kiosk::Api::AuthController`, контракт [`FLUTTER_API.md`](milestones/veha_2/runbooks/FLUTTER_API.md); shop API без дублирования.
Проверка: 6 tests; curl smoke в FLUTTER_API.md.

[2026-05-28] — Fly: worker crash loop (DB pool < Solid Queue threads)
Статус: resolved
Описание: `bin/jobs` exit code 1 — «Solid Queue is configured to use 5 threads but the database connection pool is 3»; worker machine stopped, jobs не обрабатывались.
Решение: `DB_POOL=8` в `fly.toml`; `database.yml` — `ENV.fetch("DB_POOL")`; rake `fly:callback_smoke` для prod retest.
Проверка: worker `2871332` started; `TbankCallbackJob` Processed order `85bef120` через SolidQueue(critical), без perform_now fallback.
