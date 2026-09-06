# todo — #71 QA reopen: не спрашивать email повторно после чека

| Поле | Значение |
|------|----------|
| **CBR** | #71 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md) |
| **Тип** | Fix / UX · hot-path post-pay (витрина) |
| **Цель** | После первого ввода email для чека — на следующих заказах **не показывать** блок «Куда прислать чек…» |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | MCP после REVIEW/deploy |
| **Ветка** | `develop` |
| **Запрет** | email-гейт на Checkout; OTP email; gem’ы оплаты |

## SBR

- [x] **SPEC**
- [ ] **RED**
- [ ] **GREEN**
- [ ] **/regress**
- [ ] **REVIEW**

## Решение

| QA | Решение |
|----|---------|
| Запомнить почту → не спрашивать снова | `loadReceiptEmail`/`saveReceiptEmail` (tenant LS). `shouldAskReceiptEmail`. Hide `OrderSuccessEmailBlock` если email есть. Persist после submit. Skip без ввода — не писать LS. |

## Файлы (ожидаемо)

1. `app/frontend/lib/shopGuestProfile.js` — load/save receipt email
2. `app/frontend/lib/emailCollection.js` — `shouldAskReceiptEmail`
3. `app/frontend/routes/PaymentResult.svelte` — conditional block + persist
4. `test/javascript/email_collection_test.mjs` — RED asserts

## Не ломать

- Checkout без email-гейта
- Первый заказ без email — блок есть
- Skip без записи
- `POST /orders/:id/email`

## Проверка

- `node --test test/javascript/email_collection_test.mjs`
- `bundle exec rails test test/integration/shop/checkout_acceptance_cbr_test.rb`
