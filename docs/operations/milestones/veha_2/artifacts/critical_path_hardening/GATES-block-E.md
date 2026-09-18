# Gates: TASK_93-E / #93 — Init / идемпотентность оплаты (shop)

Scope: повторный Init и гонки не портят живой `provider_payment_id` и не оставляют txn в failed state; HTTP в Т‑Банк **не** внутри длинной DB-txn `Shop::Api::BaseController` на happy path. Deploy = TASK_93-L (не DoD блока E).

- [ ] G1: матрица T-E1 + T-E4a — double Init не перетирает живой `provider_payment_id` (webhook остаётся валидным)
  CHECK: ruby bin/rails test test/services/shop/widget_payment_initiator_test.rb test/integration/shop/api/payment_widget_init_test.rb test/services/shop/sbp_payment_initiator_test.rb test/integration/shop/api/sbp_payment_init_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — T-E1/T-E4a ещё не в suite; baseline PASS ≠ DoD блока E; `--approve` только после GREEN с explicit double-Init asserts

- [ ] G2: матрица T-E2 + T-E4b — `RecordNotUnique` / concurrent same `client_order_uuid`; нет `InFailedSqlTransaction` из «грязной» открытой txn
  CHECK: ruby bin/rails test test/integration/shop/api/orders_controller_test.rb test/services/shop/order_creator_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — concurrent/same-uuid race + lock/rescue вне failed txn; `--approve` после GREEN с T-E2/T-E4b

- [ ] G3: узкий регресс зоны оплаты §2.3 (после GREEN)
  CHECK: ruby bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb test/services/shop/order_creator_test.rb test/controllers/shop/api/base_controller_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet — `/regress` после GREEN; не закрывать baseline без T-E*

- [ ] G4: E3 — HTTP Init/Т‑Банк вне длинной `ActiveRecord::Base.transaction` в `with_shop_tenant!` (или суженный scope); пул не держит ~15s HTTP внутри txn
  EVIDENCE: pending — SPEC/REVIEW: cite `base_controller` + Init path (widget/SBP/OrderCreator); тест или assert «no open txn around adapter HTTP» на happy path; без этого G4 ≠ met

- [ ] G5: hot-path Fly MCP Point A — повторный Init / webhook на живом pid
  EVIDENCE: abandoned — not DoD for TASK_93-E; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · re-Init не сменяет pid · webhook CONFIRMED settles

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block E; Local G1–G3 + REVIEW G4 close E

<!--
CoffeeOS TASK_93-E unlazy (pre-SPEC / pre-SBR):
- Канон: customer_tasks/TASK-93-Critical-path-hardening.md · карта TASK_93-E + DoD чата (E1–E4)
- Активный ledger сессии: docs/operations/session/GATES.md (тот же текст)
- Close E: G1–G3 met via --approve/--reverify after GREEN + /regress; G4 evidence в REVIEW; G5 abandoned until L
- 2026-09-18: --status unmet 4 + abandoned 1; --approve после GREEN (не сейчас)
-->
