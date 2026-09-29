# Gates: TASK_95 — Subscription offer guest state

Scope: Для каждого гостя backend хранит одну запись `subscription_offer_states` (not_shown / shown / dismissed / viewed_in_lk / purchased), `OfferPresentationService` считает `should_show_banner` / `has_unread_offer_in_lk` (промо 11₽ блокирует, повтор после 3 новых завершённых заказов, purchased — никогда), флаги в профиле гостя, `POST dismiss` / `POST viewed` только с сессией; без frontend / eligibility / GrowthPromo / TbankAdapter.

- [x] G1: model — таблица + статусы + одна запись на customer_id (Subtask 1–3)
  CHECK: ruby bin/rails test test/models/subscription_offer_state_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=1c11797809a685851aace147464579475b1b140b736e9797647011dbf5ad343a; exit=0; EXPECT=matched; output-sha256=5466a113061b74ce219a434f45497a51380b2c3343c13888004637d26f74b3e7; output-bytes=1617; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: service — OfferPresentationService + mark_* переходы (Subtask 4–17)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_presentation_service_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e8b7719f10a833a9c48ba846079c047feff421bd4f54d23cc138a29823cfc6e6; exit=0; EXPECT=matched; output-sha256=b9f21666470cf14d0ba7316212ff8dfacbe8312583c7b076eafec2a47bfba5c1; output-bytes=1631; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: API — флаги в GET /shop/api/profile + shown/dismiss/viewed + 401 без сессии, состояние не меняется (Subtask 18–22)
  CHECK: ruby bin/rails test test/integration/shop/api/subscription_offer_state_api_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=0a257a3a16697250ca0190ab62da1e070d81bf26cdd72e105ffec4cafb2e7478; exit=0; EXPECT=matched; output-sha256=deda8e4163b2cf5ab1606e4a4bcc3e58d4faa70892777ab845c1a06c30c42a18; output-bytes=1620; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: lifecycle + промо-приоритет end-to-end (Subtask 23–24)
  CHECK: ruby bin/rails test test/integration/shop/subscription_offer_lifecycle_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=5bef50767f606f5372c41cd4f37d4bcfa38d7659d0d299b3b00555592b1b00a1; exit=0; EXPECT=matched; output-sha256=4e7419801b4d3c8ba4835832f25c1c9fae2f12f8985cbd21f0125152144efab4; output-bytes=1615; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G5: regression — eligibility / GrowthPromo / offer settings / profile (Subtask 25)
  CHECK: ruby bin/rails test test/services/shop/subscription_offer_eligibility_test.rb test/services/payments/growth_promo_test.rb test/services/payments/growth_promo_point_campaign_test.rb test/models/subscription_offer_setting_test.rb test/integration/shop/api/profile_subscription_offer_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=961f7421dc812fc89adea601a207b2817bc27e9730390d523b917390be7c6e41; exit=0; EXPECT=matched; output-sha256=1a4c40038891143063c4547fc800e3d9394df480b32ddc1bfb3bb786d9c03f5a; output-bytes=1660; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G6: regression — покупка подписки + Shop API подписок (mark_purchased side-effect)
  CHECK: ruby bin/rails test test/services/subscriptions/purchase_service_test.rb test/services/subscriptions/confirm_payment_service_test.rb test/integration/shop/api/subscriptions_api_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=ceda1b97a9ed0f76facdc3d57cba3d012930f3333edba7c4b1aca139c779ac74; exit=0; EXPECT=matched; output-sha256=5c76905bda17454d87680966f27cacd29af7bc7ff94f0e7099302fa7ded7cdb0; output-bytes=1632; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G7: hot-path Fly MCP Point A — профиль отдаёт флаги, dismiss/viewed 401 без сессии, витрина/корзина не сломаны
  EVIDENCE: pending — 2026-09-29 не задеплоено (GREEN `42b61e1c` только local); Fly MCP после deploy по апруву

<!--
CoffeeOS TASK_95 unlazy:
- G1–G4 — новые тест-файлы (RED на /sbr); пути уточнить на /spec, при смене — обновить CHECK и заново --approve.
- G5–G6 — существующие файлы, должны быть зелёными до и после.
- G7 manual; Fly после deploy (апрув).
- Вопросы к /spec: `profile/config` из ТЗ = `/shop/api/profile` (per-customer) или `/shop/api/config` (tenant)?; eligibility уже учитывает GrowthPromo; purchased «на любой точке сети» vs RLS по tenant; `npx tsc` не применим.
-->
