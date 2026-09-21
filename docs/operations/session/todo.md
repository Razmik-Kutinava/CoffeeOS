# todo — #73: Фискальные чеки в ЛК

| Поле | Значение |
|------|----------|
| **ID** | **#73** · 2026-09-21 |
| **Тип** | SBR · hot-path (callbacks / shop API / ЛК) |
| **Статус** | **REVIEW · CI green** · deploy апрув |
| **Ветка** | `develop` |
| **ТЗ** | [`Хранение и отображение фискальных чеков в личном кабинете.md`](../milestones/veha_2/requirements/customer_tasks/Хранение%20и%20отображение%20фискальных%20чеков%20в%20личном%20кабинете.md) |
| **Google Doc** | https://docs.google.com/document/d/1HZGokk3jaE5-HjF3YtiyaIWo9Y0EAHF35HJbFpbCER0/edit |
| **GATES** | [`fiscal_receipts_personal_cabinet/GATES.md`](../milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/GATES.md) · G1–G4 met · G5 Fly pending |
| **Схема** | [`SCHEMA.md`](../milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/SCHEMA.md) |

## Цель шага (полный SBR)

Закрыть **основную** задачу #73: `Status=RECEIPT` → `FiscalReceipt` → API заказа → секция «Чек» в ЛК (`OrderReceipt`).  
Код контура уже на `develop` (CLOSURE_PREP); SBR = контрактные тесты + добить дыры vs ТЗ (subtasks 0–30 **без** Патч 1) → REVIEW.

## Вне scope (не трогать в этом SBR)

- **Патч 1** (Google Doc) — отдельный `/patch` после закрытия задачи
- Допы заказчика: почта с QR / ИНН·КПП в истории платежей — отдельная задача
- Собственная генерация QR по ФН/ФД/ФП
- Manager finance fiscal UI · #72 Receipt.Email (только не ломать)

## SBR

- [x] PHASE 0 /start
- [x] /unlazy — G1–G4 PASS
- [x] PHASE 1 SPEC — этот файл
- [x] PHASE 2 RED — контрактные тесты дыр vs ТЗ [TDD] · `1cfb14eb`
- [x] PHASE 2 GREEN — ФН/ФД/ФП в OrderReceipt · Local PASS · `439a87af`
- [x] `/regress` (Проверка) · JS 3/3 · Rails 37/0 · G1–G4 reverify
- [x] PHASE 3 `/review` — Local · bugbot (RLS+UI fixed) · security no med+ · Entire · push/CI
- [ ] G5 Fly MCP после fiscal notify ON + deploy апрув
- [ ] **Патч 1** — отдельный `/patch`

## Файлы (ожидаемо)

1. `app/services/payments/tbank_fiscal_notification_handler.rb` — RECEIPT → create/idempotent `FiscalReceipt`
2. `app/controllers/callbacks/tbank_controller.rb` — `Status=RECEIPT` → handler · plain `OK`
3. `app/models/fiscal_receipt.rb` — хранение · enum payment/refund · unique `ofd_receipt_id`
4. `app/controllers/shop/api/orders_controller.rb` — `fiscal_receipts` / `fiscal_expected` в JSON заказа
5. `app/frontend/routes/OrderReceipt.svelte` — секция «Чек» · ссылка · ФН/ФД/ФП · «Чек формируется»
6. `test/javascript/order_fiscal_receipt_lk_test.mjs` — контракт UI #73
7. `test/integration/shop/api/order_fiscal_receipts_api_test.rb` — API FN/FD/FP + refund

### Blast-radius (соседи, не менять без нужды)

- `app/services/payments/tbank_receipt_builder.rb` — #72 contact в Init; регрессия G4
- `app/frontend/lib/orderStatusNotifyActions.js` / `ActiveOrdersAccordion.svelte` — `receiptView` = состав заказа, **не** ОФД-чек
- `app/frontend/components/OrderStatusSheet.svelte` — poll/Cable/status вне scope

## Не ломать

1. Платёжные webhook (не-RECEIPT) и checkout / Init / Confirm
2. Идемпотентность fiscal + plain `OK` (иначе ретраи Т-Банка)
3. `receiptView` / «Состав заказа» в status-sheet ≠ `OrderReceipt` ОФД
4. Авторизация PWA / возвраты / чужие платёжные провайдеры

## Проверка

```bash
node --test test/javascript/order_fiscal_receipt_lk_test.mjs
ruby bin/rails test test/services/payments/tbank_fiscal_notification_handler_test.rb test/integration/shop/api/order_fiscal_receipts_api_test.rb test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_receipt_builder_test.rb
```

GATES: `node .agents/skills/unlazy/scripts/gate-check.mjs --reverify docs/operations/milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/GATES.md`

## DoD

- [ ] Subtasks 0–30 основной задачи (без Патч 1) закрыты или явно N/A в отчёте
- [ ] Local Проверка PASS · G1–G4 reverify
- [ ] Нет своей генерации QR · нет дублей fiscal
- [ ] `/review` + G5 Fly MCP (fiscal notify ON) — ops/deploy апрув
