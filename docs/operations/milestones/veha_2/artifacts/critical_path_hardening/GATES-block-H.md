# Gates: TASK_93-H / #93 — Корзина cookie / overflow

Scope: большая shop-корзина в cookie session → **422 + clear** (свой `Shop::CartService::OverflowError`), не **500/NameError**; proactive line/byte cap до commit cookie. Deploy = TASK_93-L (не DoD блока H). UI CartSheet / полный MobileCart PWA — out of scope, если cookie+cap закрывает DoD.

- [x] G1: матрица T-H1 — OverflowError → 422 + clear; нет мёртвого `ActionDispatch::CookieOverflow` как единственного rescue; update path если пишет session
  CHECK: ruby bin/rails test test/integration/shop/api/cart_overflow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=193b2ae8ca7223d08b122abeabdc872ea7fe89796b8983d17b6a1023dc6e5fdd; exit=0; EXPECT=matched; output-sha256=6756a4b6b5141f7789b2b5ff9abc242ae0fa8752fdcd135a67c5a86bfd65d2b7; output-bytes=1618; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: матрица T-H2 — MAX_CART_LINES (distinct) + MAX_SESSION_CART_BYTES в add!/touch_cart_session! (T-H2c skip если SPEC = cookie+cap only)
  CHECK: ruby bin/rails test test/services/shop/cart_service_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=f28a8b51114cdb5dd9a6d1f0b803b7e76853f60d5d3b0866b17511ab4d90b1ef; exit=0; EXPECT=matched; output-sha256=04c6e40884e0d455fc9026665337a17bbca26e796ceb6a2f1103280b525b3a81; output-bytes=1638; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: матрица T-H3 — POST /cart/add до overflow → **422 не 500**; малый cart регресс 200
  CHECK: ruby bin/rails test test/integration/shop/api/cart_overflow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=193b2ae8ca7223d08b122abeabdc872ea7fe89796b8983d17b6a1023dc6e5fdd; exit=0; EXPECT=matched; output-sha256=c968fb2cc4a3ae2e98267539de508da1140debe9588bc0612013f4d010c01167; output-bytes=1618; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: узкий регресс зоны cart (§8 после GREEN)
  CHECK: ruby bin/rails test test/services/shop/cart_service_test.rb test/integration/shop/api/cart_persistence_test.rb test/integration/shop/b113_s4_cart_modifiers_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=b88c21e9e58a9e1a46b1fc1a5fa2c8c26bdde63cab6aa6b17d7bb821893c5690; exit=0; EXPECT=matched; output-sha256=12be7bead1634a3ca68f163647f2b812eabf51673edcd26a66a2356f3e88ac8b; output-bytes=1663; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — большая корзина / overflow UX на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-H; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · overflow → 422 toast copy · small cart OK

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block H; Local G1–G3 + G4 after /regress close H

<!--
CoffeeOS TASK_93-H unlazy:
- Close H local: G1–G4 met 2026-09-18; G5→L
- GREEN d8e5636b · RED 5a635be3
-->
