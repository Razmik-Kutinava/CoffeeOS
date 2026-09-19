# Gates: TASK_94 / #94 — LK history repeat one-click

Scope: В каноническом `#/profile` «Повторить» создаёт новый Order из выбранного исторического заказа и запускает существующий Quick Repeat / widget one-click (inline статусы кнопки); исходный Order и стандартный checkout не меняются.

- [x] G1: JS — ЛК → Repeat → adapter / orchestration (targeted)
  CHECK: node --test test/javascript/lk_history_repeat_one_click_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=df4d0abf616b82f4dc377386e440d0e4e30a69717e1784ae54a2ac212f5a991d; exit=0; EXPECT=matched; output-sha256=541580187d00a73c6a5073901609164cceeee38cfc53f810e0bfb96fcb9e6e95; output-bytes=1571; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: Rails — ЛК history repeat → new Order + one-click contract (targeted)
  CHECK: ruby bin/rails test test/integration/shop/lk_history_repeat_one_click_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=cf6a29c44be7959d3b69c8f9c7e7fbf910fc0976f0d255abd5ce7850643f8c97; exit=0; EXPECT=matched; output-sha256=97e9657b178eebd853e2cb7958b5ab68b004c0d22fa3022bb475b7e317644462; output-bytes=1620; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: zone regression — Quick Repeat one-click + ЛК contract (не ломать)
  CHECK: ruby bin/rails test test/integration/shop/quick_repeat_pay_one_click_test.rb test/integration/shop/pwa_personal_account_lk_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=1fc42298a9a99198874bcb6a403c11b0281342891e717f6df66561be0965b7d9; exit=0; EXPECT=matched; output-sha256=eb33e72f642444b9a194ff97772190c9c0962a9fc3b2588655f2a1d9bc54af7d; output-bytes=1627; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: zone regression — inline pay button / widget flow (Патч 1)
  CHECK: node --test test/javascript/widget_repeat_pay_flow_patch1_test.mjs test/javascript/shop_inline_pay_button_fsm_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=1188fc8f061ff909bb86a4e1c52ad8025ee7a796f9b4755766bee5e35a62ea1c; exit=0; EXPECT=matched; output-sha256=bcc64556d3cf97248f5c4ddac04f27936caaac45a709604c3b4edec8d51a409e; output-bytes=4131; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — Profile → история → Повторить → one-click → PROCESSING → результат → active order
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/lk_history_repeat_one_click/mcp/; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · new Order from selected history · same widget pay flow · inline button statuses · historical Order unchanged · checkout untouched

<!--
CoffeeOS TASK_94 unlazy:
- Pre-SPEC/SBR: G1–G2 test files created on RED; G3–G4 must stay green.
- G5 Fly Point A after deploy. ABANDON only with reason at column 1.
- Do not change Checkout / payment API / OrderStatusSheet / CartSheet clearCartAfterSuccessfulPay.
-->
