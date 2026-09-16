# Gates: #91 TASK_89-UI-EXT — phone input UI/UX

Scope: На phone-auth wizard скрыты CTA с суммой и preview корзины; checkout-sheet тоньше (UX Guide); после auth — обычный checkout; Callcheck/SMS/backend не тронуты.

- [x] G1: phone-auth UI — CTA/cart hide + sheet (node; RED добавит asserts)
  CHECK: node --test test/javascript/phone_auth_wizard_test.mjs test/javascript/phone_otp_ui_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=ed0409d0a526f181ec24de6734ae799a53dc042f3ce11305078538dea06498c7; exit=0; EXPECT=matched; output-sha256=407ce2663d0670eee428d4a992f51b4049ccfc1bf27d6e84a297e91fe72aa40d; output-bytes=2126; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: checkout / cart sheet UX zone (rails)
  CHECK: ruby bin/rails test test/integration/shop/shop_checkout_cart_sheet_ux_test.rb test/integration/shop/checkout_ui_cleanup_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=27005af3941f33ead9a77f9555dc317ffbb3186ce65f1dfde7e80161daf6c21f; exit=0; EXPECT=matched; output-sha256=e536c727cca6b49e80d1f445cec9a8ab5292e5f2a270d8d0b5f6431a3284c141; output-bytes=1883; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: #89 auth funnel + phone OTP regress (rails)
  CHECK: ruby bin/rails test test/integration/shop/auth_funnel_wizard_ui_test.rb test/integration/shop/api/phone_otp_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=d2fdc815e910315a5be2c2840c8886d9b65c4f9c870b8e5028aacfb04b2e6852; exit=0; EXPECT=matched; output-sha256=ef49af3b1d6865feee4b089d763550dc16dac4da6eaa2d5cc3352750ac9f3565; output-bytes=1894; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: phone auth cascade SMS.ru zone (node)
  CHECK: node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=d1f9140e216a1befd0d6903c965795d12d59039adccdf496c35bae62c6f0fcc7; exit=0; EXPECT=matched; output-sha256=0d5b4702db6e930422e24c97c7cd4ee544189969be79f1ae84c4089e5d55b6a5; output-bytes=2194; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — phone-auth sheet без суммы/состава
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/pwa_auth_phone_input_ui_ux/mcp/; PASS = на вводе телефона нет CTA суммы · нет cart preview · sheet тоньше · после auth checkout как раньше

<!--
CoffeeOS #91 unlazy:
- EXT #89 UI only: phone-auth hide CTA+cart · thinner sheet; не Callcheck/SMS/POSTCALL.
- G1–G4: baseline pre-SPEC (#89 zone). RED добавит UI asserts → обновить G1 CHECK при новом файле.
- G5: manual Point A tenant 2fdee1ac-4674-41ee-b89e-87b45643f789.
- ABANDON only with reason at column 1.
-->
