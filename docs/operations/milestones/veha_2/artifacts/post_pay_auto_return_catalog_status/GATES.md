# Gates: #93 TASK_91 — post-pay auto return → catalog + status

Scope: После email submit/Skip или при `!askReceiptEmail` на `#/payment-result?status=ok` пользователь автоматически попадает на `#/` с существующей статусной моделью; без немедленного redirect при visible email-блоке; без правок Checkout/SBP/OrderStatusSheet internals.

- [x] G1: email / PaymentResult zone (node #71 + #93)
  CHECK: node --test test/javascript/email_collection_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=4c29f5d7d3d077abe9e52fa2f708c33681bd1ccdcb9170174dc888a23d4e25e4; exit=0; EXPECT=matched; output-sha256=a4839703d20d1c6608cf3e1e2298cdcaf30a0c666b80ce4205552ec99e2abc65; output-bytes=4723; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: order status acceptance (#35 Continue → catalog)
  CHECK: ruby bin/rails test test/integration/shop/order_status_acceptance_cbr_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=1798d8899576bd91cc2f9ff485a871700015f2900a220039dfae1c34f54c751d; exit=0; EXPECT=matched; output-sha256=94042719d266b79bbd36a674a0738468c2cc92fc9e7667f18404c47b34f1c896; output-bytes=1877; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: order status sheet mount (status model on catalog)
  CHECK: ruby bin/rails test test/integration/shop/order_status_sheet_mount_acceptance_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=545b0e73b82669f17fab839b44fb6dfa267c6461615bbcc6571715c0d77f33ea; exit=0; EXPECT=matched; output-sha256=560aea88ba2aafac0888c0c1609f1686db24124fb82c72ff562cf8c47feb6502; output-bytes=1883; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G4: hot-path Fly MCP Point A — card pay → payment-result → email/skip or known receipt → auto `#/` + status sheet
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/post_pay_auto_return_catalog_status/mcp/; PASS = no stuck «В каталог» when receipt known · status model on `#/` · no immediate redirect while email block shown · Continue CTA still works · SBP/QR untouched

<!--
CoffeeOS #93 unlazy (post-GREEN / pre-REVIEW):
- GREEN 118e5488 · maybeAutoReturnToCatalog when !askReceiptEmail
- Session GATES.md may be owned by another task (#94) — this file is the #93 ledger.
- G1–G3 local; G4 Fly Point A after deploy.
- ABANDON only with reason at column 1.
-->
