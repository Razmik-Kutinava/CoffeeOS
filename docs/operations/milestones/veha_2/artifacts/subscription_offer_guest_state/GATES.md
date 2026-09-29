# Gates: TASK_95 — Subscription offer guest state

Scope: Для каждого гостя backend хранит одну запись `subscription_offer_states` (not_shown / shown / dismissed / viewed_in_lk / purchased), `OfferPresentationService` считает `should_show_banner` / `has_unread_offer_in_lk` (промо 11₽ блокирует, повтор после 3 новых завершённых заказов, purchased — никогда), флаги в профиле гостя, `POST dismiss` / `POST viewed` только с сессией; без frontend / eligibility / GrowthPromo / TbankAdapter.

- [ ] G1: model — таблица + статусы + одна запись на customer_id (Subtask 1–3)
  CHECK: ruby bin/rails test test/models/subscription_offer_state_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [ ] G2: service — OfferPresentationService + mark_* переходы (Subtask 4–17)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_presentation_service_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [ ] G3: API — флаги в профиле + dismiss/viewed + 401 без сессии, состояние не меняется (Subtask 18–22)
  CHECK: ruby bin/rails test test/integration/shop/api/subscription_offer_state_api_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [ ] G4: lifecycle + промо-приоритет end-to-end (Subtask 23–24)
  CHECK: ruby bin/rails test test/integration/shop/subscription_offer_lifecycle_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [x] G5: regression — eligibility / GrowthPromo / offer settings / profile (Subtask 25)
  CHECK: ruby bin/rails test test/services/shop/subscription_offer_eligibility_test.rb test/services/payments/growth_promo_test.rb test/services/payments/growth_promo_point_campaign_test.rb test/models/subscription_offer_setting_test.rb test/integration/shop/api/profile_subscription_offer_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=961f7421dc812fc89adea601a207b2817bc27e9730390d523b917390be7c6e41; exit=0; EXPECT=matched; output-sha256=375013ca0deef0d6f07c5a24d54c1a41d8d1fb5c2edc78aa6188f8a6c79ed261; output-bytes=1661; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G6: regression — покупка подписки + Shop API подписок (mark_purchased side-effect)
  CHECK: ruby bin/rails test test/services/subscriptions/purchase_service_test.rb test/services/subscriptions/confirm_payment_service_test.rb test/integration/shop/api/subscriptions_api_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=ceda1b97a9ed0f76facdc3d57cba3d012930f3333edba7c4b1aca139c779ac74; exit=0; EXPECT=matched; output-sha256=f64687babc72fff64b62522c95dd0c65d7a64d2b5e186d3b52c2f8b6fc16dc99; output-bytes=1632; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G7: hot-path Fly MCP Point A — профиль отдаёт флаги, dismiss/viewed 401 без сессии, витрина/корзина не сломаны
  EVIDENCE: pending (после deploy по апруву)

<!--
CoffeeOS TASK_95 unlazy:
- G1–G4 — новые тест-файлы (RED на /sbr); пути уточнить на /spec, при смене — обновить CHECK и заново --approve.
- G5–G6 — существующие файлы, должны быть зелёными до и после.
- G7 manual; Fly после deploy (апрув).
- Вопросы к /spec: `profile/config` из ТЗ = `/shop/api/profile` (per-customer) или `/shop/api/config` (tenant)?; eligibility уже учитывает GrowthPromo; purchased «на любой точке сети» vs RLS по tenant; `npx tsc` не применим.
-->
