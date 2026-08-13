# todo — фикс MCP FAIL: NET raw + A6 frequent after cancel (2026-08-13)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| GREEN local JS 9/0 · cancel 13/0 | done local | push/deploy · Fly MCP recheck |

## Цель
1) NET: только «Нет связи. Повторить» на CTA, без alert `Failed to fetch`.  
2) A6: guest cancel → bust frequent → «повторить» снова.

## Файлы
- `app/frontend/lib/shopPayFsm.js`
- `app/frontend/routes/Checkout.svelte`
- `app/services/shop/guest_order_cancellation_service.rb`
- `app/services/shop/customer_frequent_products_service.rb` (comment)
- tests: `payment_error_user_messages_test.mjs` · `guest_order_cancellation_service_test.rb`

## Проверка
- [x] `node --test test/javascript/payment_error_user_messages_test.mjs` → 9/0
- [x] `ruby bin/rails test test/services/shop/guest_order_cancellation_service_test.rb` → 13/0
- [ ] Fly MCP Point A: offline pay (нет Failed to fetch) · cancel → повторить
