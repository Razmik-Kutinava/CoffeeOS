# ISSUES

> Канон (`coffeeos-commit-ops.mdc`, `RULES_INDEX.md`): баг фиксируется здесь **сразу**; статус до **«решено»** + **чем закрыли** (код, тесты, миграции).

## 🔴 Блокеры

[2026-07-28] — Шапка «ул. Fly Test» у Арама (inactive last_ordered)
**Статус:** 🟡 **код local PASS** · deploy/MCP `[ ]`
**Источник:** скрин заказчика «Хотя уже лучше» · адрес Fly Test при телефоне ок
**Root cause:** `last_ordered_tenant_id` = inactive Fly Overnight (`af4f78d6`, 7 заказов 2026-07-28) свежее Point A → preferred=Fly Test → bootstrap не уводил.
**Чем закрыли (код):** `resolvePreferredTenantId` только active · bootstrap bounce `!currentAllowed` · history skip inactive last_ordered
**Осталось:** push + fly deploy + MCP шапка Ленин

[2026-07-28] — В профиле Арама тестовый телефон вместо настоящего
**Статус:** **resolved** 2026-07-28 · prod `link_phone!` + merge
**Источник:** скрин владельца · настоящий номер `+79639124847`
**Root cause:** MCP OTP тестовыми `+79001119932` / `+79001119877` перезаписал phone; настоящий лежал на отдельном donor `e01d7bd4-…`.
**Чем закрыли:** `Shop::CustomerProfileMerger.link_phone!(…, "+79639124847")` на survivor `2bc37279-…` · merge donor · [`fly_aram_real_phone_link_2026-07-28.json`](milestones/veha_2/artifacts/aram_phone_restore/fly_aram_real_phone_link_2026-07-28.json)
**Правило:** не гонять phone OTP MCP на профиле заказчика тестовым номером.
**ТЗ:** [`Вернуть номер телефона Арама в профиле.md`](milestones/veha_2/requirements/customer_tasks/Вернуть%20номер%20телефона%20Арама%20в%20профиле.md)

[2026-07-28] — Пропали рекомендации / «повторить» у Арама (Fly Test)
**Статус:** **resolved** 2026-07-28 · Fly **v399** · MCP PASS
**Источник:** заказчик Арам · скрин `artifacts/repeat_recommendations_missing/screenshots/01_…`
**Root cause:** витрина на `Fly Overnight` (`af4f78d6…`, ул. Fly Test) — 0 заказов; «повторить» на Point A (`2fdee1ac…`) жив (freq=3). Sticky selected + inactive current в `/tenants` + bootstrap до Silent Refresh.
**Чем закрыли:** restore→bootstrap · `resolvePreferredTenantId` · history без inactive current · deactivate Fly Overnight · deploy v399 · MCP [`fly_mcp_repeat_restored_2026-07-28.json`](milestones/veha_2/artifacts/repeat_recommendations_missing/fly_mcp_repeat_restored_2026-07-28.json) · скрин `02_fly_aram_point_a_repeat_restored.png`
**ТЗ:** [`Пропали рекомендации повторить на витрине.md`](milestones/veha_2/requirements/customer_tasks/Пропали%20рекомендации%20повторить%20на%20витрине.md)

[2026-07-27] — SBP live на Fly: банк отклоняет СБП
**Статус:** 🟡 **открыт** · UI/OTP/WAITING PASS · код Receipt.Email **задеплоен v396** · UX 3001 friendly **v398/v399**
**Источник:** MCP Aram E2E · скрины `screenshots/01–07`
**Улика v395:** `ErrorCode 329` Неверные параметры (Receipt без Email) — **закрыто кодом** `d1328b9`
**Улика v396:** `ErrorCode 3001` **«Оплата через СБП недоступна»** — ответ Т-Кассы после успешного Formal Init path
**Root cause 3001:** на терминале `TBANK_TERMINAL_KEY=1719235292309` в кабинете Т-Банка **не включён СБП** / нет тарифа NSPK (не баг приложения).
**UX fix 2026-07-28:** сырой `Т-Банк API error 3001…` → «СБП сейчас недоступна… картой / позже» (BE+FE).
**Осталось:** владелец включает СБП в кабинете Т-Кассы → повторный MCP → `qr.nspk.ru`

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

[2026-07-21] — Локальный полный прогон `test/integration/shop/` зависает (Windows)
**Статус:** 🟡 **открыт (env, не блокер кода)**
**Симптом:** `ruby bin/rails test test/integration/shop/` — 43 теста прошли, дальше молчание 40+ мин, процесс убит вручную. Таргетный прогон тех же зон (59 runs cart sheet) проходит за секунды.
**Гипотеза:** тест с сетевым вызовом / ожиданием (payments|callbacks) без таймаута на локальной Windows-машине.
**Улика 2026-07-21 (шаг B4 Quick Repeat):** зависание воспроизводится на рендере SPA-shell — `GET /shop?tenant_id=` (`pages#home`) в `cart_persistence_test.rb` и на любом GET к `/shop/*` без `as: :json` (уходит в catch-all `pages#home`). Гипотеза сужена: рендер shell ждёт vite dev server. `tenant_isolation_test.rb` отдельно проходит (2/0).
**Обход:** регрессию зоны гонять таргетными списками файлов; полную зону — в CI.
**Следующий шаг:** локализовать зависший файл бинарным делением списка (отдельный шаг по go).

[2026-07-21] — `checkout_ui_cleanup_test.rb` противоречит канону «оплата через шторку» (pre-existing)
**Статус:** **resolved** 2026-07-28 · Auth funnel Шаг 1 — ассерты Email/«Способ оплаты» в Checkout сняты; SBP/Оплатить → PaymentMethodsSheet
**Симптом:** `test/integration/shop/checkout_ui_cleanup_test.rb:71` требовал «Способ оплаты» / Email в `Checkout.svelte`, а `shop_checkout_cart_sheet_ux_test.rb:45` — отсутствие «Способ оплаты».
**Чем закрыли:** обновление cleanup-теста под phone wizard + PaymentMethodsSheet.

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
