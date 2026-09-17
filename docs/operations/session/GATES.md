# Gates: #94 TASK_92 — Production background FCM + status sync

Scope: Фоновые FCM (tag/actions/прогресс) при смене статуса без открытой PWA; кнопка «чат с поддержкой» в статусной модели кликабельна; без правок barista status controller/service.

- [x] G1: FCM client data-only + notifier + payload
  CHECK: ruby bin/rails test test/services/shop/fcm_client_test.rb test/services/shop/order_status_push_notifier_test.rb test/services/shop/order_status_push_payload_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=43bcf97ee1add4700a89f57a31dec655e829b75b5b10237a9eb945105a5795a3; exit=0; EXPECT=matched; output-sha256=1f0cf5ba83e0d2e1c736cffe6a474dcff873d946d1d9d44156e3d10e32abcb9a; output-bytes=1891; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: support chat adapter (клик CTA → open URL)
  CHECK: node --test test/javascript/support_chat_adapter_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=fe2ae7f905e59aca2fa138d2b48f9d3156185756c0f114813ad612c048fbbd0c; exit=0; EXPECT=matched; output-sha256=3b7873887014a1ca3758a6e597d259eea474e01a4ce8ca9ac9fc43e545de2480; output-bytes=1182; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: order status push subscribe + support chat path
  CHECK: node --test test/javascript/order_status_push_subscribe_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=bb9b966fd804e14a53b13f7d2a725e8cde4e001bf442db53eda9a6b0d11b884d; exit=0; EXPECT=matched; output-sha256=5eb36a5324b8a4a306b0648fdfb4480a2c67d5b6ed31b6deb9f536177b5e39b1; output-bytes=4098; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: push pipeline simulation (status → notifier path)
  CHECK: ruby bin/rails test test/integration/shop/push_pipeline_simulation_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=11a1a6f35f62127d4edda00dc373f5f0926dfe8ccf217db959ccfb2129a976bf; exit=0; EXPECT=matched; output-sha256=45273f50080ee34adaefe9f9c00f4f10aee166571035f354a86b804737b5a61c; output-bytes=1870; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — background FCM + chat CTA
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/production_background_fcm_status_sync/mcp/; PASS = Android push in shade with progress/tag while PWA backgrounded · status sync · chat CTA opens support · barista status files untouched · Point A tenant 2fdee1ac-4674-41ee-b89e-87b45643f789

<!--
CoffeeOS #94 unlazy post-GREEN/regress:
- G1 includes fcm_client_test (#94 data-only).
- G5 Fly MCP Point A after deploy апрув.
- ABANDON only with reason at column 1.
-->
