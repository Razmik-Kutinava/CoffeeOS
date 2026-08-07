# Repeat order invalid token — PaymentMethod BottomSheet

**ТЗ:** [`../../requirements/customer_tasks/Главный экран — повторный заказ (невалидный токен) BottomSheet выбора способа оплаты.md`](../../requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md)

## Скрины заказчика

| Файл | Контекст |
|---|---|
| `screenshots/01_payment_method_bottom_sheet_invalid_token_2026-07-27.png` | Интейк 2026-07-27: макет «Способ оплаты»: «Картой *1594», СБП, «Картой +», CTA «Оплатить» |
| `screenshots/02_fly_add_card_cta_invalid_token_2026-07-27.png` | MCP Fly v393: peek CTA «Добавить карту» при invalid token |
| `screenshots/03_payment_method_bottom_sheet_invalid_token_2026-08-07.png` | Re-intake 2026-08-07: канон UI макета (шаги 2–3) |
| `screenshots/04_fly_insufficient_funds_decline_change_card_2026-08-07.png` | **Live баг:** *5953 selected · inline «Недостаточно средств» · CTA «Отказ: смените карту» · форма новой карты **не** открыта |
| `screenshots/05_fly_new_card_form_expanded_expected_2026-08-07.png` | **Ожидание заказчика:** «Картой +» selected + NewCardForm (номер / ММ/ГГ / CVV) + CTA «Оплатить» |
| `screenshots/06_otp_bank_card_5953_low_balance_2026-08-07.png` | Контекст банка: МИР *5953 баланс **159,33 ₽** (денег на оплату нет) |
| `screenshots/07_fly_pay_connecting_spinner_5953_2026-08-07.png` | Попытка оплаты *5953: FSM «Установка соединения…» |
| `screenshots/08_fly_insufficient_funds_inline_error_again_2026-08-07.png` | Повтор отказа: снова inline + «Отказ: смените карту», форма не открыта |

## MCP / история

| Артефакт | Статус |
|---|---|
| `fly_mcp_repeat_invalid_token_2026-07-27.json` | Fly **v393** · steps 1–4, 6 PASS · step5 live charge fail — unit only |
| `mcp/fly_v439_2026-08-07/` | Fly **v439** · G1–G4 **PASS** · G7 live PARTIAL (BANK_ERROR rate-limit) · unit+bundle PASS |
