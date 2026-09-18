# Gates: TASK_93-G / #93 — Tenant GUC / RLS / schema

Scope: staff `SET LOCAL` реально внутри txn (как Shop API); must-have policies/triggers воспроизводимы после schema load (`ensure_all` **или** `structure.sql`); city switcher без голого `row_security = off`; `ensure_tenant_id` строго по SPEC. Deploy/migrate Fly = TASK_93-L (не DoD блока G).

- [x] G1: матрица T-G1 — barista/manager/prep `SET LOCAL` только внутри open transaction
  CHECK: ruby bin/rails test test/integration/staff_pg_context_transaction_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=82fc22060d6cbe6811590971ac62cb1ca9c86a54e5400d1639bce6a8c60398f5; exit=0; EXPECT=matched; output-sha256=ee8606f9a5fae60aafbce3e6ebff72aaa40fac3453c6df42e271c82d45c87010; output-bytes=1615; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: матрица T-G2 + T-G3 + T-G4 — инвентарь + ensure_all/structure + свежая БД (policies/triggers)
  CHECK: ruby bin/rails test test/integration/rls_tenant_isolation_test.rb test/integration/db_triggers_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=2a5917b1ee4b229715b150e9705ba3460af6210c1288bd455689b54508a52ab6; exit=0; EXPECT=matched; output-sha256=736fe7eb21f76425698639f170e8a340a8d01a66afa5515c21c50dc012db2068; output-bytes=1625; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: матрица T-G5 — CustomerTenantHistory без `row_security = off`; city peers + last_ordered
  CHECK: ruby bin/rails test test/services/shop/customer_tenant_history_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=48d50d59cd392baaf50c0c9e062928e25001f0c212173530a521c626447274ca; exit=0; EXPECT=matched; output-sha256=436e4583d5c78b06de8dbd885165a6b1bbe3d5f75d38885917c27a7821b9e816; output-bytes=1621; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: матрица T-G6 + узкий регресс §8 (после GREEN)
  CHECK: ruby bin/rails test test/integration/rls_tenant_isolation_test.rb test/integration/db_triggers_test.rb test/services/shop/customer_tenant_history_test.rb test/integration/staff_pg_context_transaction_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=c4946f8274a71f0f89da32c283370d8222cd51fcd9dca6a93785003e47942f69; exit=0; EXPECT=matched; output-sha256=84358d05b5e692183c11d6ac68c906d19d77ada6a60a440d998d5463fdbc8355; output-bytes=1631; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: Fly MCP / migrate ensure на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-G; reopen in TASK_93-L after deploy апрув; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · staff GUC в txn · `db:rls:ensure` / triggers на Fly · city switcher peers

ABANDON: G5 Fly ensure/MCP is TASK_93-L DoD, not block G; Local G1–G4 after /regress close G

<!--
CoffeeOS TASK_93-G:
- Close G local: G1–G4 met; G5 abandoned until L
- GREEN `7c34314a` · Entire `01M2SSXE54SV4CM341NHXR0SCE`
- 2026-09-18 regress: 22/0
-->
