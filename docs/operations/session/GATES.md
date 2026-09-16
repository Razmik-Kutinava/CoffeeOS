# Gates: #90 TASK_89-POSTCALL-EXT — return after Callcheck → pay

Scope: После Callcheck-звонка пользователь возвращается в PWA без потери Callcheck/checkout; pending → «Проверяем номер» + polling; confirmed/SMS → auth TASK_89 → авто PaymentMethodsSheet; без нового init_callcheck на lifecycle.

- [x] G1: lifecycle return — visibility/pageshow resume Callcheck (node / structural)
  CHECK: node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_auth_wizard_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=75ae628ea5cba574f17ad6666aaa860f2ac313ad0ee789c10137434a3de9dd60; exit=0; EXPECT=matched; output-sha256=d02546d5ca8923f923b70579c62e032e08614c9de87991fadeca7739f885f8da; output-bytes=4350; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: post-verify → PaymentMethodsSheet (rails structural + #89 handoff)
  CHECK: ruby bin/rails test test/integration/shop/silent_refresh_frontend_structural_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=08eae614534bf91037574ef579dd25fff00142ea7ffa6a92accb69b1be6285b9; exit=0; EXPECT=matched; output-sha256=605135c7cea175965de1e2af3eb2daad8ba51c9d6511f8dd8fa73f704603673b; output-bytes=1889; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: Callcheck / linker / session regress (rails)
  CHECK: ruby bin/rails test test/integration/shop/api/phone_otp_test.rb test/services/shop/phone_verified_customer_linker_test.rb test/services/shop/phone_otp_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=fb0d5a051e3e68b175d480ade9dc6104a4fff244af69db110886b028cf08901a; exit=0; EXPECT=matched; output-sha256=f561a4ba77b360b97cf948af193f18ba71f14af308ad9d89590fce96ace60e95; output-bytes=1894; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: phone OTP UI + cascade SMS.ru (node zone)
  CHECK: node --test test/javascript/phone_otp_ui_test.mjs test/javascript/shop_phone_auth_cascade_smsru_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=bfd4ac28cafddb5369eb027e7212cc642605deb6025de16c08ddd8ca625c8ccc; exit=0; EXPECT=matched; output-sha256=4d94c34a49ead79e8fbfe0db126fa9db419e4f22ab5811c26c763812cb82d6db; output-bytes=3464; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — phone dial → return PWA → pay sheet
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/pwa_callcheck_return_continue_payment/mcp/; PASS = return resumes same Callcheck · no second init · confirmed/SMS → PaymentMethodsSheet · checkout state kept

<!--
CoffeeOS #90 unlazy (restart after rollback):
- EXT #89: lifecycle PWA + copy «вернитесь» + resume poll; не UI-EXT; не SMS.ru backend.
- G1–G4 baseline pre-SPEC (#89 zone). RED добавит lifecycle asserts → обновить G1 CHECK.
- G5: manual Point A tenant 2fdee1ac-4674-41ee-b89e-87b45643f789.
- ABANDON only with reason at column 1.
-->
