# Gates: TASK_93-A / #93 — Critical path hardening (деньги ↔ заказ)

Scope: Банк CONFIRMED → всегда `payment.succeeded` + `order.accepted`; склад/рецепт не откатывает оплату (A1–A6); blank Amount / cancelled|closed+succeeded — не silent. Deploy = TASK_93-L (не DoD блока A).

- [x] G1: матрица T-A1…T-A6 (updater + deduction + stock flow + callbacks)
  CHECK: ruby bin/rails test test/services/callbacks/payment_status_updater_test.rb test/services/inventory/order_recipe_deduction_test.rb test/jobs/payments/tbank_callback_job_test.rb test/controllers/callbacks/tbank_controller_test.rb test/integration/block_f_stock_flow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=336b3aee5b1b3cb273d0b207f8df604c901ccfa4d3dacfc39c6ea05cb51b2497; exit=0; EXPECT=matched; output-sha256=1b6e8c5f0da06c4cf42046b803c15c8929d87d169c18349ba3280be92a8dee66; output-bytes=1651; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: зона payments / callbacks / jobs (регресс после GREEN)
  CHECK: ruby bin/rails test test/services/payments/ test/services/callbacks/ test/jobs/payments/
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=6f31b49d5e02303878e4dd3c08d66dfc9eb4835df9f89e1aac06198d6a53aa99; exit=0; EXPECT=matched; output-sha256=6024cb9ae91652b860c840bfa3de63da31c6af4799f7a2902faa5d11b1ed33cd; output-bytes=1755; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: Amount blank / mismatch visibility (A4)
  CHECK: ruby bin/rails test test/services/payments/tbank_adapter_test.rb test/services/payments/tbank_payment_sync_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=7d440ba29731d2be7342d93f891a815bfd90f9bf80aff9d301b463e2da3c2b0f; exit=0; EXPECT=matched; output-sha256=d3961734336f81c518f30a94cb645f1f2b9b79900d3f28d6f301bd6dc018cef8; output-bytes=1654; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G4: hot-path Fly MCP Point A — CONFIRMED → barista sees accepted (даже без склада)
  EVIDENCE: abandoned — not DoD for TASK_93-A; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · webhook/GetState → payment succeeded + order accepted · stock alert без rollback оплаты

ABANDON: G4 Fly MCP Point A is TASK_93-L DoD, not block A; Local G1–G3 close A

<!--
CoffeeOS TASK_93-A unlazy (post-regress):
- 2026-09-18 --approve/--reverify: G1–G3 met; G4 abandoned until L
- Durable todo: TODO-block-A.md · Next: /review
-->
