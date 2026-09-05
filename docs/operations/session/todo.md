# todo — #78 Архитектура подписки (guest billing)

| Поле | Значение |
|------|----------|
| **CBR** | #78 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Архитектура%20подписки%20—%20планы%20биллинг%20и%20автосписание.md) |
| **Тип** | Feature / hot-path оплата + Shop API + PWA |
| **Цель** | Пилот: планы в БД, покупка через `TbankAdapter`, период с фиксацией лимитов; дальше — usage/renewal/API/UI |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` · sub-offer **OFF** (не включать без апрува) |
| **Ветка** | `develop` |
| **Запрет** | правки `Payments::TbankAdapter` / `TbankReceiptBuilder` / auto-Refund; `RecurrentOrderCreator` для renewal; `card_binding_attempts`; `point_campaign_settings` / промо-11₽; antifraud; ограничение подписки по `point_id`; дневной лимит напитков; восстановление tips |

## SBR

- [x] **SPEC** — slice-1 пути + Не ломать + Проверка + решения
- [ ] **RED** — failing-тест `Subscriptions::PurchaseService` (план + customer → active subscription + period snapshot)
- [ ] **GREEN** — миграции/модели + `PurchaseService` (Init через существующий `TbankAdapter`, без дубля Init/Charge)
- [ ] **/regress** — команды из «Проверка»
- [ ] **REVIEW** — bugbot + security-review + Entire + push; Fly E2E / offer ON — только после deploy (апрув)

## Slice backlog (после GREEN slice-1 — отдельные SBR)

| Slice | Scope | Subtasks ТЗ |
|-------|--------|-------------|
| 2 | `subscription_usage_events` + `UsagePricingService` + hook в cart/order | 4, 7–12 |
| 3 | `CancellationService` + Telegram alert; `auto_renew` | 13–14 |
| 4 | `RenewalService` + jobs + `recurring.yml` + past_due/3DS + confirm | 15–23 |
| 5 | Shop API subscriptions endpoints | 24–28 |
| 6 | PWA: checkout / «Моя подписка» / past_due / cancel modal; CTA без tips stub | 29–34 |
| 7 | E2E Fly + regress payment/growth | 35–36 |

## Решения SPEC

| # | Решение |
|---|---------|
| 1 | **Guest** таблицы: `subscription_plans` / `subscriptions` / `subscription_usage_events`. **Не** путать с platform `billing_plans` / `billing_subscriptions` |
| 2 | Namespace сервисов: `Subscriptions::*` (`app/services/subscriptions/`). Не менять `Payments::TbankAdapter` |
| 3 | Покупка: `PurchaseService` вызывает только публичные методы адаптера (`init_payment` / charge path как у существующих callers). Подписка **не** через `Shop::RecurrentOrderCreator` |
| 4 | `init_payment` требует `order:` — Purchase создаёт/привязывает платёжный `Order` (или эквивалент текущего payment-flow) **без** смены сигнатуры адаптера; форма заказа уточняется в RED по callers |
| 5 | На старте периода фиксировать `price_at_period_start`, `drink_limit_at_period_start`, `discount_percent_at_period_start` со снимка активного `SubscriptionPlan` |
| 6 | Использование **point-agnostic**: `purchase_point_id` информативен; usage event пишет фактический `point_id` заказа |
| 7 | Webhook idempotency recurring: существующий ключ `tbank:callback:{PaymentId}:{Status}` — **не** дублировать claim; Renewal/Purchase только потребляют уже обработанный callback |
| 8 | Отмена без usage → `canceled` + `TelegramAlertJob` / `AlertService` на **ручной** возврат; auto-Refund API **не** трогать |
| 9 | Subtask 29 (убрать tips из CTA) + UI экраны — **slice 6**, не в slice-1; Point A offer остаётся OFF |
| 10 | Задача-2 promo / незакоммиченный `growth_promo` — **parked**, не смешивать с #78 |
| 11 | Тесты — **Minitest** (`bin/rails test`), зеркало `test/services/subscriptions/` |

## Файлы (ожидаемо) — slice-1

1. `db/migrate/*_create_guest_subscription_tables.rb` — `subscription_plans` + `subscriptions` (+ schema `subscription_usage_events` без обязательной логики в slice-1)
2. `app/models/subscription_plan.rb` — план: code/price/limits/active + reader параметров
3. `app/models/subscription.rb` — customer/plan/status/period/auto_renew/payment_method + snapshot полей периода
4. `app/services/subscriptions/purchase_service.rb` — user-initiated покупка → active + period reset
5. `test/services/subscriptions/purchase_service_test.rb` — RED: успешная покупка + snapshot полей из плана
6. `test/fixtures/subscription_plans.yml` — активный план для тестов (или create в setup)

### Blast-radius (соседи, менять только при необходимости)

7. `app/services/payments/tbank_adapter.rb` — **только читать** API; правки запрещены ТЗ
8. `app/controllers/callbacks/tbank_controller.rb` — эталон idempotency; не дублировать ключ
9. `app/services/shop/recurrent_order_creator.rb` — **не** использовать для subscription renewal/purchase recurring

## Не ломать

- Обычный checkout / корзина / `Payments::GrowthPromo` (промо-11₽ и Задача-2)
- Привязка карт / RebillId / SBP token / `card_binding_attempts`
- T-Bank webhook idempotency `tbank:callback:{PaymentId}:{Status}`
- #77 eligibility / `subscription_offer_settings` / Point A offer OFF

## Проверка

- `bin/rails test test/services/subscriptions/purchase_service_test.rb`
- `bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb test/services/shop/order_creator_test.rb`
  (зона оплата §2.3; suite `tbank_adapter_test` — только если затронут callback path)
