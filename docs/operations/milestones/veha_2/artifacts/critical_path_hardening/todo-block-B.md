# todo — #93 TASK_93-B: Checkout identity (phone vs email)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-B** |
| **Тип** | SBR · hot-path shop checkout / оплата / identity |
| **Статус** | **GREEN** · Next: `/regress` |
| **Ветка** | `develop` |
| **RED** | `f6e2f3ca` |
| **GREEN** | `2213cbeb` |
| **Entire** | `01M2STWJAMB844CP992D067NWP` на `a5ca320a` (attach; code GREEN `2213cbeb`) |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-93-B-Checkout-identity.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-B-Checkout-identity.md) |
| **GATES** | [`GATES-block-B.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-B.md) |
| **Цель** | UI «можно платить» ≡ бэкенд без 422 email при `phone_verified` |
| **OUT** | A/C/D/E… · deploy (L) |

## Канон продукта — phone-first

| ID | Решение |
|----|---------|
| **R1–R5** | phone_verified session OR email_verified → Pay; neither → 422; одна точка `Shop::CheckoutIdentity` |

## SBR

- [x] PHASE 0 `/start`
- [x] `/unlazy` — GATES-block-B
- [x] PHASE 1 `/spec`
- [x] PHASE 2 RED — `f6e2f3ca`
- [x] PHASE 2 GREEN — `CheckoutIdentity` + Checkout · `2213cbeb` · 47/0 PASS
- [ ] `/regress` — G3 zone
- [ ] PHASE 3 `/review` — таблица B1–B5 · push · без deploy

## Файлы

- `app/services/shop/checkout_identity.rb` — R1–R5
- `app/services/shop/order_creator.rb` / `recurrent_order_creator.rb`
- `app/frontend/routes/Checkout.svelte` — `identityReady = phoneVerified \|\| emailVerified`
- tests: order_creator · recurrent_order_creator · checkout_identity

## Не ломать

- Email-only pay · one_click ownership · #89 Callcheck · post-pay #71

## Проверка

```bash
ruby bin/rails test test/services/shop/order_creator_test.rb test/services/shop/recurrent_order_creator_test.rb test/integration/shop/api/checkout_identity_test.rb
ruby bin/rails test test/integration/shop/api/email_otp_checkout_test.rb test/integration/shop/shop_one_click_payment_step4_test.rb test/integration/shop/shop_new_card_payment_step2_test.rb
```
