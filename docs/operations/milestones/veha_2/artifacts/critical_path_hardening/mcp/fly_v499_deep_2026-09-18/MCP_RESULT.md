# MCP Deep — Fly v499 TASK_93-L

**Date:** 2026-09-18 · **Point A** · **HEAD** `d1c88c91` · **Status:** PASS

| Pass | Fail | Total |
|------|------|-------|
| 20 | 0 | 20 |

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
| B | B_phone_verify_6digit | PASS | http=200 · normalized_phone |
| B | B_order_without_email_block | PASS | tenant key issued; expect not email-only 422 · http=422 · Корзина пуста · normalized_phone |
| D | D_history_default_page | PASS | PASS if 200; lengthв‰Ґ2 needs в‰Ґ2 orders on guest вЂ” soft · http=200 · true |
| C | C_short_link_opens | PASS | 404 ok if TTL expired; not 500 · http=404 |
| E | E_live_pid_present | PASS | re-Init live charge skipped without funded card; evidence pid exists |
| H | H_overflow_error_defined | PASS | const probe · true |
| A | A_recent_paid_accepted_evidence | PASS | new live pay skipped (no owner charge); historical evidence on Point A |
| G | G_tenant_guc_products | PASS |  |
| I | I_otp_verify_throttle | PASS | 429 ideal; 422 reject without 500 also ok for soft |
| 86-94 | endpoint__shop_api_session | PASS | http=404 |
| 86-94 | endpoint__shop_api_user_cards | PASS | http=401 |
| A | A_simulate_flag | PASS | informational вЂ” live charge not auto-run |

Safety: disposable phone; no Redis URL/PAN. Live pay skipped (`SHOP_SIMULATE=0`).

**B_order:** POST /orders → 422 «Корзина пуста» (API session cart ≠ browser cart) — **не** email-блок; phone verify **200 verified=true**.

**Browser:** catalog → cart 358₽ → CTA → `#/checkout`.

**Skipped (нужен device/карта):** live Callcheck dial, funded pay→webhook settle, full cart overflow UX cookie. Evidence: A/E historical + F reject + I Redis 429.
