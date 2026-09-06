# todo — #71 QA reopen: не спрашивать email повторно после чека

| Поле | Значение |
|------|----------|
| **CBR** | #71 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md) |
| **Тип** | Fix / UX · hot-path post-pay |
| **Цель** | После первого email для чека — не показывать блок снова |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |

## SBR

- [x] **SPEC**
- [x] **RED** (`efc9fe59`)
- [x] **GREEN** (`870df0be`) · Entire `01M1V2FH9A8C7J6X35YF5RQSFE` (`79f34353`)
- [x] **/regress** — JS 16/0 · rails 10/0
- [ ] **REVIEW**

## Решение

| QA | Решение |
|----|---------|
| Запомнить → не спрашивать | `load/saveReceiptEmail` + `shouldAskReceiptEmail`; hide блок; persist после submit |

## Файлы (ожидаемо)

1. `app/frontend/lib/shopGuestProfile.js`
2. `app/frontend/lib/emailCollection.js`
3. `app/frontend/routes/PaymentResult.svelte`
4. `test/javascript/email_collection_test.mjs`

## Не ломать

- Checkout без email-гейта
- Первый заказ без email — блок есть
- Skip без записи
- `POST /orders/:id/email`

## Проверка

- `node --test test/javascript/email_collection_test.mjs`
- `bundle exec rails test test/integration/shop/checkout_acceptance_cbr_test.rb`
