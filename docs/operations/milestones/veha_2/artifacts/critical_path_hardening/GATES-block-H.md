# Gates: TASK_93-H / #93 — Корзина cookie / overflow

Scope: большая shop-корзина в cookie session → **422 + clear** (свой `Shop::CartService::OverflowError`), не **500/NameError**; proactive line/byte cap до commit cookie. Deploy = TASK_93-L (не DoD блока H). UI CartSheet / полный MobileCart PWA — out of scope, если cookie+cap закрывает DoD.

- [x] G1: матрица T-H1 — OverflowError → 422 + clear; нет мёртвого `ActionDispatch::CookieOverflow` как единственного rescue; update path если пишет session
  CHECK: ruby bin/rails test test/integration/shop/api/cart_overflow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: met 2026-09-18 `/regress` — T-H1a/b/c in suite; GREEN `d8e5636b`; zone run 53/0 incl. overflow

- [x] G2: матрица T-H2 — MAX_CART_LINES (distinct) + MAX_SESSION_CART_BYTES в add!/touch_cart_session! (T-H2c skip если SPEC = cookie+cap only)
  CHECK: ruby bin/rails test test/services/shop/cart_service_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: met 2026-09-18 — T-H2a/b PASS; T-H2c SKIP (cookie+cap); lines=20 · bytes=3072

- [x] G3: матрица T-H3 — POST /cart/add до overflow → **422 не 500**; малый cart регресс 200
  CHECK: ruby bin/rails test test/integration/shop/api/cart_overflow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: met 2026-09-18 — T-H3a/b PASS in `/regress` bundle

- [x] G4: узкий регресс зоны cart (§8 после GREEN)
  CHECK: ruby bin/rails test test/services/shop/cart_service_test.rb test/integration/shop/api/cart_persistence_test.rb test/integration/shop/b113_s4_cart_modifiers_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: met 2026-09-18 `/regress` — `cart_service` + `cart_overflow` + `cart_persistence` + `b113_s4_cart_modifiers` → **53 runs, 0 failures, 0 errors**

- [ ] G5: hot-path Fly MCP Point A — большая корзина / overflow UX на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-H; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · overflow → 422 toast copy · small cart OK

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block H; Local G1–G3 + G4 after /regress close H

<!--
CoffeeOS TASK_93-H unlazy:
- Close H local: G1–G4 met 2026-09-18; G5→L
- GREEN d8e5636b · RED 5a635be3
-->
