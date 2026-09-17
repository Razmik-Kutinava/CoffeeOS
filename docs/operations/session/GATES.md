# Gates: #92 TASK_90 — WebPush recovery after denied

Scope: После `Notification.permission === "denied"` пользователь видит recovery UI («Открыть настройки» + «Смотреть готовность»); deep-link/fallback в настройки сайта; без нового backend/SW/iOS/Wallet; статусная модель заказа без нового recovery-state.

- [x] G1: denied → settings + recovery CTA (node push subscribe)
  CHECK: node --test test/javascript/order_status_push_subscribe_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=bb9b966fd804e14a53b13f7d2a725e8cde4e001bf442db53eda9a6b0d11b884d; exit=0; EXPECT=matched; output-sha256=ecdde90063af0fc0e3ef8c75cc235a5f171c606884058148cd7f09c8392ec85e; output-bytes=3464; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: notify actions orchestration (node)
  CHECK: node --test test/javascript/order_status_notify_actions_test.mjs test/javascript/order_status_notify_init_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=b6173ac12b067596448a324d9b616803a9417c77cf873a98fe6764a4af6ec01d; exit=0; EXPECT=matched; output-sha256=fce2e00e3276ebd85d79dd240dc4ce66cc8e7026f014cf92d51077a8c7423c21; output-bytes=4046; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: ActiveOrdersAccordion zone (node accordion + receipt)
  CHECK: node --test test/javascript/active_orders_accordion_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=3bff25f2d45bb61e8f556568d1afc1cca911c36fab1e005f1312404af7f27744; exit=0; EXPECT=matched; output-sha256=82834ca5ac77df7b576fa507f1e89fe85579a796bfb2df6a7002952dbcd46dce; output-bytes=5002; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: order status acceptance / push structural (rails)
  CHECK: ruby bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb test/integration/shop/order_status_sheet_mount_acceptance_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=a27fce989cc4164feaef45d5034f755aaf05e12af56efcad4ce53909fe45b4b8; exit=0; EXPECT=matched; output-sha256=20c1fd28e31e704aceb5a054f78832537d3115db3f88cf603ab7d19b9d383bbc; output-bytes=1891; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — Android Chrome denied → settings → return PWA
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/webpush_recovery_after_denied/mcp/; PASS = recovery UI · open settings path or fallback · «Смотреть готовность» → status model · WebPush resumes after grant · Wallet/iOS untouched

<!--
CoffeeOS #92 unlazy baseline (pre-SPEC):
- EXT #81 п.9.1 / Google TASK_90: recovery after denied; не фоновые FCM; не чат; не #83/#84.
- G1–G4 baseline существующей зоны #37/#81. RED добавит recovery UI asserts → обновить G1 CHECK.
- G5: manual Point A tenant 2fdee1ac-4674-41ee-b89e-87b45643f789 · Android+Chrome.
- ABANDON only with reason at column 1.
-->
