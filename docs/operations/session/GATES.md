# Gates: #93 TASK_91 — post-pay auto return → catalog + status

Scope: После email submit или Skip на `#/payment-result?status=ok` пользователь автоматически попадает на `#/` с существующей статусной моделью; без немедленного redirect при mount; без правок Checkout/SBP/OrderStatusSheet internals.

- [x] G1: email / PaymentResult zone (node #71)
  CHECK: node --test test/javascript/email_collection_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=4c29f5d7d3d077abe9e52fa2f708c33681bd1ccdcb9170174dc888a23d4e25e4; exit=0; EXPECT=matched; output-sha256=d14c2a6e19b52582916e7750843648e894b52476cbfe684b2f0fdcfc60fdcb5b; output-bytes=3894; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: order status acceptance (#35 Continue → catalog)
  CHECK: ruby bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=1798d8899576bd91cc2f9ff485a871700015f2900a220039dfae1c34f54c751d; exit=0; EXPECT=matched; output-sha256=27b03b14f913d8435b0ad3540c8b30e72b51f6f462c11d7acb2787d496069a83; output-bytes=1876; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: order status sheet mount (status model on catalog)
  CHECK: ruby bin/rails test test/integration/shop/order_status_sheet_mount_acceptance_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=545b0e73b82669f17fab839b44fb6dfa267c6461615bbcc6571715c0d77f33ea; exit=0; EXPECT=matched; output-sha256=3598be8b113931020d989ab5851687300998e89b878287144c6082ef7bdfcdea; output-bytes=1883; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G4: hot-path Fly MCP Point A — card pay → payment-result → email/skip → auto `#/` + status sheet
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/post_pay_auto_return_catalog_status/mcp/; PASS = no stuck «В каталог» after email/skip · status model on `#/` · no immediate redirect on success mount · Continue CTA still works · SBP/QR untouched

<!--
CoffeeOS #93 unlazy baseline (pre-SPEC):
- Customer 9.2 / Google TASK_91: auto #/ after email/skip; not #92 WebPush; not Checkout completePaySuccess.
- G1–G3 baseline зоны #71/#35 до RED. После RED обновить G1 asserts (auto navigate after submit/skip).
- G4: manual Point A tenant 2fdee1ac-4674-41ee-b89e-87b45643f789 · Android+Chrome card pay path.
- Screenshots: artifacts/post_pay_auto_return_catalog_status/screenshots/
- ABANDON only with reason at column 1.
-->
