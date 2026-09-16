# Gates: #89 PWA auth registration Callcheck → SMS

Scope: После успешного Callcheck/SMS — MobileCustomer + session; wizard закрыт; пользователь в checkout и на экране оплаты (флоу); FlashCall не возвращён.

- [x] G1: Callcheck confirmed + PhoneVerifiedCustomerLinker (rails)
  CHECK: ruby bin/rails test test/integration/shop/api/phone_otp_test.rb test/services/shop/phone_verified_customer_linker_test.rb test/services/shop/phone_otp_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=fb0d5a051e3e68b175d480ade9dc6104a4fff244af69db110886b028cf08901a; exit=0; EXPECT=matched; output-sha256=5097a44979b8bd880e2529e93ae785e4f2a750e302ba492de06e5191bf7bec54; output-bytes=1900; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: phone auth wizard + cascade SMS.ru (node)
  CHECK: node --test test/javascript/phone_auth_wizard_test.mjs test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_otp_ui_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=9cb9f35ff3d63ec2e2d3c827d187b4f9f80c90888ec8724f01a6aa9fe0d1bbf6; exit=0; EXPECT=matched; output-sha256=8872ca7bc2ef7121fed9f2c74d705fdef758752d7383483f68f4ee8beddf3cfa; output-bytes=4206; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: FlashCall guard + auth funnel UI (rails)
  CHECK: ruby bin/rails test test/integration/shop/auth_funnel_wizard_ui_test.rb test/services/shop/sms_ru_phone_otp_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=a3a82ed8a7e0889c627136fa3565ac0b56068b6915cb202e729a2729e298ad07; exit=0; EXPECT=matched; output-sha256=be26acd8692e9588d221b032d1bb9c629a62d8e50f4dd368488663e786f4ccde; output-bytes=1882; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: zone checkout / phone OTP regress (rails)
  CHECK: ruby bin/rails test test/integration/shop/checkout_ui_cleanup_test.rb test/integration/shop/checkout_acceptance_cbr_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=30057078074cca1b34de5bbfa0b015e1ceed3c4ff0075d7872603fe834b1975e; exit=0; EXPECT=matched; output-sha256=1c326b424a6cf1d3e647308c00a5c4ce32197029426093fd4bcfde4c10a91898; output-bytes=1888; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — Callcheck → session → экран оплаты
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/pwa_auth_registration_callcheck_sms/mcp/; PASS = post-call wizard gone + PaymentMethods (или CTA pay) + phone in DB

<!--
CoffeeOS #89 unlazy:
- G1–G4: после /spec → todo «Проверка»; Windows: ruby bin/rails; CWD = repo root.
- G5: manual hot-path Point A (tenant 2fdee1ac-4674-41ee-b89e-87b45643f789).
- Post-verify → PaymentMethodsSheet: закрывает доп.задачу заказчика; тест появится на RED.
- Не возвращать flash_call /code/call.
- ABANDON only with reason at column 1.
-->
