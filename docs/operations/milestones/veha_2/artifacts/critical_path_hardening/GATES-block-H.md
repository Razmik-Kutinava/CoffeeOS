# Gates: TASK_93-H / #93 — Корзина cookie / overflow

Scope: большая shop-корзина в cookie session → **422 + clear** (свой `Shop::CartService::OverflowError`), не **500/NameError**; proactive line/byte cap до commit cookie. Deploy = TASK_93-L (не DoD блока H). UI CartSheet / полный MobileCart PWA — out of scope, если cookie+cap закрывает DoD.

- [ ] G1: матрица T-H1 — OverflowError → 422 + clear; нет мёртвого `ActionDispatch::CookieOverflow` как единственного rescue; update path если пишет session
  CHECK: ruby bin/rails test test/integration/shop/api/cart_overflow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — `cart_overflow_test.rb` отсутствует (InvalidTestError 2026-09-18); baseline без Overflow path ≠ DoD; `--reverify` после GREEN: T-H1a/b/c

- [ ] G2: матрица T-H2 — MAX_CART_LINES (distinct) + MAX_SESSION_CART_BYTES в add!/touch_cart_session! (T-H2c skip если SPEC = cookie+cap only)
  CHECK: ruby bin/rails test test/services/shop/cart_service_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — baseline `cart_service_test` PASS (2026-09-18) ≠ DoD T-H2a/b (нет line/byte OverflowError cases); `--reverify` после GREEN + цифры SPEC

- [ ] G3: матрица T-H3 — POST /cart/add до overflow → **422 не 500**; малый cart регресс 200
  CHECK: ruby bin/rails test test/integration/shop/api/cart_overflow_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED — файла нет; без T-H3a блок не закрыт; `--reverify` после GREEN

- [ ] G4: узкий регресс зоны cart (§8 после GREEN)
  CHECK: ruby bin/rails test test/services/shop/cart_service_test.rb test/integration/shop/api/cart_persistence_test.rb test/integration/shop/b113_s4_cart_modifiers_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet — baseline zone PASS (2026-09-18) зафиксирован как sanity; закрывать G4 только `/regress` после GREEN T-H*

- [ ] G5: hot-path Fly MCP Point A — большая корзина / overflow UX на стенде
  EVIDENCE: abandoned — not DoD for TASK_93-H; reopen in TASK_93-L after deploy апрув; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · overflow → 422 toast copy · small cart OK

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block H; Local G1–G3 + G4 after /regress close H

<!--
CoffeeOS TASK_93-H unlazy (post-/start / pre-SPEC):
- Канон брифа: чат TASK_93-H §3–10 (H1–H3 · R1–R6); зонтик customer_tasks/TASK-93-Critical-path-hardening.md карта H
- Активный ledger сессии: docs/operations/session/GATES.md (тот же текст)
- Артефакт блока: milestones/veha_2/artifacts/critical_path_hardening/GATES-block-H.md
- Close H: G1–G3 met via --reverify after GREEN; G4 после /regress; G5 abandoned until L
- SPEC must lock: cookie+cap vs server-side · MAX_CART_LINES · MAX_SESSION_CART_BYTES · update covered?
- Без T-H3a блок не закрыт
- 2026-09-18: --status/--approve: G1+G3 fail (no overflow test) · G2+G4 baseline PASS ≠ DoD → unchecked unmet 4 + abandoned 1
-->
