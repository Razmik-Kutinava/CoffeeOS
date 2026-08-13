# todo — invalid token sheet + One-Click fail → PaymentMethodsSheet (2026-08-13)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| intake скрины + UX ТЗ | BUILD GREEN | push/deploy · Fly MCP Point A |

## Цель
1. Повторный заказ (невалидный токен): CTA «Добавить карту» + шторка = скрин `09_customer_payment_methods_sheet_canon_2026-08-13.png`.
2. UX после ошибки One-Click: «карта +» → полная `PaymentMethodsSheet` (не клип формы в peek).

## Файлы (ожидаемо)
- `app/frontend/lib/openRepeatPaymentSheet.js` — nav + markOpenPaymentSheet
- `app/frontend/lib/widgetRepeatPayFlow.js` — resolveCardPlus → openPaymentSheet
- `app/frontend/components/RepeatSection.svelte` — fail → setTokenInvalid; card+ → sheet
- `app/frontend/lib/repeatInvalidTokenStore.js` — reuse (без смены API)
- `app/frontend/components/PaymentMethodsSheet.svelte` — канон UI (без дубля ошибки)
- `app/frontend/components/CartSheet.svelte` — CTA Добавить карту (neighbor)
- `app/frontend/routes/Checkout.svelte` — consumeOpenPaymentSheet (neighbor)

## Не ломать
- Успешный One-Click / widget pay
- Checkout one_click / Charge payload
- Auth store / refresh
- Inline error на основном экране после fail (красная плашка)

## Проверка
- `node --test test/javascript/widget_repeat_pay_flow_fallback_ui_test.mjs test/javascript/open_repeat_payment_sheet_test.mjs test/javascript/repeat_invalid_token_payment_test.mjs`
- `bin/rails test test/integration/shop/repeat_invalid_token_payment_test.rb`

## Чеклист
- [x] PHASE 0: скрины в artifacts + ТЗ UX + CBR
- [x] SPEC: todo
- [x] RED/GREEN: open sheet UI + wiring
- [x] REVIEW / ops (bugbot: cart dup fixed)
