# Gates: TASK_84-RECEIPT-DISPLAY-EXT — runtime receipt display

Scope: При раскрытии активного заказа в `ActiveOrdersAccordion` фактически виден текстовый `.aoa__receipt` (позиции/модификаторы/итоги) через существующий `receiptView`; runtime DOM-тест; без backend / rewrite `receiptView`.

- [x] G1: JS — ActiveOrdersAccordion (runtime receipt + #84 contract)
  CHECK: node --test test/javascript/active_orders_accordion_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=3bff25f2d45bb61e8f556568d1afc1cca911c36fab1e005f1312404af7f27744; exit=0; EXPECT=matched; output-sha256=21f54f5894311f072c1c9692293bc64da4ebf1f1d6dc582edf724be2c42a1b24; output-bytes=6089; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: integration — backend contract active orders receipt payload
  CHECK: ruby bin/rails test test/integration/shop/api/active_orders_receipt_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=3462327a6e2c41db2c0a9043c28a302a3c429c85b55643989df1746f0f7331c6; exit=0; EXPECT=matched; output-sha256=307c923e46231bbf9150302f278e15ecd394abaf5d051457828e441e7fc64184; output-bytes=1616; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: integration — active orders API zone
  CHECK: ruby bin/rails test test/integration/shop/api/active_orders_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=26956227a19325df8a4ab84e11fb221f024f5ecfbaf1ed555a3990cd97c89d15; exit=0; EXPECT=matched; output-sha256=b1a20ecaa7fd45c7c99e07b383be0e4ff8c343bf4fc4d8e5d0bea3520539ad32; output-bytes=1617; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: zone — order status sheet mount (не ломать status model)
  CHECK: ruby bin/rails test test/integration/shop/order_status_sheet_mount_acceptance_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=545b0e73b82669f17fab839b44fb6dfa267c6461615bbcc6571715c0d77f33ea; exit=0; EXPECT=matched; output-sha256=487e015d22684855c57ac8bd114d43ffe84cc7daefcfee6712473f2a14a54ab6; output-bytes=1621; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — expand active order → `.aoa__receipt` text
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; artifact under artifacts/active_orders_receipt_display_restore/mcp/; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` · CTA «Состав заказа» → текстовый receipt (name/qty/total) · один expanded · dismiss/Cable/API не тронуты

<!--
CoffeeOS TASK_84-RECEIPT-DISPLAY-EXT unlazy:
- EXT к #84; ID не #94 (занят LK).
- G1–G4 local; G5 Fly after deploy.
- Не rewrite receiptView; не трогать aoa__dismiss / OrderStatusSheet polling.
-->
