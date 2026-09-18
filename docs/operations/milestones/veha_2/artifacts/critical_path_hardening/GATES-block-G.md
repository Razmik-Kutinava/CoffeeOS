# Gates: TASK_93-G / #93 — Tenant GUC / RLS / schema

Scope: staff `SET LOCAL` реально внутри txn (как Shop API); must-have policies/triggers воспроизводимы после schema load (`ensure_all` **или** `structure.sql`); city switcher без голого `row_security = off`; `ensure_tenant_id` строго по SPEC. Deploy/migrate Fly = TASK_93-L (не DoD блока G).

- [ ] G1: матрица T-G1 — barista/manager/prep `SET LOCAL` только внутри open transaction
  CHECK: ruby bin/rails test test/integration/staff_pg_context_transaction_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — файла/кейсов T-G1a/b/c может не быть; baseline без txn-wrap ≠ DoD; `--approve` только после GREEN: `transaction_open?` при SET LOCAL · GUC `app.current_tenant_id` читается в том же request · вне txn no-op/forbid (T-G1c)

- [ ] G2: матрица T-G2 + T-G3 + T-G4 — инвентарь + ensure_all/structure + свежая БД (policies/triggers)
  CHECK: ruby bin/rails test test/integration/rls_tenant_isolation_test.rb test/integration/db_triggers_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — нужен `RLS_PG_INVENTORY.md` (T-G2a) · asserts `pg_policies` / `trg_generate_order_number`+`trg_auto_deduct_ingredients`+`trg_auto_stop_list` (T-G2b/c · T-G4) · `DatabaseTriggers.ensure_all!` (или R3-A structure) не «только order_number» (T-G3); `--approve` после GREEN + inventory file in git

- [ ] G3: матрица T-G5 — CustomerTenantHistory без `row_security = off`; city peers + last_ordered
  CHECK: ruby bin/rails test test/services/shop/customer_tenant_history_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — T-G5b grep/assert no `row_security = off` · T-G5a peers same city · T-G5c изоляция без city GUC · T-G5d last_ordered; `--approve` после GREEN через `Rls::GucContext.with_shop_city_lookup` (имя GUC — SPEC)

- [ ] G4: матрица T-G6 + узкий регресс §8 (после GREEN)
  CHECK: ruby bin/rails test test/integration/rls_tenant_isolation_test.rb test/integration/db_triggers_test.rb test/services/shop/customer_tenant_history_test.rb test/integration/staff_pg_context_transaction_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet — `/regress` после GREEN; T-G6a production-like raise на blank tenant_id · T-G6b test-env поведение = SPEC; без G1+G3 (продукт) + T-G5 блок не закрыт

- [ ] G5: Fly MCP / migrate ensure на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-G; reopen in TASK_93-L after deploy апрув; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · staff GUC в txn · `db:rls:ensure` / triggers на Fly · city switcher peers

ABANDON: G5 Fly ensure/MCP is TASK_93-L DoD, not block G; Local G1–G3 + G4 after /regress close G

<!--
CoffeeOS TASK_93-G unlazy (pre-SPEC / pre-SBR):
- Канон: customer_tasks/TASK-93-Critical-path-hardening.md · блок G (R1–R6) + DoD чата G1–G6
- Активный ledger сессии: docs/operations/session/GATES.md (тот же текст)
- Close G: G1–G3 met via --approve/--reverify after GREEN; G4 после /regress; G5 abandoned until L
- SPEC обязателен: R3-A vs R3-B · must-have inventory · city GUC name · ensure_tenant_id в test
- Без T-G1a + T-G3a + T-G5b блок не закрыт
- 2026-09-18: --status unmet 4 + abandoned 1; --approve после GREEN (не сейчас)
-->
