# todo — #62 Предустановленный чекбокс автоплатежа СБП (2026-08-13)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 0 intake | SPEC → RED | helper default + Checkout wiring |

## Цель
Чекбокс «Привязать счет для покупок в один клик» checked по умолчанию; снятие → `save_sbp_account=false`; выбор пользователя не сбрасывается при UI-redraw. Backend #34 не трогаем.

## Файлы (ожидаемо)
- `app/frontend/lib/shopSbpAutopay.js` — `DEFAULT_SAVE_SBP_ACCOUNT` + `resolveSaveSbpAccountForSbpMode`
- `app/frontend/routes/Checkout.svelte` — default true + touched + onSelectSbp / loadSavedCards
- `app/frontend/components/PaymentMethodsSheet.svelte` — bindable default true + notify user toggle
- `test/javascript/shop_sbp_autopay_checkout_ui_test.mjs` — RED/GREEN сценарии 1–4

## Не ломать
- Оплата картой / NewCard / One-Click
- Обычный СБП Init без привязки (uncheck → без `save_sbp_account`)
- Zero-Click `sbp_account` + CHARGE_DECLINED fallback (force `saveSbpAccount: false`)
- Корзина / сумма заказа / AccountToken backend

## Проверка
- `node --test test/javascript/shop_sbp_autopay_checkout_ui_test.mjs test/javascript/shop_sbp_autopay_test.mjs test/javascript/shop_sbp_pay_test.mjs`
- (опц.) `bin/rails test test/integration/shop/api/sbp_init_save_account_test.rb` — контракт API без изменений

## Чеклист SBR
- [x] PHASE 0 intake 1:1 + CBR #62
- [x] SPEC todo
- [ ] RED helper + tests
- [ ] GREEN Checkout / PaymentMethodsSheet
- [ ] Local regression zone
- [ ] REVIEW ops
- [ ] Fly MCP Point A (после push/deploy)

## Subtasks (заказчик)
- [ ] 1: checkbox default checked=true
- [ ] 2: uncheck → save_sbp_account=false
- [ ] 3: leave checked → save_sbp_account=true
- [ ] 4: после UI-redraw user choice не сбрасывается
