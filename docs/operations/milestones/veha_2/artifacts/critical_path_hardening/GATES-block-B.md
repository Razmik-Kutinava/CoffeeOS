# Gates: TASK_93-B / #93 — Checkout identity (phone vs email)

Scope: UI «можно платить» ≡ бэкенд принимает заказ/оплату без 422 email при `phone_verified` (канон phone-first R1–R5); один identity на orders / new_card / one_click / SBP create. Deploy = TASK_93-L (не DoD блока B).

- [x] G1: T-B2a..f — OrderCreator + RecurrentOrderCreator (phone-only / email-only / neither)
  CHECK: ruby bin/rails test test/services/shop/order_creator_test.rb test/services/shop/recurrent_order_creator_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: GREEN `2213cbeb` — zone run 47/0 incl. order_creator + recurrent; phone_verified без email → order

- [x] G2: T-B5a..e + T-B4a — integration checkout_identity (orders / cards / one_click ownership)
  CHECK: ruby bin/rails test test/integration/shop/api/checkout_identity_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: GREEN `2213cbeb` — checkout_identity_test PASS (OTP session bind); phone POST 200; neither 422; ownership 422

- [x] G3: зона shop pay-paths (ТЗ §8 + new_card)
  CHECK: ruby bin/rails test test/integration/shop/api/email_otp_checkout_test.rb test/integration/shop/shop_one_click_payment_step4_test.rb test/integration/shop/shop_new_card_payment_step2_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: GREEN zone 47/0 PASS (email_otp + one_click + new_card included)

- [x] G4: T-B3 UI identityReady ≡ R1–R3 (phone-first, не требует emailVerified для Pay)
  EVIDENCE: GREEN — `const identityReady = $derived(phoneVerified || emailVerified)` in Checkout.svelte; phone-auth slim sheet only when neither verified

- [ ] G5: hot-path Fly MCP Point A — phone Callcheck → Pay → order без 422 email
  EVIDENCE: abandoned — not DoD for TASK_93-B; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · phone_verified → POST /orders 2xx без «Подтвердите email»

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block B; Local G1–G4 close B pending `/regress` reverify

<!--
CoffeeOS TASK_93-B unlazy:
- ТЗ: customer_tasks/TASK-93-B-Checkout-identity.md
- Зеркало: artifacts/critical_path_hardening/GATES-block-B.md (+ session/GATES.md пока этот чат активен)
- A/C/D: GATES-block-A.md · GATES-block-C.md · GATES-block-D.md
- 2026-09-18 --approve: G3 met; G1/G2 unmet (missing tests); G4 manual; G5 abandoned
-->
