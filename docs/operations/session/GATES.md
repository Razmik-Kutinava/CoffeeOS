# Gates: TASK_93-E / #93 — Init / идемпотентность оплаты (shop)

Scope: повторный Init и гонки не портят живой `provider_payment_id` и не оставляют txn в failed state; HTTP в Т‑Банк **не** внутри длинной DB-txn `Shop::Api::BaseController` на happy path. Deploy = TASK_93-L (не DoD блока E).

- [x] G1: матрица T-E1 + T-E4a — double Init не перетирает живой `provider_payment_id` (webhook остаётся валидным)
  CHECK: ruby bin/rails test test/services/shop/widget_payment_initiator_test.rb test/integration/shop/api/payment_widget_init_test.rb test/services/shop/sbp_payment_initiator_test.rb test/integration/shop/api/sbp_payment_init_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=4514f710cf42561fb0840798d8b8c679ef46e66d202058ea1cb12eb73317cf80; exit=0; EXPECT=matched; output-sha256=a23e665f2a65ecf527d8bbc155be52358f48d80859633e22c33a02a2145edfea; output-bytes=1645; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: матрица T-E2 + T-E4b — `RecordNotUnique` / concurrent same `client_order_uuid`; нет `InFailedSqlTransaction` из «грязной» открытой txn
  CHECK: ruby bin/rails test test/integration/shop/api/orders_controller_test.rb test/services/shop/order_creator_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=ce0e4d885f2673247e04c486e845604776a880774331dd06939e782cd3cd291c; exit=0; EXPECT=matched; output-sha256=85037603fe2455c0df6a1cde134323aa8399f53ef9f9133619d0da0cb55a2431; output-bytes=1656; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: узкий регресс зоны оплаты §2.3 (после GREEN)
  CHECK: ruby bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb test/services/shop/order_creator_test.rb test/controllers/shop/api/base_controller_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=6d253e30a83e0653df019026eebfb756cbdd040b4a6b9c73c8d13800a3d9ab47; exit=0; EXPECT=matched; output-sha256=16ef4398fd9754fdcc762a091db2e2d423df23c8dcb38c09bee47e520c6497c9; output-bytes=1646; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: E3 — HTTP Init/Т‑Банк вне длинной `ActiveRecord::Base.transaction` в `with_shop_tenant!` (или суженный scope); пул не держит ~15s HTTP внутри txn
  EVIDENCE: met — cite `app/controllers/shop/api/base_controller.rb` session `SET app.current_tenant_id` + ensure RESET (no AR.transaction around yield); T-E3a `ar_open_transactions <= 1` in `base_controller_test`; GREEN `2eb22c71`

- [ ] G5: hot-path Fly MCP Point A — повторный Init / webhook на живом pid
  EVIDENCE: abandoned — not DoD for TASK_93-E; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · re-Init не сменяет pid · webhook CONFIRMED settles

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block E; Local G1–G3 + G4 cite close E

<!--
CoffeeOS TASK_93-E unlazy (post-GREEN / post-regress):
- Канон: customer_tasks/TASK-93-Critical-path-hardening.md · карта TASK_93-E
- Зеркало: artifacts/critical_path_hardening/GATES-block-E.md
- Параллельные: GATES-block-A/B/C/D/K.md (не затирать)
- Close E: G1–G3 met via --approve/--reverify; G4 cite met; G5 abandoned until L
- 2026-09-18: regress 85/0 · approve G1–G3 next
-->
