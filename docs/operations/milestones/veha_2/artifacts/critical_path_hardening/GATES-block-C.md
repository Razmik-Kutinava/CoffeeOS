# Gates: TASK_93-C / #93 — SMS «заказ готов» + short link

Scope: SMS URL на живом host приложения; `/o/:hash` → bind + redirect; HostAuthorization не режет; throttle brute MAC; TTL токена. Deploy/DNS = TASK_93-L (не DoD блока C).

- [x] G1: T-C1a..c — SMS host canon (не мёртвый codeblack.xyz) + длина ≤70
  CHECK: ruby bin/rails test test/services/shop/order_ready_sms_link_test.rb test/services/shop/order_ready_paid_notifier_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=f8273175e65cdf93a5f2971bb4fa220a67328830ceee440fd24a3d11d2a0b97a; exit=0; EXPECT=matched; output-sha256=8f7b5b5f96c35fc65eb2facbbd31f5e552f799e37b68b5250b5f986d5a8b16bb; output-bytes=1626; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: T-C2c + T-C3a..d — `/o/:hash` Host OK + redirect/bind + forge 404
  CHECK: ruby bin/rails test test/integration/shop/order_short_links_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=9e3844426cc051f197ebd192ad01a740310f975a9653d7919141542a6da63a09; exit=0; EXPECT=matched; output-sha256=60af5cfbea78d85f61e6fe000a4e6063f04d20549bea575180c6256d15cb8f5f; output-bytes=1618; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: T-C4a/b — Rack::Attack throttle GET `/o/`
  CHECK: ruby bin/rails test test/integration/rack_attack_order_short_link_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=5b0d96c2f4ada269c196771a0e1638202f9ee85ce364489897e4106d3592c00b; exit=0; EXPECT=matched; output-sha256=e576acb6f807175b3c9b81bf2960345473a6994a75e9d11b223e0ec44be6ce0c; output-bytes=1615; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: T-C5a/c (+ T-C5b если one-time) — TTL short-link token
  CHECK: ruby bin/rails test test/integration/shop/order_short_links_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=9e3844426cc051f197ebd192ad01a740310f975a9653d7919141542a6da63a09; exit=0; EXPECT=matched; output-sha256=4ece86c5fc8398d55035b7e7d8e089a2a6ec390ed5ab771581958eecd7d82065; output-bytes=1617; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G5: зона #82 / notifications regress (notifier + short links)
  CHECK: ruby bin/rails test test/services/shop/order_ready_paid_notifier_test.rb test/integration/shop/order_short_links_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=45080ae724431dd90941b01c32e8a1ed345fc83ace97cb45bb0f6029999e6953; exit=0; EXPECT=matched; output-sha256=d690a73f104fc5cc08dd0b4efd9a968be1f8569e77a1da3b0f974b5796c4f721; output-bytes=1621; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G6: hot-path Fly MCP Point A — SMS tap → order status sheet
  EVIDENCE: abandoned — not DoD for TASK_93-C; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · SMS/test link → `/o/{hash}` → sheet visible

ABANDON: G6 Fly MCP Point A is TASK_93-L DoD, not block C; Local G1–G5 close C (REVIEW table C1–C5)

<!--
CoffeeOS TASK_93-C unlazy (post-/start / pre-SPEC):
- Канон брифа: чат TASK_93-C §3–9 (C1–C5); зонтик customer_tasks/TASK-93-Critical-path-hardening.md карта C
- Канон ledger: session/GATES.md + artifacts/.../GATES-block-C.md (+ зеркало GATES.md)
- A/B/D: GATES-block-A.md · GATES-block-B.md · GATES-block-D.md
- Close C: G1–G5 met via --approve/--reverify after GREEN + /regress; G6 abandoned until L
- SPEC must lock: R2-A|B, TTL hours, one-time y/n, throttle limit/period
-->
