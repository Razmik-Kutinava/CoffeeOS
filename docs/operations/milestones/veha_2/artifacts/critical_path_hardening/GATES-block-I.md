# Gates: TASK_93-I / #93 — OTP / rate limit / auth abuse

Scope: Rack::Attack shared Redis store на multi-machine Fly; throttle `verify_sms` (+ legacy/email по SPEC); OTP SMS 6 digits; short-link rule `shop/order_short_link/ip` через shared store **без** дубля. Deploy Redis / secret Fly = TASK_93-L (не DoD блока I).

- [x] G1: матрица T-I1 — shared Attack store (не MemoryStore на prod/FLY)
  CHECK: ruby bin/rails test test/integration/rack_attack_store_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=5bc13eb17bbac14b64f8f6da7d2cd603d876419281c6fc8e777458d8b69a15d5; exit=0; EXPECT=matched; output-sha256=57fb52e652c902c11099d0aae179d46cd5075129641edc0d15c649a67b3c10ee; output-bytes=1676; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: матрица T-I2 — throttle verify_sms (+ legacy)
  CHECK: ruby bin/rails test test/integration/rack_attack_otp_verify_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e82d0f791bfa698afc3ae11076d1cd1b0880808b4698f6b6177e8f044feb81ec; exit=0; EXPECT=matched; output-sha256=6886018fcb3733f2820a67c1ef2b9ea35305b7071e50af81f0cd88a2192734dc; output-bytes=1613; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: матрица T-I3 — SMS OTP 6 digits (+ UI)
  CHECK: ruby bin/rails test test/services/shop/phone_otp_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=2116c6501200adaa5eba5a241d92276a619f187183d2bfdcdba2d57ee92a9b8d; exit=0; EXPECT=matched; output-sha256=b223288e5bd6bcb4a7102df3b1f7b250c6bc3f0394c388a85945a575db8e50e3; output-bytes=1622; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: матрица T-I4 + узкий регресс §8 (после GREEN)
  CHECK: ruby bin/rails test test/integration/rack_attack_order_short_link_test.rb test/integration/shop/order_short_links_test.rb test/integration/rack_attack_otp_verify_test.rb test/services/shop/phone_otp_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e4cae0a37b0735f4f569f5f398e5575605f97fe0261afd5649f74af3b72dac59; exit=0; EXPECT=matched; output-sha256=37a9d5f3acb08023a567e58fae8a3a1a069847b9f002ee7ad7d2dd2c7424b83c; output-bytes=1639; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: Fly Redis attach / secret `REDIS_URL` + hot-path MCP Point A
  EVIDENCE: abandoned — not DoD for TASK_93-I; reopen in TASK_93-L; runbook `REDIS_RACK_ATTACK.md`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789`

ABANDON: G5 Fly Redis secret + MCP Point A is TASK_93-L DoD, not block I; Local G1–G4 close I

<!--
CoffeeOS TASK_93-I:
- GREEN c14f5202 · Entire 01M2T0ABAE2SFY486XQCJTW147 (backfill 16fbcad4)
- 2026-09-18 /regress: matrix 23/0 (1 skip T-I1b) · zone 27/0 · G1–G4 met · G5→L
-->
