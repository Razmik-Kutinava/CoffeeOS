# todo — #73 Патч 1: fiscal OFD (2026-09-20)

| Поле | Значение |
|------|----------|
| **ID** | **#73 Патч 1** · 2026-09-21 |
| **Тип** | `/patch` · SBR · hot-path (callbacks / shop API / OrderReceipt) |
| **Статус** | **GREEN Local** · ждать `/review` · Subtask 3 ops + 21/26 blocked |
| **Ветка** | `develop` |
| **ТЗ** | [`Хранение и отображение фискальных чеков…`](../milestones/veha_2/requirements/customer_tasks/Хранение%20и%20отображение%20фискальных%20чеков%20в%20личном%20кабинете.md) · **Патч 1: 2026-09-20** |
| **Google Doc** | https://docs.google.com/document/d/1HZGokk3jaE5-HjF3YtiyaIWo9Y0EAHF35HJbFpbCER0/edit |
| **GATES** | [`GATES.md`](../milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/GATES.md) · G5 = Subtask 3 ops |

## Цель шага (только Патч 1)

Закрыть **Исправленный сценарий** Патч 1 (patch v1).

| Subtask | Статус |
|---------|--------|
| **10** | ✅ claim release на fiscal 500 + `TbankFiscalRetryJob` на payment_not_found |
| **12** | ✅ второй receipt с уникальным `ofd_receipt_id` |
| **18 / 28** | ✅ poll `OrderReceipt` пока «Чек формируется» |
| **3** | ⏳ ops: fiscal notify ON в кабинете Т-Банка (не код) |
| **21 / 26** | ⛔ blocked — нет Type/payload закрытия предоплаты |

## SBR

- [x] PHASE 0 — патч в Google Doc + аудит
- [x] PHASE 1 SPEC — этот файл
- [x] PHASE 2 RED — `bcaa0511`
- [x] PHASE 2 GREEN — poll + regression · Local PASS
- [x] `/regress` (Проверка)
- [ ] PHASE 3 `/review`
- [ ] G5 / Subtask 3 — fiscal notify ON + deploy апрув
- [ ] Subtask 21/26 — после примера payload от Т-Банка

## Файлы (ожидаемо)

1. `app/frontend/lib/orderReceiptFiscalPoll.js` — shouldPoll + 5s
2. `app/frontend/routes/OrderReceipt.svelte` — `$effect` poll (не status-sheet)
3. `test/javascript/order_receipt_fiscal_poll_test.mjs`
4. `test/javascript/order_fiscal_receipt_lk_test.mjs`
5. `test/controllers/callbacks/tbank_controller_test.rb` — fiscal 500 → release
6. `test/services/payments/tbank_fiscal_notification_handler_test.rb` — unique ofd + max retry
7. customer_tasks + `docs/integrations/tbank.md` — Патч 1 / ops note

## Не ломать

1. Платёжные webhook (не-RECEIPT) + plain `OK`
2. Идемпотентность fiscal (`ofd_receipt_id` / claim FN/FD/FP)
3. `receiptView` / ActiveOrdersAccordion / OrderStatusSheet — COMPONENT_MAP
4. `TbankFiscalRetryJob` только на `payment_not_found`

## Проверка

```bash
node --test test/javascript/order_fiscal_receipt_lk_test.mjs test/javascript/order_receipt_fiscal_poll_test.mjs
ruby bin/rails test test/services/payments/tbank_fiscal_notification_handler_test.rb test/integration/shop/api/order_fiscal_receipts_api_test.rb test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_receipt_builder_test.rb
```

**Local:** JS 8/0 · Rails 41/0 PASS (2026-09-21)

## DoD

- [x] Subtask 10 / 12 / 18 / 28 — Local PASS
- [x] Subtask 3 — ops checklist в `tbank.md` / ТЗ; live ON = владелец
- [x] Subtask 21 / 26 — явно blocked в ТЗ
- [x] Не тронуты status-sheet / receiptView
- [ ] `/review` + G5 после fiscal notify ON
