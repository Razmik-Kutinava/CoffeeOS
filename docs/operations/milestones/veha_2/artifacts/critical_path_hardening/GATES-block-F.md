# Gates: TASK_93-F / #93 — Callbacks / stuck payments / Events

Scope: Events fail-closed без secrets на публичном стенде; rejected не держит idempotency `processing` 24h (retry после reject); stuck tbank → GetState/`TbankPaymentSync`; fiscal soft-skip → report/alert (+ optional retry). Deploy = TASK_93-L (не DoD блока F). T‑Bank `notify` HMAC path не ломаем.

- [ ] G1: матрица T-F1 + T-F2 + T-F5 — fail-closed secrets · claim release on reject · auth 401
  CHECK: ruby bin/rails test test/controllers/callbacks/events_controller_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — T-F1a/b · T-F2a/b/c/d · T-F5a/b ещё не в suite / дыры; baseline PASS ≠ DoD блока F; `--approve` только после GREEN с explicit fail-closed + release claim + retry-after-reject

- [ ] G2: матрица T-F3 — StuckPaymentsCheckJob GetState/sync (не только Telegram)
  CHECK: ruby bin/rails test test/jobs/payments/stuck_payments_check_job_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — файла/кейсов T-F3a–d может не быть; `--approve` после GREEN: pending>30m + pid → succeeded; без pid → alert; GetState fail → alert+continue; fresh <threshold ignore

- [ ] G3: матрица T-F4 — fiscal soft-skip → Rails.error.report / alert (+ retry если в SPEC)
  CHECK: ruby bin/rails test test/services/payments/tbank_fiscal_notification_handler_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — T-F4a/b (c) report на payment_not_found / missing_fiscal_ids; T-F4d happy receipt без ложного report; `--approve` после GREEN

- [ ] G4: узкий регресс зоны callbacks/payments (§8 после GREEN)
  CHECK: ruby bin/rails test test/controllers/callbacks/ test/jobs/payments/ test/services/payments/tbank_payment_sync_test.rb test/jobs/payments/tbank_callback_job_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet — `/regress` после GREEN; не закрывать baseline без T-F*; amount mismatch Events остаётся 422 без succeeded (R6)

- [ ] G5: hot-path Fly MCP Point A — Events/stuck/fiscal на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-F; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · fail-closed без secrets · stuck sync · fiscal skip visible в Sentry/Telegram

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block F; Local G1–G3 + G4 after /regress close F

<!--
CoffeeOS TASK_93-F unlazy (pre-SPEC / pre-SBR):
- Канон: customer_tasks/TASK-93-Critical-path-hardening.md · блок F (R1–R6) + DoD чата F1–F5
- Активный ledger сессии: docs/operations/session/GATES.md (тот же текст)
- Close F: G1–G3 met via --approve/--reverify after GREEN; G4 после /regress; G5 abandoned until L
- Зависимость: A до F предпочтительно (GetState→succeeded может снова дернуть deduction)
- Без T-F2a и T-F3a блок не закрыт
- 2026-09-18: --status unmet 4 + abandoned 1; --approve после GREEN (не сейчас)
-->
