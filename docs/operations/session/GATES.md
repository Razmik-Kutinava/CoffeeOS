# Gates: #86 SBP PWA recovery after bank

Scope: После СБП/банка PWA восстанавливает payment state и показывает success/error/waiting (return + cold start); device Android+iOS без SKIP.

- [x] G1: unit pending + SBP status (node)
  CHECK: node --test test/javascript/codeblack_pending_order_test.mjs test/javascript/shop_sbp_pay_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=74dd84b59d3c5c2b7cdc8ca02db61eb3c7c6b4c60eaee97ac756e56f55f6c33c; exit=0; EXPECT=matched; output-sha256=d2ced6a71a18c21ef5b3fcd199fc7a0c66790df0f11b4036d50564dddd38b89f; output-bytes=2645; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=f06fbfcf7545/77 entries

- [x] G2: SBP return/UI integration (rails zone)
  CHECK: ruby bin/rails test test/integration/shop/sbp_payment_return_ui_test.rb test/integration/shop/sbp_payment_ui_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=bbb4bd4d528e00cc66ee2f32b81e1919349643c02b4d2da81c5f81e3ea3c5bb3; exit=0; EXPECT=matched; output-sha256=b958a7784c806e70cac90fb77d54f6511d72604a322aeae9c56faf7b3ae98ea0; output-bytes=1885; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=f06fbfcf7545/77 entries

- [ ] G3: hot-path Fly MCP Point A
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; paste mcp artifact path + PASS

- [ ] G4: device E2E Android PWA→NSPK→bank→return/reopen→result
  EVIDENCE: pending — artifacts/sbp_pwa_recovery_after_bank_ext/device/android/ (SKIP ≠ PASS)

- [ ] G5: device E2E iOS PWA→NSPK→bank→return/reopen→result
  EVIDENCE: pending — artifacts/sbp_pwa_recovery_after_bank_ext/device/ios/ (SKIP ≠ PASS)

<!--
CoffeeOS #86 unlazy:
- G1–G2: todo «Проверка»; CWD = repo root; Windows: ruby bin/rails.
- G3–G5: manual evidence; заполняются после GREEN/Review/device.
- ABANDON only with reason at column 1.
-->
