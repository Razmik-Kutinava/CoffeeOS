# todo — #73 Патч 1: fiscal OFD (2026-09-20)

| Поле | Значение |
|------|----------|
| **ID** | **#73 Патч 1** · 2026-09-21 |
| **Тип** | `/patch` · SBR · hot-path |
| **Статус** | **REVIEW · CI green** · deploy апрув |
| **Ветка** | `develop` |
| **ТЗ** | customer_tasks · **Патч 1: 2026-09-20** |
| **Google Doc** | https://docs.google.com/document/d/1HZGokk3jaE5-HjF3YtiyaIWo9Y0EAHF35HJbFpbCER0/edit |
| **GREEN** | `ced2ad97` · RED `bcaa0511` |

## Цель

Патч 1 Исправленный сценарий: 10/12/18/28 ✅ · 3 ops ⏳ · 21/26 blocked.

## SBR

- [x] SPEC / RED / GREEN / regress
- [x] PHASE 3 Local · bugbot · security
- [x] Entire attach + explain
- [x] push / CI green
- [ ] G5 / Subtask 3 fiscal notify ON
- [ ] Subtask 21/26 после payload

## Файлы

1. `app/frontend/lib/orderReceiptFiscalPoll.js`
2. `app/frontend/routes/OrderReceipt.svelte`
3. tests (js + callbacks + handler)
4. `docs/integrations/tbank.md` · COMPONENT_MAP

## Не ломать

1. Payment webhook plain OK
2. Fiscal idempotency / claim FN·FD·FP
3. receiptView / OrderStatusSheet
4. TbankFiscalRetryJob на payment_not_found

## Проверка

```bash
node --test test/javascript/order_fiscal_receipt_lk_test.mjs test/javascript/order_receipt_fiscal_poll_test.mjs
ruby bin/rails test test/services/payments/tbank_fiscal_notification_handler_test.rb test/integration/shop/api/order_fiscal_receipts_api_test.rb test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_receipt_builder_test.rb
```

## DoD

- [x] 10/12/18/28 Local PASS
- [x] bugbot + security
- [x] Entire id · CI green
- [ ] Subtask 3 ops · G5
