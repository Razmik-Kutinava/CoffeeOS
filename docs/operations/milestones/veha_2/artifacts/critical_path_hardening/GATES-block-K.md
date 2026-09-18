# Gates: TASK_93-K / #93 — Hygiene pack (K1–K7)

Scope: один GREEN/PR закрывает hygiene K1–K7 (blog sanitize, demo guard, paymentUrl prod fail, merger whitelist, RUBY-1K regress, HANDOFF sync, RUBY-1J B) — без молчаливых хвостов; DEFER только явной строкой в REVIEW. Deploy/prod = TASK_93-L (не DoD блока K).

- [x] G1: матрица T-K1 — Blog show = `BlogPost::ALLOWED_*` only; save strips disallowed; render не расширяет allowlist
  CHECK: ruby bin/rails test test/models/blog_post_sanitize_consistency_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=aef02ca4672956f8b1f23312e049d8a9275ead73840ea6ac142d20cca155e366; exit=0; EXPECT=matched; output-sha256=91faa3e411c0e2700af10de207bef635691636677b51749163aee654b7844c8f; output-bytes=1614; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: матрица T-K2 + T-K4 — demo password guard + merger `ALLOWED_OPTIONAL_TABLES`
  CHECK: ruby bin/rails test test/services/shop/customer_profile_merger_test.rb test/services/demo/environment_setup_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=dc4ea823f474651882946f262f72983f4d6686daa55b66a1df807629f384330e; exit=0; EXPECT=matched; output-sha256=f3c809b29fd834b0aba2f7d541ce811c141813e5dfed574bf9e0ec1cdf6818fa; output-bytes=1812; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: матрица T-K3 — `adapter_payment_url` без fake tinkoff URL в production-like
  CHECK: ruby bin/rails test test/controllers/shop/api/widget_payment_url_test.rb test/integration/shop/api/payment_widget_init_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=5648b325c551a1717d2cc723b2e892eaad49c59c8d0afff45f716132cac59078; exit=0; EXPECT=matched; output-sha256=c59e1c4b5a3f92b375e144717bf9d7a28c84ff9fdb7527c8f55b5ffc94ce8205; output-bytes=1621; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: матрица T-K5a + T-K7c + узкий регресс §8 (после GREEN)
  CHECK: ruby bin/rails test test/integration/platform/menu_category_sort_order_update_test.rb test/services/shop/customer_profile_merger_test.rb test/services/analytics/channel_order_stats_collector_test.rb test/models/blog_post_sanitize_consistency_test.rb test/controllers/shop/api/widget_payment_url_test.rb test/integration/shop/api/payment_widget_init_test.rb test/services/demo/environment_setup_test.rb test/integration/platform/onboarding_infra_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=0d1e4d7986ef2d4f8c233774532567ac2c1d2248bde5568f15d234c93ce18b80; exit=0; EXPECT=matched; output-sha256=16f3b32dfe0ceac09fac0f26c76b5cc0ea765fe4520229d668676f89574a1847; output-bytes=1836; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: Fly MCP Point A / deploy checklist K5-in-prod
  EVIDENCE: abandoned — not DoD for TASK_93-K; reopen in TASK_93-L after deploy апрув; K5 код+тест+checklist в K; «закрыт в проде» только после L; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · widget PaymentURL happy path · blog show

ABANDON: G5 Fly MCP / prod deploy is TASK_93-L DoD, not block K; Local G1–G4 met after /regress; K6 HANDOFF sync + K7-B note = `/review`

<!--
CoffeeOS TASK_93-K unlazy:
- Close K local: G1–G4 met; G5→L; /review for K6 + RUBY-1K/1J notes
- 2026-09-18 regress: 35/0 · approve G1–G4
-->
