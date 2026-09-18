# Gates: TASK_93-A / #93 — Critical path hardening (деньги ↔ заказ)

Scope: Банк CONFIRMED → всегда `payment.succeeded` + `order.accepted`; склад/рецепт не откатывает оплату (A1–A6); blank Amount / cancelled|closed+succeeded — не silent. Deploy = TASK_93-L (не DoD блока A).

- [ ] G1: матрица T-A1…T-A6 (updater + deduction + stock flow + callbacks)
  CHECK: ruby bin/rails test test/services/callbacks/payment_status_updater_test.rb test/services/inventory/order_recipe_deduction_test.rb test/jobs/payments/tbank_callback_job_test.rb test/controllers/callbacks/tbank_controller_test.rb test/integration/block_f_stock_flow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — RED/GREEN A1–A6; после GREEN добавить новые A5/A6 файлы в CHECK если появятся

- [ ] G2: зона payments / callbacks / jobs (регресс после GREEN)
  CHECK: ruby bin/rails test test/services/payments/ test/services/callbacks/ test/jobs/payments/
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — `/regress` блок A

- [ ] G3: Amount blank / mismatch visibility (A4)
  CHECK: ruby bin/rails test test/services/payments/tbank_adapter_test.rb test/services/payments/tbank_payment_sync_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — T-A4a/b; report/audit при blank/mismatch; платёж не succeeded при mismatch

- [ ] G4: hot-path Fly MCP Point A — CONFIRMED → barista sees accepted (даже без склада)
  EVIDENCE: abandoned — not DoD for TASK_93-A; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · webhook/GetState → payment succeeded + order accepted · stock alert без rollback оплаты

ABANDON: G4 Fly MCP Point A is TASK_93-L DoD, not block A; Local G1–G3 close A

<!--
CoffeeOS TASK_93-A unlazy (pre-SPEC / pre-SBR):
- Канон ТЗ: customer_tasks/TASK-93-Critical-path-hardening.md §7–9
- Зеркало ledger: artifacts/critical_path_hardening/GATES.md
- Close A: G1–G3 met via --approve/--reverify after GREEN + /regress; G4 abandoned until L
-->
