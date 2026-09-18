# Gates: TASK_93-J / #93 — Push / уведомления / worker

Scope: смена статуса / webhook **не** ждут APNs/FCM; FCM OAuth cache + dead tokens; cascade `wait = SMS_GRACE + 5s` без race grace; runbook Solid Queue / `SOLID_QUEUE_IN_PUMA`. Deploy worker Fly = TASK_93-L (не DoD блока J). UI WebPush (#90), SMS текст (C), Redis Attack (I), склад (A) — out of scope.

- [ ] G1: матрица T-J1 — async APNs/Wallet/FCM; PassUpdater **не** sync из broadcaster; push вне `payment.with_lock`
  CHECK: ruby bin/rails test test/services/barista/order_status_update_service_test.rb test/services/shop/guest_order_broadcaster_test.rb test/services/callbacks/payment_status_updater_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — baseline: `GuestOrderBroadcaster` sync `PassUpdater.call!`; cascade `set(wait: SMS_GRACE)`; `GuestOrderBroadcaster` из `accept_order_if_paid!` **внутри** `with_lock`; T-J1a/b/c ещё нет / не assert DoD; `--approve` после GREEN

- [ ] G2: матрица T-J2 — FCM OAuth cache + UNREGISTERED clears token
  CHECK: ruby bin/rails test test/services/shop/fcm_client_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — `fetch_access_token!` без `Rails.cache`; нет cleanup UNREGISTERED; T-J2a/b/c; `--approve` после GREEN · T-J2c simulate unchanged

- [ ] G3: матрица T-J3 — cascade wait **>** SMS_GRACE (BUFFER +5s); presence grace / SMS skip
  CHECK: ruby bin/rails test test/jobs/shop/order_ready_cascade_job_test.rb test/services/shop/order_ready_presence_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — enqueue `wait: SMS_GRACE` (==15s) → race; нужно `wait: SMS_GRACE + 5.seconds`; T-J3a–d; без **J1+J3** блок не закрыт; `--approve` после GREEN

- [ ] G4: J4 runbook + tbank/cascade queue contract + узкий регресс §8 (после GREEN)
  CHECK: ruby bin/rails test test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb test/controllers/callbacks/tbank_controller_test.rb test/services/shop/order_status_push_notifier_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet — `/regress` после GREEN; T-J4a `docs/operations/runbooks/SOLID_QUEUE_FLY.md` (файл **отсутствует** 2026-09-18); T-J4b tbank `perform_now` primary; T-J4c cascade/ready требуют queue runner · `deploy.yml` уже `SOLID_QUEUE_IN_PUMA: true` (зафиксировать в runbook); без ложного dual perform_now для SMS

- [ ] G5: hot-path Fly MCP Point A — worker / push / cascade на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-J; reopen in TASK_93-L (включить/проверить worker или Puma plugin live); artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · status change без sync APNs latency · cascade SMS after grace+buffer · queue jobs run

ABANDON: G5 Fly worker/MCP Point A is TASK_93-L DoD, not block J; Local G1–G3 + G4 after /regress close J; runbook docs in J (T-J4a)

<!--
CoffeeOS TASK_93-J unlazy (post-/start / pre-SPEC):
- Канон брифа: чат TASK_93-J §3–11 (J1–J4 · R1–R8 · T-J*); зонтик customer_tasks/TASK-93-Critical-path-hardening.md карта J
- Активный ledger сессии: docs/operations/session/GATES.md (тот же текст)
- Артефакт блока: milestones/veha_2/artifacts/critical_path_hardening/GATES-block-J.md
- Close J: G1–G3 met via --approve/--reverify after GREEN; G4 после /regress; G5 abandoned until L
- SPEC must lock: BUFFER=5s · job names (WalletUpdateJob?) · sync Cable vs async APNs/FCM matrix · R8 perform_now fallback vs Puma-only
- Зависимость: A затем J (broadcaster из lock); после F удобно (та же очередь)
- Без J1+J3 блок не закрыт
- 2026-09-18: --status unmet 4 · abandoned 1 (G5); --approve после GREEN (не сейчас)
-->
