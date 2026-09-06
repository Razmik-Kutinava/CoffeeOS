# todo — #26 QA reopen: inline надпись при отказе банка (шаг 5)

| Поле | Значение |
|------|----------|
| **CBR** | #26 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md) · UX [Понятные сообщения…](../milestones/veha_2/requirements/customer_tasks/Понятные%20сообщения%20пользователю%20при%20ошибке%20оплаты.md) |
| **Тип** | Fix / hot-path оплата · PaymentMethodsSheet |
| **Цель** | Отказ банка / 400/500 → inline в шторке; selection сохранить; CTA разблокировать; клик → new card |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | после GREEN / REVIEW — MCP |
| **Ветка** | `develop` |
| **Артефакты QA** | [`…/screenshots/qa_2026-09-06/`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/screenshots/qa_2026-09-06/) |

## SBR

- [x] **SPEC**
- [x] **RED** (`58a177a1`)
- [x] **GREEN**
- [ ] **/regress**
- [ ] **REVIEW**

## Баг → решение

| # | Решение |
|---|---------|
| 1 | `resolveCheckoutSheetInlineError` → `payFsmLabel` (не null, не raw message) |
| 2 | `shouldAutoOpenNewCardOnClientError` → false; убрать `$effect` auto-open в Checkout |
| 3 | CTA click `CLIENT_ERROR` → `onChangeCard` / `open_new_card` (G7 без wipe) |

## Файлы (ожидаемо)

1. `app/frontend/lib/shopPayFsm.js`
2. `app/frontend/routes/Checkout.svelte`
3. `app/frontend/components/PaymentMethodsSheet.svelte`
4. `app/frontend/components/CheckoutPayButton.svelte`
5. `test/javascript/payment_error_user_messages_test.mjs`
6. `test/javascript/repeat_invalid_token_payment_test.mjs`
7. `test/integration/shop/repeat_invalid_token_payment_test.rb`

### Blast-radius

8. `app/frontend/lib/shopInlinePayFsm.js`
9. `app/frontend/components/CartSheet.svelte`
10. `app/frontend/components/NewCardForm.svelte`

## Не ломать

- One-Click / webhook idempotency
- Invalid token → PaymentMethodsSheet (шаги 1–4, 6)
- CartSheet peek / pay-stack
- CTA при отказе карты → new card (не silent retry)

## Проверка

- `node --test test/javascript/payment_error_user_messages_test.mjs test/javascript/repeat_invalid_token_payment_test.mjs`
- `bin/rails test test/integration/shop/repeat_invalid_token_payment_test.rb`
