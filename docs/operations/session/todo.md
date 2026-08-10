# todo — Group 2: payments / cards / SBP (2026-08-10)

**Намерение:** ебашь Группа 2 — UserCards · invalid token · inline · widget · SBP · autopay · cancel refund

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| Group 2 code: error_code · Cancel→422 · 1051≠invalid | Local PASS · MCP sheet PASS | deploy FE **или** Group 3 шторка |

## Файлы (ожидаемо)
- `app/services/shop/payment_status_presenter.rb` ✅ error_code
- `app/services/payments/tbank_payment_sync.rb` ✅ keep ErrorCode
- `app/services/shop/guest_order_cancellation_service.rb` ✅ Cancel ApiError→422
- `app/frontend/lib/repeatInvalidTokenStore.js` ✅ 1051 out of invalid rebill

## Не ломать
- оплата / 1-клик / UserCards список
- кнопка «повторить» / frequent
- табло бариста / статусы в PWA
- peek корзины / CartSheet layering (нет наслоения pay-sheet)

## Проверка
```bash
bundle exec rails test \
  test/integration/shop/api/payment_status_error_code_test.rb \
  test/services/shop/guest_order_cancellation_service_test.rb \
  test/integration/shop/api/qa_section_2_3_payment_cart_test.rb \
  test/integration/shop/api/qa_section_2_3_stage5_e2e_test.rb \
  test/integration/shop/api/sbp_payment_init_test.rb \
  test/integration/shop/api/sbp_autopay_charge_test.rb \
  test/integration/shop/api/payment_widget_init_test.rb \
  test/integration/shop/api/payment_status_test.rb \
  test/integration/shop/shop_usercards_phase1_persist_test.rb \
  test/integration/shop/shop_saved_cards_step3_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/integration/shop/repeat_invalid_token_payment_test.rb
# → 70 runs, 0 failures, 2 skips
node --test test/javascript/repeat_invalid_token_payment_test.mjs test/javascript/shop_inline_pay_button_fsm_test.mjs
# → 27 pass
```

## Чеклист
- [x] Local PASS
- [x] MCP: PaymentMethodsSheet *8782/*5953 · SBP disabled · без OTP
- [x] ErrorCode банка не маскируем под app-bug (1051 → insufficient, не invalid token)
- [x] Косяки → fix (presenter / Cancel / 1051)
- [ ] deploy FE (Group 1+2) — ждать апрув
