# todo — TASK_95: Состояние оффера подписки на гостя

| Поле | Значение |
|------|----------|
| **ID** | TASK_95 · CBR #95 |
| **Док** | [TASK-95-Состояние-оффера-подписки-на-гостя.md](../milestones/veha_2/requirements/customer_tasks/TASK-95-Состояние-оффера-подписки-на-гостя.md) |
| **Google** | https://docs.google.com/document/d/18f25SUyeTWwixkcDX9XvTedfkd8GzSO6lfjoCTNWzPA/edit?usp=drivesdk |
| **Ledger** | [GATES.md](../milestones/veha_2/artifacts/subscription_offer_guest_state/GATES.md) |
| **Тип** | новая фича · полный SBR |
| **Статус** | SPEC `[x]` · ждёт `/sbr` (RED) |

## SBR

- [x] PHASE 0 intake
- [x] /unlazy ledger (G5–G6 baseline PASS)
- [x] PHASE 1 SPEC
- [ ] PHASE 2 RED — тесты G1–G4
- [ ] PHASE 2 GREEN — код
- [ ] /regress — G5–G6
- [ ] PHASE 3 REVIEW — push/CI · deploy по апруву · G7 Fly

## Решения SPEC (по умолчанию — подтвердить до RED)

Ответ на вопросы не получен → взяты рекомендованные варианты:

1. **`profile/config` из ТЗ = `GET /shop/api/profile`.** `/shop/api/config` — tenant-level без гостя; флаги гостя кладём рядом с `eligible_for_subscription_offer`.
2. **Добавить `POST /shop/api/subscription_offer/shown`.** В ТЗ нет точки для `mark_shown` (Subtask 8 «баннер отрендерен frontend»), без неё `dismiss` недостижим. Пробел ТЗ → сообщить заказчику.
3. **`mark_purchased` — в `Subscriptions::PaymentFulfillment`**, а не в `PurchaseService`: fulfillment — единая точка активации (sync-charge и webhook redirect/СБП). `PurchaseService` не трогаем вовсе.
4. **Завершённые заказы — на текущей точке** (`SubscriptionOfferEligibility#completed_orders_count`, под RLS). Без обхода RLS.

Прочее:
- `subscription_offer_states` — **без RLS**, как `subscriptions` / `mobile_customers` (глобальные, customer-scoped): «purchased на любой точке сети» работает без обхода. Доступ — только по `customer_id` из серверной сессии.
- Промо 11₽: `SubscriptionOfferEligibility.check` уже возвращает false при `GrowthPromo.available?`; сервис всё равно явно проверяет `GrowthPromo.available?` первым (Subtask 5, явный приоритет в тестах).
- `should_show_push` = `should_show_banner` (сервис возвращает, в API не отдаём — push frontend чужая задача).
- «Гость достиг `ready`» — backend-хука в статус не добавляем: frontend на `ready` запрашивает профиль, флаг уже вычислен (`orderStatusCtaMachine.js` не трогаем).
- §5 ТЗ `npx tsc --noEmit` — не применим (Rails backend, frontend не меняется) → `bin/rails test`.

## Файлы (ожидаемо)

1. `db/migrate/20260929120000_create_subscription_offer_states.rb` — таблица: `customer_id` (uuid, unique index, FK `mobile_customers`), `status` (string, default `not_shown`), `first_shown_at`, `last_dismissed_at`, `completed_orders_count_at_dismissal` (int), `unread_since`, timestamps. Subtask 1.
2. `app/models/subscription_offer_state.rb` — `enum :status, { not_shown:, shown:, dismissed:, viewed_in_lk:, purchased: }` (string), `for_customer!` = find-or-create с rescue `RecordNotUnique`. Subtask 2–3.
3. `app/services/subscriptions/offer_presentation_service.rb` — `call` → `{ should_show_banner:, should_show_push:, has_unread_offer_in_lk: }`; `mark_shown` / `mark_dismissed` / `mark_viewed_in_lk` / `mark_purchased` (идемпотентные, с блокировкой строки). Subtask 4–17.
4. `app/controllers/shop/api/subscription_offers_controller.rb` — `shown` / `dismiss` / `viewed`; `require_customer!` как в `SubscriptionsController` (401 «Требуется авторизация»); только вызов сервиса. Subtask 19–22.
5. `config/routes.rb` — 3 POST в `shop/api` рядом с `subscriptions/*`.
6. `app/controllers/shop/api/profile_controller.rb` — +`should_show_banner`, `has_unread_offer_in_lk` в `profile_json` через сервис. Subtask 18.
7. `app/services/subscriptions/payment_fulfillment.rb` — после `subscription.save!` → `mark_purchased` (в той же транзакции вызывающего). Subtask 16.

Тесты (G1–G4) и docs:
- `test/models/subscription_offer_state_test.rb` · `test/services/subscriptions/offer_presentation_service_test.rb` · `test/integration/shop/api/subscription_offer_state_api_test.rb` · `test/integration/shop/subscription_offer_lifecycle_test.rb`
- `docs/integrations/shop-api.md` · `docs/integrations/pwa-realtime.md` · `docs/operations/session/COMPONENT_MAP.md` (Subtask 26–28)

Blast-radius (соседи, только чтение/регрессия):
- `app/services/shop/subscription_offer_eligibility.rb` — вход сервиса; запрещено менять.
- `app/services/payments/growth_promo.rb` — `available?` только читаем.
- `app/services/subscriptions/purchase_service.rb` — вызывает `PaymentFulfillment` в sync-charge; регрессия G6.

## Не ломать

- Оплата подписки: `PurchaseService` / `PaymentFulfillment` идемпотентность (повторный webhook → тот же `Subscription`, без второго `mark_purchased`-эффекта), `Payments::TbankAdapter`.
- Промо 11₽ / `GrowthPromo` / `SubscriptionOfferEligibility` / `subscription_offer_settings` — без изменений логики.
- Статус/табло: `orderStatusCtaMachine.js` и CTA на `ready` — не трогаем; `GET /shop/api/config` — контракт без изменений.
- `GET /shop/api/profile` — существующие поля и `orders_count` / `eligible_for_subscription_offer` не меняются; добавляются только 2 поля.

## Проверка

```bash
bin/rails test test/models/subscription_offer_state_test.rb test/services/subscriptions/offer_presentation_service_test.rb test/integration/shop/api/subscription_offer_state_api_test.rb test/integration/shop/subscription_offer_lifecycle_test.rb
bin/rails test test/services/shop/subscription_offer_eligibility_test.rb test/services/payments/growth_promo_test.rb test/integration/shop/api/profile_subscription_offer_test.rb test/services/subscriptions/ test/integration/shop/api/subscriptions_api_test.rb
```

Fly MCP Point A (G7, после deploy): `GET /shop/api/profile` отдаёт 2 флага · `POST subscription_offer/*` без сессии → 401 · витрина/корзина PASS.

## DoD

- [ ] Subtask 1–3: таблица + модель + одна запись на гостя (G1)
- [ ] Subtask 4–17: сервис + переходы + промо-приоритет + 3 заказа + unread + purchased (G2)
- [ ] Subtask 18–22: профиль + shown/dismiss/viewed + 401 (G3)
- [ ] Subtask 23–24: lifecycle + промо-приоритет e2e (G4)
- [ ] Subtask 25: регрессия G5–G6
- [ ] Subtask 26–28: docs integrations + COMPONENT_MAP
- [ ] G7 Fly MCP Point A (после deploy по апруву)
