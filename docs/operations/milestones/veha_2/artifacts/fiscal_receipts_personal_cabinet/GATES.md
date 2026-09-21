# Gates: #73 — фискальные чеки в ЛК

Scope: RECEIPT webhook Т-Банка → хранение `FiscalReceipt` → API истории/деталей заказа → секция «Чек» в PWA ЛК (без Патч 1; без email/QR-допов заказчика).

- [x] G1: unit — TbankFiscalNotificationHandler (idempotency / mapping / Token)
  CHECK: ruby bin/rails test test/services/payments/tbank_fiscal_notification_handler_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=98350cbfd943aee29dc2d9c33d4c9e05e841e86e7ad08556b4118ddc442404f3; exit=0; EXPECT=matched; output-sha256=cf8bade12c731482eb788ae9ee4ac850376b15b002a95772fb5b9016a2b78f2c; output-bytes=1620; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: integration — API фискальных чеков заказа (ЛК)
  CHECK: ruby bin/rails test test/integration/shop/api/order_fiscal_receipts_api_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=c62eb966ab1859a2a4740aec82914ab9fdc64cf94792fe1262dfb6b388e8bf87; exit=0; EXPECT=matched; output-sha256=15b4709b5f64becb5687d9272acd45aca8ca21a5af787adcf855713c3234aa55; output-bytes=1614; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: zone — callbacks T-Bank (fiscal + payment OK / Token)
  CHECK: ruby bin/rails test test/controllers/callbacks/tbank_controller_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=547f8e3301acc7f950be58867725a0cf213b7eb6fa736902f94e449b5a402667; exit=0; EXPECT=matched; output-sha256=9579ff30e50dac7950c2f72a62c47741d5870dcff7fd9bf01de33bfc578cb758; output-bytes=1631; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: zone regression — Receipt contact (#72) не ломать
  CHECK: ruby bin/rails test test/services/payments/tbank_receipt_builder_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=9f2a63a6d767efb07741dcad4fd4306cc13d65ea190996c99b6406df80e31959; exit=0; EXPECT=matched; output-sha256=a5c7b70cd9b548251f59e1aa82d0d60b8c1242f3f1f98450b4049beedbad5466; output-bytes=1618; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — live RECEIPT → чек в ЛК
  EVIDENCE: pending — skip until fiscal notify ON на терминале + deploy; artifact under artifacts/fiscal_receipts_personal_cabinet/mcp/; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · Status=RECEIPT на `/callbacks/tbank` · `FiscalReceipt` · ссылка «Чек» в карточке заказа

<!--
CoffeeOS #73 unlazy:
- Полный SBR по основной задаче; Патч 1 — отдельный /patch после.
- Pre-SPEC: G1–G4 — целевые тесты зоны (CLOSURE_PREP 2026-08-28).
- G5 Fly после deploy + fiscal notify ON. ABANDON только с reason на колонке 1.
- Не генерировать свой QR по ФН/ФД/ФП; не ломать payment webhook / checkout.
-->
