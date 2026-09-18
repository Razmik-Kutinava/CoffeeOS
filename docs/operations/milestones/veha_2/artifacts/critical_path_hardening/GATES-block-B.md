# Gates: TASK_93-B / #93 — Checkout identity (phone vs email)

Scope: UI «можно платить» ≡ бэкенд принимает заказ/оплату без 422 email при `phone_verified` (канон phone-first R1–R5); один identity на orders / new_card / one_click / SBP create. Deploy = TASK_93-L (не DoD блока B).

- [ ] G1: T-B2a..f — OrderCreator + RecurrentOrderCreator (phone-only / email-only / neither)
  CHECK: ruby bin/rails test test/services/shop/order_creator_test.rb test/services/shop/recurrent_order_creator_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — `recurrent_order_creator_test.rb` отсутствует (InvalidTestError); T-B2a ещё не написан; создать на `/sbr` RED

- [ ] G2: T-B5a..e + T-B4a — integration checkout_identity (orders / cards / one_click ownership)
  CHECK: ruby bin/rails test test/integration/shop/api/checkout_identity_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — файла нет (InvalidTestError); создать на RED; phone → 2xx без «Подтвердите email»; no identity → 422; чужая карта → ownership 422

- [x] G3: зона shop pay-paths (ТЗ §8 + new_card)
  CHECK: ruby bin/rails test test/integration/shop/api/email_otp_checkout_test.rb test/integration/shop/shop_one_click_payment_step4_test.rb test/integration/shop/shop_new_card_payment_step2_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; exit=0; EXPECT=matched; output-sha256=ece15702826475523ee350cb7709330b105562f54f2b8e67897a039046c63b65 — baseline PASS до изменений B

- [ ] G4: T-B3 UI identityReady ≡ R1–R3 (phone-first, не требует emailVerified для Pay)
  EVIDENCE: pending — manual/REVIEW: grep `identityReady` в Checkout.svelte ≡ phoneVerified || emailVerified; без фейкового emailVerified; цитата в GREEN-отчёте

- [ ] G5: hot-path Fly MCP Point A — phone Callcheck → Pay → order без 422 email
  EVIDENCE: abandoned — not DoD for TASK_93-B; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · phone_verified → POST /orders 2xx без «Подтвердите email»

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block B; Local G1–G3 + REVIEW G4 close B

<!--
CoffeeOS TASK_93-B unlazy:
- ТЗ: customer_tasks/TASK-93-B-Checkout-identity.md
- Зеркало: artifacts/critical_path_hardening/GATES-block-B.md (+ session/GATES.md пока этот чат активен)
- A/C/D: GATES-block-A.md · GATES-block-C.md · GATES-block-D.md
- 2026-09-18 --approve: G3 met; G1/G2 unmet (missing tests); G4 manual; G5 abandoned
-->
