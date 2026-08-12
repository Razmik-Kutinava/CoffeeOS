# todo — Enable SBP in PaymentMethodsSheet (2026-08-12)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| local GREEN 29/0 · commit | done local | push + deploy + Fly MCP Point A |

## Цель
Заказчик: «кнопка СБП не активна». Root cause: hardcoded disable в `PaymentMethodsSheet` (#26 G4). Unlock → Checkout + `shopSbpPay`.

## Файлы (ожидаемо)
- `app/frontend/components/PaymentMethodsSheet.svelte` — **[x]**
- `test/integration/shop/sbp_payment_ui_test.rb` — **[x]**
- `test/integration/shop/checkout_acceptance_cbr_test.rb` — **[x]**
- `test/integration/shop/repeat_invalid_token_payment_test.rb` — **[x]**

## Не ломать
- Карта / «Картой +» / NewCardForm
- Inline fallback СБП
- Toast 3001 в `shopSbpPay`

## Проверка
- `bin/rails test …sbp_payment_ui… checkout_acceptance_cbr… repeat_invalid_token… checkout_ui_cleanup… user_cards_sbp_accounts` → **29/0 PASS**

## SBR
- [x] SPEC
- [x] RED→GREEN (тесты + unlock)
- [x] commit + ops
- [ ] Fly MCP (после deploy)
