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
| **5** | Shop API (этот проход) | **SPEC** |
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
| PATCH auto_renew | Реальный update `auto_renew` на current; ветки used≥1 / cancel rules — Slice 3 (сейчас любой bool на active/past_due) |
| current | Подписка customer со статусом `active` или `past_due` (не `canceled`/`pending`); нет → **404** |
| Ownership | Только session customer (`Shop::CustomerSession`); чужая / чужой tenant customer → **404**; без auth → **401** |
| POST body | `plan_id` **или** `plan_code`, `payment_method_id`, optional `auto_renew` (default true) → `Subscriptions::PurchaseService` |
| purchase_point | `@shop_tenant` (точка запроса); usage point-agnostic не трогаем |
| GET payload | `status`, `drinks_remaining` (= limit−used, ≥0), `savings_amount` (SUM usage events, 0 до Slice 2), `current_period_end`, `auto_renew`, плюс `id`, `plan_code`, `drinks_used_this_period`, `drink_limit` |
| PurchaseService | **вызов только**; не менять Init→Charge / technical order → closed |
| Gems / adapter | Без новых gem’ов; FakeTbank в тестах; не трогать `Payments::TbankAdapter` |
| Docs | Секция Subscriptions в `shop-api.md`; INTEGRATIONS bridge — одна строка если нет ссылки |

## SBR

- [x] **SPEC** (этот файл)
- [ ] **RED** — падающие integration tests Shop API subscriptions
- [ ] **GREEN** — controller + routes + docs + regress
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI

## Файлы (ожидаемо)

- `config/routes.rb` — routes: current / create / auto_renew / cancel / confirm_payment под `shop/api`
- `app/controllers/shop/api/subscriptions_controller.rb` — **NEW**: auth, ownership, serialize, вызов `PurchaseService`; 501 cancel/confirm
- `test/integration/shop/api/subscriptions_api_test.rb` — **NEW**: GET/POST happy+401/404; PATCH auto_renew; cancel/confirm → 501
- `docs/integrations/shop-api.md` — таблица Subscriptions (#78 slice-5)
- `docs/integrations/INTEGRATIONS.md` — bridge-строка на shop-api § Subscriptions (если ещё нет)

### Blast-radius (соседи, не менять без нужды)

- `app/services/subscriptions/purchase_service.rb` — только вызов; контракт kwargs уже есть
- `app/services/subscriptions/payment_fulfillment.rb` / webhook `subscription_intent` → **closed** — не трогать
- `test/integration/shop/api/profile_subscription_offer_test.rb` — #77 eligibility/CTA не ломать

## Не ломать

1. Checkout заказа / one-click / SBP / UserCards (`payments/*`, `user/cards`)
2. Webhook: `subscription_intent` → `PaymentFulfillment` → order **closed**, не табло barista
3. #77 eligibility / `subscription_offer` в config + profile (`eligible_for_subscription_offer`)
4. Idempotency `tbank:callback:{PaymentId}:{Status}`

## Проверка

- `ruby bin/rails test test/services/subscriptions/ test/integration/shop/api/subscriptions_api_test.rb`
- `ruby bin/rails test test/integration/shop/api/profile_subscription_offer_test.rb`

Point A (после GREEN/REVIEW, live по возможности): smoke `POST`+`GET` под guest с RebillId; иначе FakeTbank / SKIP с доказательством кода.

## Acceptance (RED→GREEN)

1. Auth guest + active sub → GET 200 с полями выше; без sub → 404; без session → 401
2. POST с `plan_code`/`plan_id` + `payment_method_id` (FakeTbank) → 201/200 + active sub; чужая карта → 4xx
3. PATCH `{ auto_renew: false }` → persisted; GET отражает
4. POST cancel / confirm_payment → **501** + стабильный JSON error
5. IDOR: подписка другого customer → 404

## След. проходы (не мешать)

- **Slice 6** — PWA screens + CTA machine; убрать tips second CTA
- **Slice 2** — UsagePricingService + cart
- **Slice 3** — CancellationService (заменить 501 cancel)
- **Slice 4** — Renewal* + real confirm_payment
- **Slice 7** — Fly MCP E2E Point A
