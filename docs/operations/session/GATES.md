# Gates: TASK_93-K / #93 — Hygiene pack (K1–K7)

Scope: один GREEN/PR закрывает hygiene K1–K7 (blog sanitize, demo guard, paymentUrl prod fail, merger whitelist, RUBY-1K regress, HANDOFF sync, RUBY-1J A|B) — без молчаливых хвостов; DEFER только явной строкой в REVIEW. Deploy/prod = TASK_93-L (не DoD блока K).

- [ ] G1: матрица T-K1 — Blog show = `BlogPost::ALLOWED_*` only; save strips disallowed; render не расширяет allowlist
  CHECK: ruby bin/rails test test/models/blog_post_test.rb test/models/blog_post_sanitize_consistency_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — T-K1a source/ERB без отдельного `%w[h1 img style…]` · T-K1b before_save strips `<img>` · T-K1c integration show; `--approve` после GREEN (helper `blog_sanitize` ок)

- [ ] G2: матрица T-K2 + T-K4 — demo password guard + merger `ALLOWED_OPTIONAL_TABLES`
  CHECK: ruby bin/rails test test/services/shop/customer_profile_merger_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — T-K2a seed/prod path без force `demo123456` · T-K2b DEMO_LOGINS warning «не prod» · T-K2c optional no `demo123456` under `app/` · T-K4a `reassign_optional_table!("orders")` raises · T-K4b allowed tables merge; demo file asserts могут жить в том же/соседнем test; `--approve` после GREEN

- [ ] G3: матрица T-K3 — `adapter_payment_url` без fake tinkoff URL в production-like
  CHECK: ruby bin/rails test test/controllers/shop/api/payments_controller_test.rb test/controllers/shop/api/widget_payment_url_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — T-K3a blank/non-http → error (не `securepayments.tinkoff.ru/#{pid}`) · T-K3b valid https as-is · T-K3c UrlBuilder без `SHOP_BASE_DOMAIN` → `?tenant_id=` (регресс); `--approve` после GREEN; simulate/dev fallback ок по SPEC

- [ ] G4: матрица T-K5a + T-K7c + узкий регресс §8 (после GREEN)
  CHECK: ruby bin/rails test test/integration/platform/menu_category_sort_order_update_test.rb test/services/shop/customer_profile_merger_test.rb test/services/analytics/channel_order_stats_collector_test.rb test/models/blog_post_test.rb test/controllers/shop/api/payments_controller_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet — `/regress` после GREEN; T-K5a blank sort_order PASS + REVIEW note «RUBY-1K in this release train» · T-K7c collector PASS · + новые T-K* файлы; без G1+G2+G3 блок не закрыт; K6 HANDOFF sha sync = `/review` ops (не этот CHECK)

- [ ] G5: Fly MCP Point A / deploy checklist K5-in-prod
  EVIDENCE: abandoned — not DoD for TASK_93-K; reopen in TASK_93-L after deploy апрув; K5 код+тест+checklist в K; «закрыт в проде» только после L; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · widget PaymentURL happy path · blog show

ABANDON: G5 Fly MCP / prod deploy is TASK_93-L DoD, not block K; Local G1–G3 + G4 after /regress close K; K6 HANDOFF sync + K7 A|B artifact = `/review` (SPEC locks A vs B before RED)

<!--
CoffeeOS TASK_93-K unlazy (post-/start / pre-SPEC):
- Канон брифа: чат TASK_93-K §1–11 (K1–K7 · T-K*); зонтик customer_tasks/TASK-93-Critical-path-hardening.md карта K
- Активный ledger сессии: docs/operations/session/GATES.md (тот же текст)
- Артефакт блока: milestones/veha_2/artifacts/critical_path_hardening/GATES-block-K.md
- Close K: G1–G3 met via --approve/--reverify after GREEN; G4 после /regress; G5 abandoned until L; K6+K7 в REVIEW
- SPEC must lock: K7 A (Sentry ignore) vs B (collector SET LOCAL); K3 production 422/error shape; DEFER list (лучше пусто); один RED pack → один GREEN
- Без T-K1 + T-K3a + T-K4a блок не закрыт; запрет merge K1+K4 без K3/K7 строки DEFER
- 2026-09-18: --status unmet 4 · abandoned 1 (G5); --approve после GREEN (не сейчас)
-->
