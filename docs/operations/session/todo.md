# todo — #78 slice-5 · Shop API subscriptions

| Поле | Значение |
|------|----------|
| **CBR / корень** | #78 · после slice-1 (models + PurchaseService + Fulfillment) |
| **ТЗ** | [`Архитектура подписки — планы биллинг и автосписание.md`](../milestones/veha_2/requirements/customer_tasks/Архитектура%20подписки%20—%20планы%20биллинг%20и%20автосписание.md) · Subtasks **24–28** |
| **Артефакты** | [`subscription_billing_architecture/`](../milestones/veha_2/artifacts/subscription_billing_architecture/) |
| **Тип** | Feat / hot-path shop API · оплата подписки |
| **Цель** | Публичный Shop API: `GET current` + `POST create` → `PurchaseService`; cancel/confirm — контракт **501** до Slice 3/4 |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **OUT** | PWA UI (6) · UsagePricing (2) · CancellationService logic (3) · Renewal*/jobs (4) · E2E Fly (7) · TbankAdapter / RecurrentOrderCreator / promo #76 / auto-Refund · Point A offer UK ops |

## Карта slices (#78)

| Slice | Содержание | Статус |
|-------|------------|--------|
| 1 | Models + PurchaseService + Fulfillment | DONE |
| **5** | Shop API (этот проход) | **GREEN** |
| 6 | PWA UI + CTA | TODO (след. намерение) |
| 2 | UsagePricing + cart | TODO |
| 3 | CancellationService | TODO |
| 4 | Renewal + jobs + confirm_payment real | TODO |
| 7 | E2E / Fly MCP | TODO |

Порядок: `5 → 6 → 2 → 3 → 4 → 7`

## Решения SPEC (зафиксировано)

| Тема | Решение |
|------|---------|
| DoD минимум | **GET** `/shop/api/subscriptions/current` + **POST** `/shop/api/subscriptions` обязательны |
| Cancel | **501** `{ error: "not_implemented", slice: 3 }` + контракт-тест; `CancellationService` **OUT** этого SBR |
| confirm_payment | **501** `{ error: "not_implemented", slice: 4 }` + контракт-тест |
| PATCH auto_renew | Реальный update `auto_renew` на current; ветки used≥1 / cancel rules — Slice 3 |
| current | Подписка customer со статусом `active` или `past_due`; нет → **404** |
| Ownership | Только session customer; чужая карта → 422; без auth → **401** |
| POST body | `plan_id` **или** `plan_code`, `payment_method_id`, optional `auto_renew` → `PurchaseService` |
| purchase_point | `@shop_tenant` |
| GET payload | `status`, `drinks_remaining`, `savings_amount`, `current_period_end`, `auto_renew`, `id`, `plan_code`, `drinks_used_this_period`, `drink_limit` |
| PurchaseService | **вызов только** |
| Gems / adapter | FakeTbankSubscription в тесте; не трогать `Payments::TbankAdapter` код |

## SBR

- [x] **SPEC** (`39544ab0`)
- [x] **RED** (`084f0451`)
- [x] **GREEN** (этот коммит)
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI

## Файлы (ожидаемо)

- `config/routes.rb` — routes subscriptions
- `app/controllers/shop/api/subscriptions_controller.rb` — **NEW**
- `test/integration/shop/api/subscriptions_api_test.rb` — **NEW**
- `docs/integrations/shop-api.md` — § Subscriptions
- `docs/integrations/INTEGRATIONS.md` — bridge-строка

### Blast-radius (соседи, не менять без нужды)

- `app/services/subscriptions/purchase_service.rb` — только вызов
- `app/services/subscriptions/payment_fulfillment.rb` — не трогать
- `test/integration/shop/api/profile_subscription_offer_test.rb` — #77

## Не ломать

1. Checkout / one-click / SBP / UserCards
2. Webhook `subscription_intent` → closed
3. #77 eligibility / `subscription_offer`
4. Idempotency `tbank:callback:{PaymentId}:{Status}`

## Проверка

- `ruby bin/rails test test/services/subscriptions/ test/integration/shop/api/subscriptions_api_test.rb` → **PASS**
- `ruby bin/rails test test/integration/shop/api/profile_subscription_offer_test.rb` → **PASS**

## Acceptance (RED→GREEN)

1. Auth + active sub → GET 200; без sub → 404; без session → 401
2. POST plan + payment_method → 201 + active
3. PATCH auto_renew → persisted
4. cancel / confirm_payment → **501**
5. IDOR → 404

## След. проходы

- **Slice 6** — PWA + CTA
- **Slice 2** — UsagePricing
- **Slice 3** — CancellationService
- **Slice 4** — Renewal + confirm_payment
- **Slice 7** — Fly MCP E2E
