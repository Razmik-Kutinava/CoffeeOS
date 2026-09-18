# Gates: TASK_93-I / #93 — OTP / rate limit / auth abuse

Scope: Rack::Attack shared Redis store на multi-machine Fly; throttle `verify_sms` (+ legacy/email по SPEC); OTP SMS 6 digits **или** явный DEFER; short-link rule `shop/order_short_link/ip` живой через shared store **без** дубля. Deploy Redis / secret Fly = TASK_93-L (не DoD блока I). SolidCache для Attack **запрещён**.

- [ ] G1: матрица T-I1 — shared Attack store (не MemoryStore на prod/FLY)
  CHECK: ruby bin/rails test test/integration/rack_attack_store_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — файла/кейсов T-I1a/b/c может не быть; baseline MemoryStore ≠ DoD; `--approve` после GREEN: prod/FLY+REDIS_URL → Redis*/RedisCacheStore (T-I1a) · shared increment (T-I1b) · без REDIS_URL на FLY → boot fail **или** documented fail-open+ERROR (T-I1c = SPEC)

- [ ] G2: матрица T-I2 — throttle verify_sms (+ legacy)
  CHECK: ruby bin/rails test test/integration/rack_attack_otp_verify_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — нет throttle verify → T-I2a должен падать на RED; `--approve` после GREEN: N+1 → 429 RATE_LIMIT_EXCEEDED (T-I2a) · under limit не 429 (T-I2b) · phone key (T-I2c если R3) · legacy `/phone_otp/verify` (T-I2d); email verify — если SPEC R4 in-scope

- [ ] G3: матрица T-I3 — SMS OTP 6 digits (+ UI)
  CHECK: ruby bin/rails test test/services/shop/phone_otp_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — SPEC **I3 IN SCOPE** (не DEFER): `%06d` (T-I3a) · verify 6 (T-I3b) · frontend PIN/SMS length=6 (T-I3c); Callcheck не менять; `--approve` после GREEN

- [ ] G4: матрица T-I4 + узкий регресс §8 (после GREEN)
  CHECK: ruby bin/rails test test/integration/rack_attack_order_short_link_test.rb test/integration/shop/order_short_links_test.rb test/integration/rack_attack_otp_verify_test.rb test/services/shop/phone_otp_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet — `/regress` после GREEN; T-I4a rule exists · T-I4b many GET `/o/` → 429 · T-I4c один matched name (нет дубля); phone OTP zone regress; без I1+I2 блок не закрыт; I4 = «C4 multi-machine»

- [ ] G5: Fly Redis attach / secret `REDIS_URL` + hot-path MCP Point A
  EVIDENCE: abandoned — not DoD for TASK_93-I; reopen in TASK_93-L (или отдельный ops step с апрувом); runbook Redis в artifacts ок в I; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · Attack counters shared across machines · verify_sms 429 · `/o/` throttle

ABANDON: G5 Fly Redis secret + MCP Point A is TASK_93-L DoD, not block I; Local G1–G2 (+ G3 if in-scope) + G4 after /regress close I; runbook docs allowed in I

<!--
CoffeeOS TASK_93-I unlazy (post-/start / pre-SPEC):
- Канон брифа: чат TASK_93-I §3–11 (I1–I4 · R1–R7 · T-I*); зонтик customer_tasks/TASK-93-Critical-path-hardening.md карта I
- Активный ledger сессии: docs/operations/session/GATES.md (тот же текст)
- Артефакт блока: milestones/veha_2/artifacts/critical_path_hardening/GATES-block-I.md
- Close I: G1–G2 met via --approve/--reverify after GREEN; G3 met или DEFER/abandon; G4 после /regress; G5 abandoned until L
- SPEC 2026-09-18: R1 Redis URL priority · R8 fail-boot · R3/R4 5/min IP+identity · R5 I3 IN SCOPE · R9 CI redis
- Без I1+I2 блок не закрыт; I4 обязателен; I3 in-scope
- 2026-09-18: --status unmet 4 · abandoned 1 (G5); --approve после GREEN (не сейчас)
- 2026-09-18 GREEN c14f5202 · Local matrix PASS (T-I1b skip) · Entire backfill commit next
-->
