# Gates: TASK_93-J / #93 — Push / уведомления / worker

Scope: смена статуса / webhook **не** ждут APNs/FCM; FCM OAuth cache + dead tokens; cascade `wait = SMS_GRACE + 5s` без race grace; runbook Solid Queue / `SOLID_QUEUE_IN_PUMA`. Deploy worker Fly = TASK_93-L (не DoD блока J). UI WebPush (#90), SMS текст (C), Redis Attack (I), склад (A) — out of scope.

- [x] G1: матрица T-J1 — async APNs/Wallet/FCM; PassUpdater **не** sync из broadcaster; push вне `payment.with_lock`
  CHECK: ruby bin/rails test test/services/barista/order_status_update_service_test.rb test/services/shop/guest_order_broadcaster_test.rb test/services/callbacks/payment_status_updater_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=a73d3daf47b0c5fc2eb35b9316ae783a636ba784485bab8ade617d616febe84a; exit=0; EXPECT=matched; output-sha256=459d9c5a21db9eeb6bda20613a54a7dd951f974d9ab82cde087ef0560bfb1b79; output-bytes=1642; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: матрица T-J2 — FCM OAuth cache + UNREGISTERED clears token
  CHECK: ruby bin/rails test test/services/shop/fcm_client_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=ebd753a372a9d9de6fe1698901e312b832fbc66f8d716c1fda4897e455df7706; exit=0; EXPECT=matched; output-sha256=6b22f2740ad774054a396c2885500b0593c6b340a3957c3cff2e3073cc12a74a; output-bytes=1619; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: матрица T-J3 — cascade wait **>** SMS_GRACE (BUFFER +5s); presence grace / SMS skip
  CHECK: ruby bin/rails test test/jobs/shop/order_ready_cascade_job_test.rb test/services/shop/order_ready_presence_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=c9da170518e7b35ae00f7bab88a0436e5a6e366a471cd325b1f65627849b349d; exit=0; EXPECT=matched; output-sha256=ba68b8012ebdfa3fd56cfcd7b3af18af0101c9254dd85117b94ddced8b8e3771; output-bytes=1634; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: J4 runbook + tbank/cascade queue contract + узкий регресс §8 (после GREEN)
  CHECK: ruby bin/rails test test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb test/controllers/callbacks/tbank_controller_test.rb test/services/shop/order_status_push_notifier_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=f4f3ad7396b808a7630a7409f856b850f2f964f4ff42247acdb3ab486d724e37; exit=0; EXPECT=matched; output-sha256=c2adbd324c3f2104c90f11d0ad667c050a1f75398b8676d18f4550d430df0360; output-bytes=1663; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — worker / push / cascade на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-J; reopen in TASK_93-L (включить/проверить worker или Puma plugin live); artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · status change без sync APNs latency · cascade SMS after grace+buffer · queue jobs run

ABANDON: G5 Fly worker/MCP Point A is TASK_93-L DoD, not block J; Local G1–G3 + G4 after /regress close J; runbook docs in J (T-J4a)

<!--
CoffeeOS TASK_93-J unlazy:
- Close J: G1–G4 met via --approve/--reverify after /regress; G5 abandoned until L
- 2026-09-18 /regress: 87/0 · SOLID_QUEUE_FLY.md present · Next /review
-->
