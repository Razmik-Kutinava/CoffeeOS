# Gates: #87 Quick Repeat status model composition

Scope: После Quick Repeat one-click / card autopay заказ в status model с составом Order; без интерактивного блока корзины (7.1: Удалить / ± / +N₽).

- [ ] G1: unit createRepeat + OrderStatusSheet + clearCartAfterPay (node)
  CHECK: node --test test/javascript/create_repeat_inline_order_test.mjs test/javascript/order_status_sheet_test.mjs test/javascript/clear_cart_after_successful_pay_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [ ] G2: active orders + receipt composition (rails)
  CHECK: ruby bin/rails test test/integration/shop/api/active_orders_test.rb test/integration/shop/api/active_orders_receipt_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [ ] G3: zone Quick Repeat one-click + cart/status stack (rails)
  CHECK: ruby bin/rails test test/integration/shop/quick_repeat_pay_one_click_test.rb test/integration/shop/active_order_cart_peek_stack_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [ ] G4: hot-path Fly MCP Point A
  EVIDENCE: pending — skip until PHASE 3 REVIEW / deploy; paste mcp artifact path + PASS

<!--
CoffeeOS #87 unlazy:
- G1–G3: todo «Проверка» после /spec; CWD = repo root; Windows: ruby bin/rails.
- G4: manual evidence; заполняется после GREEN/Review.
- 7.1: status sheet ≠ cart UI (Удалить / ± / Итого+CTA).
- ABANDON only with reason at column 1.
-->
