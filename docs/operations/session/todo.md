# todo — #71 Патч_1: server email prefill (не спрашивать снова)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#71** · Патч_1 2026-09-17 |
| **Тип** | **ПАТЧ** · канон `TASK_PATCH.md` |
| **Статус** | **REVIEW** · fix `72d90862` · push/CI |
| **RED** | `5b1e31c2` |
| **GREEN** | `55c34592` |
| **FIX** | `72d90862` review (txn + squat) |
| **Ветка** | `develop` |
| **Канон** | `@coffeeos-task-patch` · `@spec-build-review` · `@coffeeos-commit-ops` |
| **ТЗ** | [`Email-сбор после оплаты (Callcheck-флоу).md`](../milestones/veha_2/requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md) § **Патч_1** |
| **Google** | https://docs.google.com/document/d/1igng5OvrPOKMs5NkAZ8CAQYSufJBk3i3ZTI3bTgFLY8/edit?usp=drivesdk |
| **Артефакты** | [`email_collection_after_payment/`](../milestones/veha_2/artifacts/email_collection_after_payment/) |
| **OUT** | Checkout payment flow · Callcheck · #72 Receipt/Tbank · CRM/bounce · ActiveOrders/receiptView · удаление OrderEmail · email OTP |

## SBR

- [x] `/patch` — секция Патч_1 в TASK + этот todo (Шаг 5)
- [x] PHASE 2 RED — `5b1e31c2`
- [x] PHASE 2 GREEN — server email persist + PaymentResult profile
- [x] PHASE 3 `/review`

## Файлы (ожидаемо)

- `app/services/orders/email_service.rb` — `persist_customer_contact!` → `MobileCustomer.email`
- `app/frontend/routes/PaymentResult.svelte` — `api("profile")` → serverEmail prefill / ask
- `test/integration/shop/api/orders_email_test.rb` — P1 S12/12a/13/14
- `test/javascript/email_collection_test.mjs` — P1 source + shouldAsk

## Не ломать

- `Checkout.svelte` payment/checkout / Callcheck (TASK_89 / TASK_89-UI-EXT / TASK_89-POSTCALL-EXT)
- #72 `TbankReceiptBuilder` / Receipt.Email|Phone
- LS `shop_receipt_email` hide после submit (v481) — fallback
- ActiveOrders / `receiptView` (#83/#84)

## Проверка

- `ruby bin/rails test test/integration/shop/api/orders_email_test.rb` → **13/0 PASS**
- `node --test test/javascript/email_collection_test.mjs` → **21/0 PASS**

## DoD (Патч_1)

1. [x] Post-pay email → `MobileCustomer.email`
2. [x] Success №2 без LS — server prefill path в PaymentResult
3. [x] Server email → `askReceiptEmail=false` (`savedReceipt \|\| serverEmail`)
4. [x] Change/clear обновляет профиль
5. [x] Идемпотентность user+order
6. [x] LS-hide + существующие email tests зелёные

## Исправленный сценарий (чекбокс)

- [x] Subtask 12 (patch v2) — server prefill
- [x] Subtask 12a (patch v2) — источник = профиль
- [x] Subtask 12b (patch v2) — без LS нет повторного запроса при server email
- [x] Subtask 13 (patch v2) — change/clear в профиле
- [x] Subtask 14 (patch v2) — идемпотентность

## Next

`/review`
