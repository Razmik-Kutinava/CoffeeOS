# todo — T-Bank auto refund on PWA cancel (#40)

**ТЗ:** [`customer_tasks/Автоматический возврат платежа Т-Банк при отмене заказа в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Автоматический%20возврат%20платежа%20Т-Банк%20при%20отмене%20заказа%20в%20PWA.md)  
**Артефакты:** [`artifacts/tbank_auto_refund_order_cancellation_pwa/`](../milestones/veha_2/artifacts/tbank_auto_refund_order_cancellation_pwa/)  
**Фаза:** PHASE 0 `[x]` · SPEC `[x]` · шаги 1–4 GREEN `[x]` · RED шаг 5 `in_progress` · REVIEW `[ ]`  
**CBR:** #40

---

## Канон стека (маппинг ТЗ → CoffeeOS)

| В ТЗ | В репо (делать так) | Не делать |
|------|---------------------|-----------|
| RSpec / WebMock / `spec/…` | **Minitest** + stub `Net::HTTP` (как в `tbank_adapter_test`) | Не `spec/` |
| Jest + RTL + React / `src/…tsx` | **Svelte** + `test/javascript/*.mjs` (node:test) | Не React / не `any` в JSDoc |
| `OrderCancellationModal.tsx` | `app/frontend/components/OrderCancelModal.svelte` + `lib/orderCancelFlow.js` | Не раздувать `OrderStatus.svelte` (уже 754) |
| `tsc --noEmit` | JSDoc + существующий FE lint/test | Не внедрять TS ради ТЗ |

### Есть в репо (не изобретать)

| Артефакт | Путь | Статус vs ТЗ |
|----------|------|--------------|
| `Payments::TbankAdapter` | `app/services/payments/tbank_adapter.rb` (260 строк) | Init/GetState/Confirm/Charge есть; **Cancel нет** |
| Token sha256 | `build_token` | **не трогать** |
| `CONFIRMED` → `succeeded` | `TBANK_STATUS_MAP` | уже есть |
| Guest cancel API | `POST /shop/api/orders/:id/cancel` | есть |
| `GuestOrderCancellationService` | `app/services/shop/…` | pending/accepted local; **без `/v2/Cancel`** |
| Блок `preparing+` | `Order#guest_can_cancel?` + 422 | почти готов |
| CTA machine | `lib/orderStatusCtaMachine.js` | cancel только `accepted`; label «Отменить» / «Чат» |

### Глобальные ограничения (канон)

- Payload `/v2/Cancel` — **без** `Receipt`.
- Не менять переходы `preparing`/`ready`/`issued` (только deny cancel).
- Не менять `build_token`.
- Refund только если `payment.status == succeeded` (+ есть `provider_payment_id`).
- Barista cancel — **out of scope** (без автовозврата в этом эпике).

### Отклонение ТЗ (зафиксировано)

| ТЗ буквально | Канон репо |
|--------------|------------|
| `pending_payment`: «платёж не затрагивается» | `PaymentFailureJournal` → ордер `cancelled`, pending payment → **`failed`** (без T-Bank). Сохраняем journal. |
| «Написать в поддержку» | Сейчас label **«Чат»** — в шаге 5 меняем label по ТЗ (kind остаётся `chat`, URL/handler без смены флоу). |
| TypeScript / `any` | Svelte+JSDoc; запрет нетипизированных «any» в новых typedef. |

### Размер файлов

| Файл | Строк | План |
|------|-------|------|
| `tbank_adapter.rb` | **260** (>200) | Шаг 1: минимальный `#cancel_payment` по паттерну `confirm_payment` (~25 строк). Сплит адаптера — **backlog PRACTICES**, не блокер #40. |
| `guest_order_cancellation_service.rb` | 95 | Ветка refund; если >120 — вынести `Shop::GuestOrderTbankRefund` |
| `OrderStatus.svelte` | **754** | Не раздувать: модалка + flow в отдельных файлах |

### Happy path (целевой)

```text
pending_payment → GuestCancel → journal (cancelled + payment failed) → NO T-Bank
accepted + payment.succeeded → GuestCancel → TbankAdapter.cancel_payment(PaymentId)
  → Success → payment.refunded (+ Refund row) + order.cancelled → broadcast
preparing|ready|issued → 422, без изменений
```

---

## Шаги (TDD: RED → GREEN)

| # | Что | Тесты (канон) | Код | Статус |
|---|-----|---------------|-----|--------|
| 1 | `TbankAdapter#cancel_payment` → `POST /v2/Cancel` без Receipt | `test/services/payments/tbank_adapter_test.rb` | `app/services/payments/tbank_adapter.rb` | **GREEN `[x]`** |
| 2 | `pending_payment` local cancel без T-Bank | `test/services/shop/guest_order_cancellation_service_test.rb` (уточнить assert: no Cancel stub) | сервис уже есть — assert/stub | **GREEN `[x]`** (контракт; код был) |
| 3 | `accepted` + succeeded → Cancel → `refunded` + `cancelled` | guest cancel unit + stub adapter; integration `orders_guest_cancel_test` | `GuestOrderCancellationService` (+ optional thin refund helper) | **GREEN `[x]`** |
| 4 | Block `preparing`/`ready`/`issued` → 422, payment unchanged | integration + unit (усилить ready/issued + payment freeze) | deny path уже есть | **GREEN `[x]`** (контракт; код был) |
| 5 | UI CTA: cancel labels + support | `test/javascript/order_status_cta_machine_test.mjs` | `orderStatusCtaMachine.js` (+ OrderStatus wiring) | **RED** `[ ]` GREEN |
| 6 | Modal confirm для `accepted` (сумма) | `test/javascript/order_cancel_flow_test.mjs` (copy/format) | `OrderCancelModal.svelte` + flow lib | `[ ]` |
| 7 | Loading / toast success / toast 422→«Готовится» | тот же JS + manual/MCP later | `orderCancelFlow.js` + `OrderStatus.svelte` | `[ ]` |

### Критические кейсы (в шагах 1/3/7)

- Timeout / 500/504 T-Bank → API 500, ордер/платёж не «тихо» cancelled.
- Двойной cancel: UI disable + бэкенд `guest_can_cancel?` / already cancelled / already refunded.
- Payment `failed`/`refunded` при `accepted` → reject, без Cancel.
- Сумма в модалке = `order.final_amount` (формат `N ₽`).

### Регрессия зоны (после GREEN шагов / REVIEW)

```text
bin/rails test test/services/payments/tbank_adapter_test.rb \
  test/services/shop/guest_order_cancellation_service_test.rb \
  test/integration/shop/api/orders_guest_cancel_test.rb

# зона оплаты (dev-gates)
bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb \
  test/services/shop/order_creator_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb
```

FE: `node --test test/javascript/order_status_cta_machine_test.mjs test/javascript/order_cancel_flow_test.mjs` (или принятый runner репо).

---

## Out of scope / backlog

- Barista/manager auto-refund при staff cancel
- Partial refund
- Сплит `tbank_adapter.rb` / `OrderStatus.svelte`
- Drop `window.confirm` только после шага 6 (замена модалкой)

---

## Дальше

**go / ебашь** → PHASE 2 RED шаг 1 (`cancel_payment` failing test).
