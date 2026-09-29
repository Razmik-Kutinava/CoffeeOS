# Gates: TASK_95 — Subscription offer guest state

Scope: Для каждого гостя backend хранит одну запись `subscription_offer_states` (not_shown / shown / dismissed / viewed_in_lk / purchased), `OfferPresentationService` считает `should_show_banner` / `has_unread_offer_in_lk` (промо 11₽ блокирует, повтор после 3 новых завершённых заказов, purchased — никогда), флаги в профиле гостя, `POST dismiss` / `POST viewed` только с сессией; без frontend / eligibility / GrowthPromo / TbankAdapter.

- [x] G1: model — таблица + статусы + одна запись на customer_id (Subtask 1–3)
  CHECK: ruby bin/rails test test/models/subscription_offer_state_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=1c11797809a685851aace147464579475b1b140b736e9797647011dbf5ad343a; exit=0; EXPECT=matched; output-sha256=7ae8166dd3754bbcd6aafd50edc3e32875fc90724c7fb958e34e7fc8e0554768; output-bytes=1617; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: service — OfferPresentationService + mark_* переходы (Subtask 4–17)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_presentation_service_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e8b7719f10a833a9c48ba846079c047feff421bd4f54d23cc138a29823cfc6e6; exit=0; EXPECT=matched; output-sha256=00c4a1889cb795b9f162cdb36955e5c2d729fecff73447c2cb9a82d4c827f88b; output-bytes=1630; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: API — флаги в GET /shop/api/profile + shown/dismiss/viewed + 401 без сессии, состояние не меняется (Subtask 18–22)
  CHECK: ruby bin/rails test test/integration/shop/api/subscription_offer_state_api_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=0a257a3a16697250ca0190ab62da1e070d81bf26cdd72e105ffec4cafb2e7478; exit=0; EXPECT=matched; output-sha256=e00ac640d07afb245b9169b645653471441ca40d67fe2f7aa62ab85634bec4bb; output-bytes=1621; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: lifecycle + промо-приоритет end-to-end (Subtask 23–24)
  CHECK: ruby bin/rails test test/integration/shop/subscription_offer_lifecycle_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=5bef50767f606f5372c41cd4f37d4bcfa38d7659d0d299b3b00555592b1b00a1; exit=0; EXPECT=matched; output-sha256=48e743c2083cd479574b007ddea6db938e8d74fd45dc4edf7c4526ce81f478e7; output-bytes=1615; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G5: regression — eligibility / GrowthPromo / offer settings / profile (Subtask 25)
  CHECK: ruby bin/rails test test/services/shop/subscription_offer_eligibility_test.rb test/services/payments/growth_promo_test.rb test/services/payments/growth_promo_point_campaign_test.rb test/models/subscription_offer_setting_test.rb test/integration/shop/api/profile_subscription_offer_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=961f7421dc812fc89adea601a207b2817bc27e9730390d523b917390be7c6e41; exit=0; EXPECT=matched; output-sha256=ad0ebd89ee6e5fa0caa5397968e899672c5581ecf225435ebe7259fc7fd1d038; output-bytes=1660; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G6: regression — покупка подписки + Shop API подписок (mark_purchased side-effect)
  CHECK: ruby bin/rails test test/services/subscriptions/purchase_service_test.rb test/services/subscriptions/confirm_payment_service_test.rb test/integration/shop/api/subscriptions_api_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=ceda1b97a9ed0f76facdc3d57cba3d012930f3333edba7c4b1aca139c779ac74; exit=0; EXPECT=matched; output-sha256=07da816a3a97f1c6da38293c5ee6596d8a7065b1dd3b004650889f1b54a48661; output-bytes=1632; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G7: hot-path Fly MCP Point A — профиль отдаёт флаги, dismiss/viewed 401 без сессии, витрина/корзина не сломаны
  EVIDENCE: pending (после deploy по апруву)

<!--
CoffeeOS TASK_95 unlazy:
- G1–G4 — новые тест-файлы (RED на /sbr); пути уточнить на /spec, при смене — обновить CHECK и заново --approve.
- G5–G6 — существующие файлы, должны быть зелёными до и после.
- G7 manual; Fly после deploy (апрув).
- Вопросы к /spec: `profile/config` из ТЗ = `/shop/api/profile` (per-customer) или `/shop/api/config` (tenant)?; eligibility уже учитывает GrowthPromo; purchased «на любой точке сети» vs RLS по tenant; `npx tsc` не применим.
-->
