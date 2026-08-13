# todo — понятные сообщения при ошибке оплаты (2026-08-13)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| GREEN local texts + Retry CTA | done local | push/deploy · Fly MCP Point A |

## Цель
Доп. UX к задаче 3 / One-Click fail: понятные тексты «карта» и «Нет связи. Повторить» + CTA повтора без нового payment flow.

## Файлы (ожидаемо)
- `app/frontend/lib/shopInlinePayFsm.js` — labels + mapTbankInlineError + classify
- `app/frontend/lib/shopWidgetPayFsm.js` — export isCardErrorCode
- `app/frontend/lib/widgetRepeatPayFlow.js` — network → showRetry; card → card label
- `app/frontend/components/InlinePayFallback.svelte` — CTA «Повторить»
- `app/frontend/components/RepeatSection.svelte` — onRetry → тот же pay flow
- `app/frontend/lib/shopPayFsm.js` — labels CLIENT/NET
- `test/javascript/payment_error_user_messages_test.mjs`

## Не ломать
- Успешный One-Click / CONFIRMED
- Charge / one_click payload / API эквайринга
- PaymentMethodsSheet без дубля ошибки
- G7 CLIENT_ERROR → open_new_card

## Проверка
- `node --test …payment_error… …shop_inline… …widget_repeat…` → **17/0 PASS**
- `repeat_invalid_token_payment` → **12/0 PASS**
- `shop_pay_fsm_3ds` → **PASS**

## Чеклист
- [x] PHASE 0 intake 1:1 + CBR
- [x] SPEC todo
- [x] RED/GREEN messages + Retry
- [x] Local regression zone
- [ ] Fly MCP Point A
