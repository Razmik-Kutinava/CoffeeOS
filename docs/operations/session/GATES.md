# Gates: #87 Quick Repeat status model composition

Scope: После Quick Repeat one-click / card autopay заказ в status model с составом Order; без интерактивного блока корзины (7.1: Удалить / ± / +N₽).

- [x] G1: unit createRepeatInlineOrder + OrderStatusSheet (node)
  CHECK: node --test test/javascript/create_repeat_inline_order_test.mjs test/javascript/order_status_sheet_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=dc5f4b91a3bdf4c5c97f504bdaeb22cf11f23dd2d034afd7f0a95513d96bc528; exit=0; EXPECT=matched; output-sha256=2c0ecef80a651d75bf19ef4b2cdedeaa78d1c38ff244f727c7053eb795408f4c; output-bytes=2768; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=f06fbfcf7545/77 entries

- [x] G2: active orders + receipt composition (rails)
  CHECK: ruby bin/rails test test/integration/shop/api/active_orders_test.rb test/integration/shop/api/active_orders_receipt_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=0095b174ce9610a7ca86c27430a99c2a36ac729a3843c0df4c39fcad8e60d92d; exit=0; EXPECT=matched; output-sha256=2e9fea42212d0f336953d57875ababa94e2c3ff81306cf5b710aa5a2cbabf6bc; output-bytes=1881; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=f06fbfcf7545/77 entries

- [x] G3: zone Quick Repeat one-click + cart/status stack (rails)
  CHECK: ruby bin/rails test test/integration/shop/quick_repeat_pay_one_click_test.rb test/integration/shop/active_order_cart_peek_stack_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=e17aa7a8a7c409cb46baa65843c9cb5fe2874f986f5f243f10d52dc5ffaab8c4; exit=0; EXPECT=matched; output-sha256=1b58662cb2016ca6024ea48803a8031c82e0dac63640a633404a3a80bba8480c; output-bytes=1885; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=f06fbfcf7545/77 entries

- [ ] G4: hot-path Fly MCP Point A
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; paste mcp artifact path + PASS

<!--
CoffeeOS #87 unlazy:
- G1–G3: todo «Проверка» после /spec; CWD = repo root; Windows: ruby bin/rails.
- G4: manual evidence; заполняется после GREEN/Review.
- 7.1: status sheet ≠ cart UI (Удалить / ± / Итого+CTA).
- ABANDON only with reason at column 1.
-->
