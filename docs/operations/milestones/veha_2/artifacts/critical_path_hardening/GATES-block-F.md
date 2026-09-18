# Gates: TASK_93-F / #93 — Callbacks / stuck payments / Events

Scope: Events fail-closed без secrets на публичном стенде; rejected не держит idempotency `processing` 24h (retry после reject); stuck tbank → GetState/`TbankPaymentSync`; fiscal soft-skip → report/alert (+ optional retry). Deploy = TASK_93-L (не DoD блока F). T‑Bank `notify` HMAC path не ломаем.

- [x] G1: матрица T-F1 + T-F2 + T-F5 — fail-closed secrets · claim release on reject · auth 401
  CHECK: ruby bin/rails test test/controllers/callbacks/events_controller_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=f75ba056e7ff55d96a076634a9c913a2b7d79e3ededac2b920fb7cfda2548a02; exit=0; EXPECT=matched; output-sha256=b73193164bb92537c748139bd45353d9f4cebd27d07767a7cb01a9e3d508c06f; output-bytes=1650; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: матрица T-F3 — StuckPaymentsCheckJob GetState/sync (не только Telegram)
  CHECK: ruby bin/rails test test/jobs/payments/stuck_payments_check_job_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=8bcee1586eaf3d792c87be4a92afc5485709424aed93edb4d185909426bc8e94; exit=0; EXPECT=matched; output-sha256=32900e7ceecc07bd5e1ac6e790fbd3c5ea5b1567956aa3b27d819a978ce28b7e; output-bytes=1611; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: матрица T-F4 — fiscal soft-skip → Rails.error.report / alert (+ retry)
  CHECK: ruby bin/rails test test/services/payments/tbank_fiscal_notification_handler_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=98350cbfd943aee29dc2d9c33d4c9e05e841e86e7ad08556b4118ddc442404f3; exit=0; EXPECT=matched; output-sha256=2d2f8baac62bc791b12d600aae58d3a426e317b4971f2541454aa32f82f47704; output-bytes=1615; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: узкий регресс зоны callbacks/payments (§8 после GREEN)
  CHECK: ruby bin/rails test test/controllers/callbacks/ test/jobs/payments/ test/services/payments/tbank_payment_sync_test.rb test/jobs/payments/tbank_callback_job_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=c7a56ac596d5166f25d13ae29335454ee1026128d018001dec8afb23828e0f16; exit=0; EXPECT=matched; output-sha256=18091b6ff0e0426ca2af84579c8f9e4c67cac3580104044edf4e823f3d662489; output-bytes=1689; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — Events/stuck/fiscal на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-F; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · fail-closed без secrets · stuck sync · fiscal skip visible в Sentry/Telegram

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block F; Local G1–G4 close F

<!--
CoffeeOS TASK_93-F unlazy:
- Close F: G1–G4 met 2026-09-18 after GREEN + /regress; G5 abandoned until L
- GREEN `1b28a128` · Entire `01M2SSQXT1V67AK260SH1P9RAX`
-->
