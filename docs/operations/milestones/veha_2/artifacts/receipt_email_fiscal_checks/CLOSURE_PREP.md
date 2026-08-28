# #72 + #73 — closure prep (до REVIEW)

**Дата:** 2026-08-28  
**Ветка:** `develop`  
**Следующий шаг:** `/review` (bugbot + security + Entire) · **deploy** — только апрув владельца

---

## Вердикт кода: GREEN local

Код обеих задач на `develop`. Новой разработки в этом шаге нет — closure docs + регрессия.

| CBR | Суть | Код | Local tests | Fly MCP |
|-----|------|-----|-------------|---------|
| **#72** | `Receipt.Email` / `Phone` в Init | `TbankReceiptBuilder`, все Init-пути | PASS 31/0 (зона) | **PARTIAL** — live Init SKIP |
| **#73** | RECEIPT webhook → ЛК | `TbankFiscalNotificationHandler`, `FiscalReceipt`, PWA | PASS (в составе зоны) | **PARTIAL** — fiscal notify OFF |

---

## Subtask matrix (#72)

| Subtask | Статус | Примечание |
|---------|--------|------------|
| 1–4 checkout email | **SKIP (канон)** | #71: Callcheck → phone; email не гейт на pay |
| 5–8 Init + contact | **DONE** | `TbankReceiptBuilder.for_order!` |
| 9 Confirm | **DONE (N/A)** | Confirm без Receipt |
| 10 partial Cancel | **N/A** | нет partial Cancel+Receipt в продукте |
| 11 full Cancel | **DONE (doc)** | без Receipt (#40), касса по исходному платежу |
| 12–13 SendClosingReceipt | **N/A** | только `full_payment`; CONFIRMED — в ТЗ 2026-08-28 |
| 14–21 приёмка | **PARTIAL** | local PASS; live — после deploy + fiscal notify |
| 22 acceptance log | **PARTIAL** | `mcp/fly_v459_2026-08-27/MCP_RESULT.md` |

**Open decisions (закрыты в `docs/integrations/tbank.md`):**

- Полный Cancel без Receipt — касса Т-Банк (#40).
- SendClosingReceipt — N/A (нет prepayment в Receipt).

---

## Subtask matrix (#73)

| Subtask | Статус | Примечание |
|---------|--------|------------|
| 0 аудит | **DONE** | handler + ветки #72/#73 на develop |
| 1 схема | **DONE** | `SCHEMA.md` + example JSON |
| 2–8 handler core | **DONE** | mapping, token, idempotency |
| 9 + 9а ответ OK | **DONE** | plain `OK` fiscal + payment |
| 3 терминал | **OPS** | владелец: fiscal notify ON |
| 10–13 storage | **DONE** | `FiscalReceipt`, unique `ofd_receipt_id` |
| 14–22 PWA UI | **DONE** | API + `OrderReceipt.svelte` |
| 23 recovery | **DONE** | `RECOVERY.md` |
| 24–30 tests | **DONE** | Minitest зона |
| Fly live RECEIPT | **SKIP** | fiscal notify OFF · fr=0 |

---

## Регрессия (2026-08-28)

```bash
bin/rails test \
  test/services/payments/tbank_receipt_builder_test.rb \
  test/services/payments/tbank_fiscal_notification_handler_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/integration/shop/api/order_fiscal_receipts_api_test.rb
```

**Результат:** 31 runs, 118 assertions, **0 failures**

---

## После deploy (ops, не REVIEW)

1. Кабинет Т-Банка → fiscal notifications ON → `/callbacks/tbank`
2. Один live pay test-customer
3. MCP пачка: `MCP_DEPLOY_CHECKLIST.md` (#72) + `fiscal_receipts_personal_cabinet/mcp/`
4. Вердикт PASS только при live RECEIPT + ссылка «Чек» в ЛК

**Next:** `/review`
