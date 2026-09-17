# Gates: #94 TASK_92 — Production background FCM + status sync

Scope: Фоновые FCM (tag/actions/прогресс) при смене статуса без открытой PWA; кнопка «чат с поддержкой» в статусной модели кликабельна; без правок barista status controller/service.

- [x] G1: FCM notifier + payload (обогащение / tag / actions)
  CHECK: ruby bin/rails test test/services/shop/order_status_push_notifier_test.rb test/services/shop/order_status_push_payload_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e2a0af4161881379d75948222397767a02af4eb38fb85b1373f47c07fd5c6ef2; exit=0; EXPECT=matched; output-sha256=1fde0d94a2a9c2ddf5c2601c2c2d0a9ea8082359ab704ef8b2341ef8c03d2e50; output-bytes=1882; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: support chat adapter (клик CTA → open URL)
  CHECK: node --test test/javascript/support_chat_adapter_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=fe2ae7f905e59aca2fa138d2b48f9d3156185756c0f114813ad612c048fbbd0c; exit=0; EXPECT=matched; output-sha256=3421671050b67bb2587c2da976eb42933c79ce86f013411d1276e747bda23180; output-bytes=985; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: order status push subscribe + support chat path
  CHECK: node --test test/javascript/order_status_push_subscribe_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=bb9b966fd804e14a53b13f7d2a725e8cde4e001bf442db53eda9a6b0d11b884d; exit=0; EXPECT=matched; output-sha256=dbf81aff28b6d529bccacc1a8d7efbccf469ef593f0f3dcd21c1dd31e20e1e87; output-bytes=3466; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: push pipeline simulation (status → notifier path)
  CHECK: ruby bin/rails test test/integration/shop/push_pipeline_simulation_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=11a1a6f35f62127d4edda00dc373f5f0926dfe8ccf217db959ccfb2129a976bf; exit=0; EXPECT=matched; output-sha256=2f338dbb02a21200442a9ce187658688a169af9f1816c83d96a2cd9250f92a38; output-bytes=1870; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — background FCM + chat CTA
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/production_background_fcm_status_sync/mcp/; PASS = Android push in shade with progress/tag while PWA backgrounded · status sync · chat CTA opens support · barista status files untouched · Point A tenant 2fdee1ac-4674-41ee-b89e-87b45643f789

<!--
CoffeeOS #94 unlazy baseline (pre-SPEC):
- Customer TASK_92 / Google Doc 1gcML9Wk…: п.1 фоновые FCM «не реализовано»; chat CTA shown but dead.
- CBR #94 ≠ CBR #92 (WebPush recovery TASK_90).
- G1–G4 baseline зоны #38/#41 до RED. После RED обновить asserts (background payload + chat click).
- G5: manual Point A · Android Chrome · reopen #81 backlog slice.
- ABANDON only with reason at column 1.
-->
