# Repeat order invalid token — PaymentMethod BottomSheet

**ТЗ:** [`../../requirements/customer_tasks/Главный экран — повторный заказ (невалидный токен) BottomSheet выбора способа оплаты.md`](../../requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md)

## Скрины заказчика

| Файл | Контекст |
|---|---|
| `screenshots/01_payment_method_bottom_sheet_invalid_token_2026-07-27.png` | Интейк 2026-07-27: главный экран + BottomSheet «Способ оплаты»: «Картой *1594», СБП, «Картой +», CTA «Оплатить» |
| `screenshots/02_fly_add_card_cta_invalid_token_2026-07-27.png` | MCP Fly v393: peek CTA «Добавить карту» при invalid token |
| `screenshots/03_payment_method_bottom_sheet_invalid_token_2026-08-07.png` | **Re-intake 2026-08-07:** тот же канон UI (шаги 2–3) + exit criteria сверху; карта *1594 selected, СБП серый, «Картой +», CTA «Оплатить» |

## MCP

| Артефакт | Статус |
|---|---|
| `fly_mcp_repeat_invalid_token_2026-07-27.json` | Fly **v393** · steps 1–4, 6 PASS · step5 live charge fail — unit only |
