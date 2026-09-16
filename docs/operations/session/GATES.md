# Gates: #91 TASK_89-UI-EXT — phone input UI/UX

Scope: На phone-auth wizard скрыты CTA с суммой и preview корзины; checkout-sheet тоньше (UX Guide); после auth — обычный checkout; Callcheck/SMS/backend не тронуты.

- [x] G1: phone-auth UI — CTA/cart hide + sheet (node; RED добавит asserts)
  CHECK: node --test test/javascript/phone_auth_wizard_test.mjs test/javascript/phone_otp_ui_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=ed0409d0a526f181ec24de6734ae799a53dc042f3ce11305078538dea06498c7; exit=0; EXPECT=matched; output-sha256=1e660c46d35bf85b5278f63db3dd0b2b8cdade4991ba00d454beb12a99c7422a; output-bytes=2123; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: checkout / cart sheet UX zone (rails)
  CHECK: ruby bin/rails test test/integration/shop/shop_checkout_cart_sheet_ux_test.rb test/integration/shop/checkout_ui_cleanup_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=27005af3941f33ead9a77f9555dc317ffbb3186ce65f1dfde7e80161daf6c21f; exit=0; EXPECT=matched; output-sha256=c5cf5578cd2ed1db5218c3c16470475ecce3f070484d362a47a81746323dc3e2; output-bytes=1883; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: #89 auth funnel + phone OTP regress (rails)
  CHECK: ruby bin/rails test test/integration/shop/auth_funnel_wizard_ui_test.rb test/integration/shop/api/phone_otp_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=d2fdc815e910315a5be2c2840c8886d9b65c4f9c870b8e5028aacfb04b2e6852; exit=0; EXPECT=matched; output-sha256=235e13f9070242b7b84ed7dfafbbd491ce75ecaccfe7cd93410bd1d7c0bdd235; output-bytes=1895; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: phone auth cascade SMS.ru zone (node)
  CHECK: node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=d1f9140e216a1befd0d6903c965795d12d59039adccdf496c35bae62c6f0fcc7; exit=0; EXPECT=matched; output-sha256=ac15d9b1c16861a0f044a9088569c58431f31b13e655778c8b9210d4f38bf57f; output-bytes=2201; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — phone-auth sheet без суммы/состава
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/pwa_auth_phone_input_ui_ux/mcp/; PASS = на вводе телефона нет CTA суммы · нет cart preview · sheet тоньше · после auth checkout как раньше

<!--
CoffeeOS #91 unlazy:
- EXT #89 UI only: phone-auth hide CTA+cart · thinner sheet; не Callcheck/SMS/POSTCALL.
- G1–G4: baseline pre-SPEC (#89 zone). RED добавит UI asserts → обновить G1 CHECK при новом файле.
- G5: manual Point A tenant 2fdee1ac-4674-41ee-b89e-87b45643f789.
- ABANDON only with reason at column 1.
-->
