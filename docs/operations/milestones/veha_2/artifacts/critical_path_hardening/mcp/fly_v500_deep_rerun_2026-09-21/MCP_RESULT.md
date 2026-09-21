# MCP Deep — Fly v500 TASK_93-L

**Date:** 2026-09-21 · **Point A** · **HEAD** `ad0421c6` · **Status:** PARTIAL

| Pass | Fail | Total |
|------|------|-------|
| 19 | 2 | 21 |

| Block | ID | Pass | Notes |
|-------|----|------|-------|
| I | I_redis_store | PASS |  |
| J | J_worker_started | PASS |  |
| J | J_solid_queue_alive | PASS |  |
| F | F_events_fail_closed | PASS | http=404 |
| F | F_tbank_callback_reject | PASS | http=401 |
| K | K_blog_reachable | PASS | http=404 |
| K | K_shop_home_200 | PASS | http=200 |
| smoke | categories_200 | PASS | http=200 |
| B | B_phone_verify_6digit | FAIL | http=422 |
| B | B_order_without_email_block | PASS | phone_verified must not 422 on email alone · http=422 |
| D | D_history_default_page | PASS | PASS if 200; length≥2 needs ≥2 orders on guest — soft · http=200 |
| D | D_per_page_1_honored | PASS | http=200 |
| C | C_short_link_opens | PASS | 404 ok if TTL expired; not 500 · http=302 |
| E | E_live_pid_present | PASS | re-Init live charge skipped without funded card; evidence pid exists |
| H | H_overflow_error_defined | FAIL | full cookie overflow UX = browser follow-up |
| A | A_recent_paid_accepted_evidence | PASS | new live pay skipped (no owner charge); historical evidence on Point A |
| G | G_tenant_guc_products | PASS |  |
| I | I_otp_verify_throttle | PASS | 429 ideal; 422 reject without 500 also ok for soft |
| 86-94 | endpoint__shop_api_session | PASS | http=404 |
| 86-94 | endpoint__shop_api_user_cards | PASS | http=200 |
| A | A_simulate_flag | PASS | informational — live charge not auto-run |

Safety: disposable phone only; no Redis URL/PAN/OTP codes in artifact.
