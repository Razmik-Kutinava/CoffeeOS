# Gates: #92 TASK_90 — WebPush recovery after denied

Scope: После `Notification.permission === "denied"` пользователь видит recovery UI («Открыть настройки» + «Смотреть готовность»); deep-link/fallback в настройки сайта; без нового backend/SW/iOS/Wallet; статусная модель заказа без нового recovery-state.

- [x] G1: denied → settings + recovery CTA (node push subscribe)
  CHECK: node --test test/javascript/order_status_push_subscribe_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=bb9b966fd804e14a53b13f7d2a725e8cde4e001bf442db53eda9a6b0d11b884d; exit=0; EXPECT=matched; output-sha256=fe0ef813cecaa0b38b81ef6050742f40d2e6ff8b5d7d1c0aa5f48c5bb4611fb7; output-bytes=3467; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: notify actions orchestration (node)
  CHECK: node --test test/javascript/order_status_notify_actions_test.mjs test/javascript/order_status_notify_init_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=b6173ac12b067596448a324d9b616803a9417c77cf873a98fe6764a4af6ec01d; exit=0; EXPECT=matched; output-sha256=33f80ceb3675a5bbc18a630e8f63ceb83f09c4943b53c1092ad3811de0f9feb0; output-bytes=4050; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: ActiveOrdersAccordion zone (node accordion + receipt)
  CHECK: node --test test/javascript/active_orders_accordion_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=3bff25f2d45bb61e8f556568d1afc1cca911c36fab1e005f1312404af7f27744; exit=0; EXPECT=matched; output-sha256=992b6a03949f829ed80d1c86d9717a50550fec7d5aba62459f8c8c2897140ae0; output-bytes=4999; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: order status acceptance / push structural (rails)
  CHECK: ruby bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb test/integration/shop/order_status_sheet_mount_acceptance_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=a27fce989cc4164feaef45d5034f755aaf05e12af56efcad4ce53909fe45b4b8; exit=0; EXPECT=matched; output-sha256=dce605af015a4fc8212bb2d9f8ed5aa7f09338a440ac27ff81b5105960ec5ac4; output-bytes=1891; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — Android Chrome denied → settings → return PWA
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/webpush_recovery_after_denied/mcp/; PASS = recovery UI · open settings path or fallback · «Смотреть готовность» → status model · WebPush resumes after grant · Wallet/iOS untouched

<!--
CoffeeOS #92 unlazy baseline (pre-SPEC):
- EXT #81 п.9.1 / Google TASK_90: recovery after denied; не фоновые FCM; не чат; не #83/#84.
- G1–G4 baseline существующей зоны #37/#81. RED добавит recovery UI asserts → обновить G1 CHECK.
- G5: manual Point A tenant 2fdee1ac-4674-41ee-b89e-87b45643f789 · Android+Chrome.
- ABANDON only with reason at column 1.
-->
