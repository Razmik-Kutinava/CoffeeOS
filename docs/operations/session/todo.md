# todo — #26 QA reopen: inline надпись при отказе банка (шаг 5)

| Поле | Значение |
|------|----------|
| **CBR** | #26 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md) |
| **Тип** | Fix / hot-path оплата · PaymentMethodsSheet |
| **Цель** | Отказ банка → inline в шторке; selection сохранить; CTA → new card |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты QA** | [`…/screenshots/qa_2026-09-06/`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/screenshots/qa_2026-09-06/) |

## SBR

- [x] **SPEC**
- [x] **RED** (`58a177a1`)
- [x] **GREEN** (`32c79960`) · Entire attach `01M1V1SBJ6NVZ0K0X3RQ0CSE4Z` (амend-orphan `dcb5a861`)
- [x] **/regress** — JS 29/0 · rails 12/0 · CI GREEN `34025628548` / `34025794993`
- [x] **REVIEW** — bugbot OK · security OK · push

## Решение

| # | Решение |
|---|---------|
| 1 | `resolveCheckoutSheetInlineError` → `payFsmLabel` |
| 2 | `shouldAutoOpenNewCardOnClientError` → false; убран `$effect` |
| 3 | CTA `CLIENT_ERROR` → `onChangeCard` |

## Проверка

- `node --test test/javascript/payment_error_user_messages_test.mjs test/javascript/repeat_invalid_token_payment_test.mjs`
- `bin/rails test test/integration/shop/repeat_invalid_token_payment_test.rb`
