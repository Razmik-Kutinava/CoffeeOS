# todo — #73 Патч 1: fiscal OFD (2026-09-20)

| Поле | Значение |
|------|----------|
| **ID** | **#73 Патч 1** · 2026-09-21 |
| **Тип** | `/patch` · SBR · hot-path (callbacks / shop API / OrderReceipt) |
| **Статус** | **SPEC → RED** |
| **Ветка** | `develop` |
| **ТЗ** | [`Хранение и отображение фискальных чеков…`](../milestones/veha_2/requirements/customer_tasks/Хранение%20и%20отображение%20фискальных%20чеков%20в%20личном%20кабинете.md) · секция **Патч 1: 2026-09-20** |
| **Google Doc** | https://docs.google.com/document/d/1HZGokk3jaE5-HjF3YtiyaIWo9Y0EAHF35HJbFpbCER0/edit |
| **GATES** | [`fiscal_receipts_personal_cabinet/GATES.md`](../milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/GATES.md) · G5 Fly = Subtask 3 ops |

## Цель шага (только Патч 1)

Закрыть **Исправленный сценарий** Патч 1 (patch v1): Subtasks **3, 10, 12, 18, 21, 26, 28**.  
Основная задача #73 (subtasks 0–30 без патча) — **не трогать** (уже REVIEW).

| Subtask | Действие |
|---------|----------|
| **3** | Ops: fiscal notify ON → `POST /callbacks/tbank` (код готов; F0 = кабинет Т-Банка) |
| **10** | Regression: fiscal exception → HTTP 500 + release claim; `payment_not_found` → `TbankFiscalRetryJob` |
| **12** | Regression: 2-й receipt с другим `ofd_receipt_id` не перезаписывает |
| **18 / 28** | Live-refresh: poll `OrderReceipt` пока «Чек формируется» |
| **21 / 26** | **Blocked** — нет подтверждённого `Type`/payload закрытия предоплаты (запрет патча) |

## Вне scope

- Переписывать `TbankFiscalNotificationHandler` / новый `FiscalReceipt` flow
- `receiptView` / ActiveOrdersAccordion / OrderStatusSheet poll-Cable / payment business logic
- Собственный QR · предположительный Type предоплаты
- `COMPONENT_MAP.md` до Review

## SBR

- [x] PHASE 0 — патч в Google Doc + аудит vs код
- [ ] PHASE 1 SPEC — этот файл
- [ ] PHASE 2 RED — тесты дыр Патч 1 [TDD]
- [ ] PHASE 2 GREEN — poll + regression claim release
- [ ] `/regress` (Проверка)
- [ ] PHASE 3 `/review` — после GREEN
- [ ] G5 / Subtask 3 — fiscal notify ON + deploy апрув

## Файлы (ожидаемо)

1. `app/frontend/lib/orderReceiptFiscalPoll.js` — **новый** · shouldPoll + interval ms
2. `app/frontend/routes/OrderReceipt.svelte` — poll пока forming (не status-sheet)
3. `test/javascript/order_receipt_fiscal_poll_test.mjs` — контракт poll helper
4. `test/javascript/order_fiscal_receipt_lk_test.mjs` — source: poll wired
5. `test/controllers/callbacks/tbank_controller_test.rb` — fiscal 500 → release claim
6. `test/services/payments/tbank_fiscal_notification_handler_test.rb` — unique `ofd_receipt_id` + retry job (уточнение)
7. `docs/operations/milestones/veha_2/requirements/customer_tasks/Хранение и отображение фискальных чеков в личном кабинете.md` — секция Патч 1 sync

### Blast-radius (не менять)

- `ActiveOrdersAccordion.svelte` / `activeOrdersAccordion.js` / `orderStatusNotifyActions.js` — `receiptView` = #84
- `OrderStatusSheet.svelte` / `OrderStatus.svelte` — poll/Cable/dismiss
- `app/services/payments/tbank_receipt_builder.rb` — #72

## Не ломать

1. Платёжные webhook (не-RECEIPT) + plain `OK`
2. Идемпотентность fiscal (`ofd_receipt_id` / claim key с FN/FD/FP)
3. `receiptView` / «Состав заказа» ≠ ОФД `OrderReceipt` — см. COMPONENT_MAP · OrderReceipt / ActiveOrdersAccordion
4. `TbankFiscalRetryJob` на `payment_not_found` (не общий `retry_on`)

## Проверка

```bash
node --test test/javascript/order_fiscal_receipt_lk_test.mjs test/javascript/order_receipt_fiscal_poll_test.mjs
ruby bin/rails test test/services/payments/tbank_fiscal_notification_handler_test.rb test/integration/shop/api/order_fiscal_receipts_api_test.rb test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_receipt_builder_test.rb
```

## DoD

- [ ] Subtask 10 / 12 / 18 / 28 — Local PASS
- [ ] Subtask 3 — ops checklist зафиксирован; live ON = владелец (не код)
- [ ] Subtask 21 / 26 — явно blocked + открытый вопрос в ТЗ
- [ ] Не тронуты файлы из «Не трогать» / COMPONENT_MAP status-sheet
- [ ] `/review` + G5 после fiscal notify ON — отдельно
