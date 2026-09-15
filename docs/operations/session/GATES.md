# Gates: #87 Quick Repeat status model composition

Scope: После Quick Repeat one-click / card autopay заказ в status model с составом Order; без интерактивного блока корзины (7.1: Удалить / ± / +N₽).

- [x] G1: unit createRepeat + OrderStatusSheet + clearCartAfterPay (node)
  CHECK: node --test test/javascript/create_repeat_inline_order_test.mjs test/javascript/order_status_sheet_test.mjs test/javascript/clear_cart_after_successful_pay_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e635afebe8edbcf5df5a0588a74539fea24c309876460d0b0e9ae4e30da2e70f; exit=0; EXPECT=matched; output-sha256=c43c19ee77df9a18fb1f14d336cf896bdd8306f7819bf217fb174d13a1b57255; output-bytes=3389; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=f06fbfcf7545/77 entries

- [x] G2: active orders + receipt composition (rails)
  CHECK: ruby bin/rails test test/integration/shop/api/active_orders_test.rb test/integration/shop/api/active_orders_receipt_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=0095b174ce9610a7ca86c27430a99c2a36ac729a3843c0df4c39fcad8e60d92d; exit=0; EXPECT=matched; output-sha256=f178a1b394a93e806f299a17cd887ccbf7757264106485c4dbde4cbea016e6e3; output-bytes=1882; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=f06fbfcf7545/77 entries

- [x] G3: zone Quick Repeat one-click + cart/status stack (rails)
  CHECK: ruby bin/rails test test/integration/shop/quick_repeat_pay_one_click_test.rb test/integration/shop/active_order_cart_peek_stack_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e17aa7a8a7c409cb46baa65843c9cb5fe2874f986f5f243f10d52dc5ffaab8c4; exit=0; EXPECT=matched; output-sha256=06cbf5ec05ebb2d1fd93f91e6699ef4a4bd1a491c1976e4a0b6a03316f7c89e7; output-bytes=1887; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=f06fbfcf7545/77 entries

- [ ] G4: hot-path Fly MCP Point A
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; paste mcp artifact path + PASS

<!--
CoffeeOS #87 unlazy:
- G1–G3: todo «Проверка» после /spec; CWD = repo root; Windows: ruby bin/rails.
- G4: manual evidence; заполняется после GREEN/Review.
- 7.1: status sheet ≠ cart UI (Удалить / ± / Итого+CTA).
- ABANDON only with reason at column 1.
-->
