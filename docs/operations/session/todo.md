# todo — #71 Патч_1: server email prefill (не спрашивать снова)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#71** · Патч_1 2026-09-17 |
| **Тип** | **ПАТЧ** (не новая фича) · канон `TASK_PATCH.md` |
| **Статус** | `/patch` docs ready · Next: **`/sbr`** |
| **Ветка** | `develop` |
| **Канон** | `@coffeeos-task-patch` · `@spec-build-review` · `@coffeeos-commit-ops` |
| **ТЗ** | [`Email-сбор после оплаты (Callcheck-флоу).md`](../milestones/veha_2/requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md) § **Патч_1** |
| **Google** | https://docs.google.com/document/d/1igng5OvrPOKMs5NkAZ8CAQYSufJBk3i3ZTI3bTgFLY8/edit?usp=drivesdk |
| **Артефакты** | [`email_collection_after_payment/`](../milestones/veha_2/artifacts/email_collection_after_payment/) |
| **OUT** | Checkout payment flow · Callcheck · #72 Receipt/Tbank · CRM/bounce · ActiveOrders/receiptView · удаление OrderEmail · email OTP |

## SBR

- [x] `/patch` — секция Патч_1 в TASK + этот todo (Шаг 5)
- [ ] PHASE 2 RED — тесты patch v2
- [ ] PHASE 2 GREEN — реализация
- [ ] PHASE 3 `/review`

## Файлы (ожидаемо)

- `app/services/orders/email_service.rb` — писать `MobileCustomer.email` (+ clear при удалении), не только `email_collected_at`
- `app/models/mobile_customer.rb` — метод persist/clear email контакта (если нужен)
- `app/controllers/shop/api/profile_controller.rb` — уже отдаёт `email`; убедиться, что post-pay путь читает его
- `app/frontend/routes/PaymentResult.svelte` — prefill + `askReceiptEmail` с **серверного** профиля (LS fallback)
- `app/frontend/lib/emailCollection.js` — `shouldAskReceiptEmail` учитывает server email
- `test/integration/shop/api/orders_email_test.rb` — order1 save → customer.email; order2 path / idempotent
- `test/javascript/email_collection_test.mjs` — server prefill / no re-ask без LS

### Соседи (blast-radius)

- `app/controllers/shop/api/orders/email_controller.rb` — тонкий; менять только если контракт ответа
- `app/frontend/lib/shopGuestProfile.js` — LS receipt fallback; **не** удалять

## Не ломать

- `Checkout.svelte` payment/checkout / Callcheck (#89/#90/#91) — `COMPONENT_MAP` → Checkout
- #72 `TbankReceiptBuilder` / Receipt.Email|Phone
- LS `shop_receipt_email` hide после submit (v481) — оставить fallback
- ActiveOrders / `receiptView` (#83/#84)
- CRM / bounce jobs без нужды

## Проверка

- `ruby bin/rails test test/integration/shop/api/orders_email_test.rb`
- `node --test test/javascript/email_collection_test.mjs`

## DoD (Патч_1)

1. Post-pay email сохраняется на **профиле** пользователя (verified phone → `MobileCustomer.email`), не только в `OrderEmail` заказа.
2. Success screen заказа №2 без LS получает email с сервера и **предзаполняет** блок.
3. При наличии server email **не** показывать повторный «спрос» (`askReceiptEmail=false`), даже если LS пуст.
4. Изменение/очистка email обновляет профиль (Subtask 13 patch v2).
5. Повторный POST того же email — без дублей контакта/`OrderEmail`/jobs (Subtask 14 patch v2).
6. Существующие LS-hide и идемпотентность тесты зелёные.

## Исправленный сценарий (чекбокс)

- [ ] Subtask 12 (patch v2) — server prefill
- [ ] Subtask 12a (patch v2) — источник = профиль, не OrderEmail прошлого заказа
- [ ] Subtask 12b (patch v2) — без LS нет повторного запроса при server email
- [ ] Subtask 13 (patch v2) — change/clear в профиле
- [ ] Subtask 14 (patch v2) — идемпотентность user+order

## Next

`/sbr` — RED тесты Патч_1, затем GREEN.
