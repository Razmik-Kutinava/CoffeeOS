# todo — #72 + #73 (REVIEW done · CI watch)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| REVIEW bugbot+security+Entire+push | CI green `33149337416` | deploy — апрув |

**CBR:** #72 · #73  
**Контекст:** Receipt.Email/Phone в Init (#72) + fiscal RECEIPT webhook → ЛК (#73)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Closure:** [`artifacts/receipt_email_fiscal_checks/CLOSURE_PREP.md`](../milestones/veha_2/artifacts/receipt_email_fiscal_checks/CLOSURE_PREP.md)

## Цель шага

Закрыть подготовку обеих задач **одной пачкой** до PHASE 3 REVIEW: intake заказчика 2026-08-28, recovery runbook, регрессия, ops. **Deploy и live MCP — после апрува.**

## Статус

| Фаза | #72 | #73 |
|------|-----|-----|
| Intake | **`[x]`** редакция CONFIRMED | **`[x]`** Subtask 0, 9а, `/callbacks/tbank` |
| SPEC | **`[x]`** (ранее) | **`[x]`** (ранее) |
| RED / GREEN | **`[x]`** | **`[x]`** |
| /regress | **`[x]`** 31/0 (2026-08-28) | **`[x]`** (в составе) |
| CLOSURE_PREP | **`[x]`** | **`[x]`** |
| REVIEW | **`[x]`** bugbot · security · Entire · push | **`[x]`** |
| Deploy + Fly MCP | **`[ ]`** апрув | **`[ ]`** fiscal notify ON |

## Не ломать

- #71 post-pay email (Brevo) ≠ ОФД Receipt
- Callcheck phone как fallback контакта (#72)
- Fiscal + payment webhook plain `OK`
- `fiscal_expected` только для `provider=tbank`

## Проверка

```bash
bin/rails test \
  test/services/payments/tbank_receipt_builder_test.rb \
  test/services/payments/tbank_fiscal_notification_handler_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/integration/shop/api/order_fiscal_receipts_api_test.rb
```
