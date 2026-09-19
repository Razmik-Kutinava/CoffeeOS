# Gates: TASK_94 / #94 — LK history repeat one-click

Scope: В каноническом `#/profile` «Повторить» создаёт новый Order из выбранного исторического заказа и запускает существующий Quick Repeat / widget one-click (inline статусы кнопки); исходный Order и стандартный checkout не меняются.

**Живой ledger сессии:** [`docs/operations/session/GATES.md`](../../../session/GATES.md)

- [ ] G1: JS — ЛК → Repeat → adapter / orchestration (targeted)
  CHECK: node --test test/javascript/lk_history_repeat_one_click_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — file created on RED

- [ ] G2: Rails — ЛК history repeat → new Order + one-click contract (targeted)
  CHECK: ruby bin/rails test test/integration/shop/lk_history_repeat_one_click_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending — file created on RED

- [x] G3: zone regression — Quick Repeat one-click + ЛК contract (не ломать)
  CHECK: ruby bin/rails test test/integration/shop/quick_repeat_pay_one_click_test.rb test/integration/shop/pwa_personal_account_lk_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: see session GATES.md (2026-09-19 baseline PASS)

- [x] G4: zone regression — inline pay button / widget flow (Патч 1)
  CHECK: node --test test/javascript/widget_repeat_pay_flow_patch1_test.mjs test/javascript/shop_inline_pay_button_fsm_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: see session GATES.md (2026-09-19 baseline PASS)

- [ ] G5: hot-path Fly MCP Point A — Profile → история → Повторить → one-click → PROCESSING → результат → active order
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/lk_history_repeat_one_click/mcp/

<!--
CoffeeOS TASK_94 unlazy — baseline 2026-09-19: met G3/G4 · unmet G1/G2/G5
-->
