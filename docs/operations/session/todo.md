# todo — #71 QA reopen: не спрашивать email повторно после чека

| Поле | Значение |
|------|----------|
| **CBR** | #71 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md) |
| **Тип** | Fix / UX · hot-path post-pay (витрина) |
| **Цель** | После первого ввода email для чека — на следующих заказах **не показывать** блок «Куда прислать чек…» |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | MCP после REVIEW/deploy (не Local-only для DoD) |
| **Ветка** | `develop` |
| **Запрет** | возвращать email-гейт на Checkout; OTP email; gem’ы оплаты; ломать submit чека / skip |

## SBR

- [x] **SPEC** — пути + Не ломать + Проверка
- [ ] **RED** — тесты: skip блока при сохранённом email; persist после submit
- [ ] **GREEN** — UI/lib + регрессия зоны
- [ ] **/regress** — команды из «Проверка»
- [ ] **REVIEW** — bugbot + security-review + Entire + push

## Решение

| # | QA | Решение |
|---|-----|---------|
| QA | Спросили почту для чека → запомнить → дальше не спрашивать | Отдельный tenant-scoped LS ключ receipt-email (без требования `name`, т.к. Callcheck). На success: если email есть → **не** рендерить `OrderSuccessEmailBlock`. После успешного `submitOrderEmail` — сохранить email. Первый заказ без email — блок как сейчас. Skip без ввода — **не** считать «запомнили». |

## Файлы (ожидаемо)

1. `app/frontend/lib/shopGuestProfile.js` — `loadReceiptEmail` / `saveReceiptEmail` (tenant LS; не ломать `loadGuestProfile` name+email)
2. `app/frontend/routes/PaymentResult.svelte` — hide email-блока если receipt email есть; persist после submit
3. `app/frontend/lib/emailCollection.js` — опционально: хелпер `shouldAskReceiptEmail` (если вынесем из Svelte)
4. `test/javascript/email_collection_test.mjs` — RED: skip-условие + save на submit path в исходниках

### Blast-radius (только читать / не ломать контракт)

5. `app/frontend/components/OrderSuccessEmailBlock.svelte` — без смены копирайта; условие снаружи
6. `app/frontend/routes/Checkout.svelte` — не трогать identityReady / phoneVerified
7. `test/integration/shop/checkout_acceptance_cbr_test.rb` — smoke зона, если заденем markup

## Не ломать

- Оплата / Callcheck phone-гейт (Checkout без email)
- Первый заказ без сохранённого email — блок «Куда прислать чек…» остаётся
- Skip без ввода → навигация на `/` без записи email
- Submit API `POST /orders/:id/email` + async receipt

## Проверка

- `node --test test/javascript/email_collection_test.mjs`
- `bundle exec rails test test/integration/shop/checkout_acceptance_cbr_test.rb`
