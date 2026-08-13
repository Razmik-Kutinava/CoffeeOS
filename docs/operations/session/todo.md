# todo — #62 Предустановленный чекбокс автоплатежа СБП (2026-08-13)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| GREEN local JS 39/0 | done local | push/deploy · Fly MCP Point A |

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
- `node --test …shop_sbp_autopay_checkout_ui… …shop_sbp_autopay… …shop_sbp_pay…` → **39/0 PASS**

## Чеклист SBR
- [x] PHASE 0 intake 1:1 + CBR #62
- [x] SPEC todo
- [x] RED helper + tests
- [x] GREEN Checkout / PaymentMethodsSheet
- [x] Local regression zone
- [x] REVIEW ops
- [ ] Fly MCP Point A (после push/deploy)

## Subtasks (заказчик)
- [x] 1: checkbox default checked=true
- [x] 2: uncheck → save_sbp_account=false
- [x] 3: leave checked → save_sbp_account=true
- [x] 4: после UI-redraw user choice не сбрасывается
