# Gates: TASK_84-RECEIPT-DISPLAY-EXT — runtime receipt display

Scope: При раскрытии активного заказа в `ActiveOrdersAccordion` фактически виден текстовый `.aoa__receipt` (позиции/модификаторы/итоги) через существующий `receiptView`; runtime DOM-тест; без backend / rewrite `receiptView`.

- [x] G1: JS — ActiveOrdersAccordion (runtime receipt + #84 contract)
  CHECK: node --test test/javascript/active_orders_accordion_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=3bff25f2d45bb61e8f556568d1afc1cca911c36fab1e005f1312404af7f27744; exit=0; EXPECT=matched; output-sha256=8486f798db5444a9ffa29e8921384c259eb1b6328f8dbd51420105dbfa7df949; output-bytes=6087; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: integration — backend contract active orders receipt payload
  CHECK: ruby bin/rails test test/integration/shop/api/active_orders_receipt_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=3462327a6e2c41db2c0a9043c28a302a3c429c85b55643989df1746f0f7331c6; exit=0; EXPECT=matched; output-sha256=c4b120f06504aab97da33eff9feb65b50d54eb3a49209c54595496ab2dc4cfc8; output-bytes=1617; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: integration — active orders API zone
  CHECK: ruby bin/rails test test/integration/shop/api/active_orders_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=26956227a19325df8a4ab84e11fb221f024f5ecfbaf1ed555a3990cd97c89d15; exit=0; EXPECT=matched; output-sha256=9222baf7fb4f5e5a0be1f99ac58dc5d8f4ba2a8d6bb585fe4834c014977c5807; output-bytes=1617; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: zone — order status sheet mount (не ломать status model)
  CHECK: ruby bin/rails test test/integration/shop/order_status_sheet_mount_acceptance_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=545b0e73b82669f17fab839b44fb6dfa267c6461615bbcc6571715c0d77f33ea; exit=0; EXPECT=matched; output-sha256=e6f613a0d080c75d6dd12c8b30447938b1b1da4d234e9d963041b698b13de007; output-bytes=1620; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G5: hot-path Fly MCP Point A — expand active order → `.aoa__receipt` text
  EVIDENCE: PARTIAL 2026-09-21 Fly **v500** · bundle `aoa__receipt` in `application-GGG5C-C0.js` · deep MCP 19/21 · catalog/cart Point A PASS · expand active order unmet (нет active orders) · [`artifacts/mcp/fly_v500_2026-09-21/MCP_RESULT.md`](../mcp/fly_v500_2026-09-21/MCP_RESULT.md)

<!--
CoffeeOS TASK_84-RECEIPT-DISPLAY-EXT unlazy:
- EXT к #84; ID не #94 (занят LK).
- G1–G4 local; G5 Fly after deploy.
- Не rewrite receiptView; не трогать aoa__dismiss / OrderStatusSheet polling.
-->
