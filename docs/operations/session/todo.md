# todo — #78 Архитектура подписки (guest billing)

| Поле | Значение |
|------|----------|
| **CBR** | #78 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Архитектура%20подписки%20—%20планы%20биллинг%20и%20автосписание.md) |
| **Тип** | Feature / hot-path оплата + Shop API + PWA |
| **Цель** | Пилот: планы в БД, покупка через `TbankAdapter`, период с фиксацией лимитов; дальше — usage/renewal/API/UI |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` · sub-offer **OFF** |
| **Ветка** | `develop` |
| **Запрет** | правки `TbankAdapter` / `TbankReceiptBuilder` / auto-Refund; `RecurrentOrderCreator` для renewal; `card_binding_attempts`; `point_campaign_settings` / промо-11₽; antifraud; ограничение по `point_id`; tips restore |

## SBR

- [x] **SPEC** — slice-1 пути + Не ломать + Проверка + решения
- [x] **RED** — failing-тест `Subscriptions::PurchaseService` (NameError SubscriptionPlan / PurchaseService)
- [ ] **GREEN** — миграции/модели + `PurchaseService`
- [ ] **/regress** — команды из «Проверка»
- [ ] **REVIEW** — bugbot + security-review + Entire + push

## Slice backlog (после GREEN slice-1)

| Slice | Scope |
|-------|--------|
| 2 | usage events + UsagePricingService |
| 3 | CancellationService + auto_renew |
| 4 | RenewalService + jobs + past_due |
| 5 | Shop API subscriptions |
| 6 | PWA screens + CTA |
| 7 | E2E Fly |

## Решения SPEC (канон)

1. Guest `subscription_*` ≠ platform `billing_*`
2. `Subscriptions::*` вызывает `TbankAdapter` без правок адаптера
3. Технический `Order` + `Payment` для Init/Charge; после CONFIRMED → order `closed` (не barista board)
4. Snapshot периода с плана; point-agnostic usage позже
5. Тесты Minitest; план в setup (не fixtures.yml)

## Файлы (ожидаемо) — slice-1

1. `db/migrate/*_create_guest_subscription_tables.rb`
2. `app/models/subscription_plan.rb`
3. `app/models/subscription.rb`
4. `app/services/subscriptions/purchase_service.rb`
5. `test/services/subscriptions/purchase_service_test.rb`

### Blast-radius (только читать)

6. `app/services/payments/tbank_adapter.rb`
7. `app/controllers/callbacks/tbank_controller.rb`
8. `app/services/shop/recurrent_order_creator.rb` — не использовать

## Не ломать

- Checkout / GrowthPromo / промо-11₽
- Binding / RebillId / SBP / card_binding_attempts
- Webhook idempotency `tbank:callback:{PaymentId}:{Status}`
- #77 eligibility / Point A offer OFF

## Проверка

- `bin/rails test test/services/subscriptions/purchase_service_test.rb`
- `bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb test/services/shop/order_creator_test.rb`
