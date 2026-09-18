# Gates: TASK_93-C / #93 — SMS «заказ готов» + short link

Scope: SMS URL на живом host приложения; `/o/:hash` → bind + redirect; HostAuthorization не режет; throttle brute MAC; TTL токена. Deploy/DNS = TASK_93-L (не DoD блока C).

- [ ] G1: T-C1a..c — SMS host canon (не мёртвый codeblack.xyz) + длина ≤70
  CHECK: ruby bin/rails test test/services/shop/order_ready_sms_link_test.rb test/services/shop/order_ready_paid_notifier_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — RED: assert без hardcoded dead domain; GREEN: SHOP_SMS_LINK_HOST|APP_HOST|fallback coffeeos.fly.dev; R2 mode fixed in SPEC; length budget

- [ ] G2: T-C2c + T-C3a..d — `/o/:hash` Host OK + redirect/bind + forge 404
  CHECK: ruby bin/rails test test/integration/shop/order_short_links_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — valid → 302 + reconnect_token + guest bind; bad/forged MAC → 404 no bind; T-C2a only if SPEC chooses R2-B

- [ ] G3: T-C4a/b — Rack::Attack throttle GET `/o/`
  CHECK: ruby bin/rails test test/integration/rack_attack_order_short_link_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — файл создать на RED; over limit → 429; under limit → 302/404; limit/period зафиксировать в SPEC (MemoryStore OK; Redis → 93-I)

- [ ] G4: T-C5a/c (+ T-C5b если one-time) — TTL short-link token
  CHECK: ruby bin/rails test test/integration/shop/order_short_links_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — expired → 404 no bind; within TTL first open → 302 + bind; one-time да/нет = SPEC (TTL обязателен)

- [ ] G5: зона #82 / notifications regress (notifier + short links)
  CHECK: ruby bin/rails test test/services/shop/order_ready_paid_notifier_test.rb test/integration/shop/order_short_links_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — `/regress` блок C после GREEN

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
