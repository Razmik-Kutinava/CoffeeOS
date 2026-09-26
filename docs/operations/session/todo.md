# todo — Патч 1: 22.09.2026 · Привязка способа оплаты и промо 11₽

| Поле | Значение |
|------|----------|
| **ID** | Патч 1 · 22.09.2026 · Google Doc «Привязка способа оплаты и промо 11₽» |
| **Док** | https://docs.google.com/document/d/1hP-1JZnB3J_3V-cm5Dl7bFRrCk6JWIvrZOZir250x3Y/edit |
| **Статус** | REVIEW done · CI green · deploy апрув |
| **RED** | `b5653fa1` |
| **GREEN** | `ddf8e294` |
| **fix (bugbot)** | `e687317d` · Entire `01M3EF80ZRWCQSW2HV6TG9N8B6` |
| **CI** | [`36231701455`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36231701455) success (+ Semgrep + CodeQL) |
| **Scope** | Только «Исправленный сценарий» Патча 1 |

## SBR: REVIEW done

## Файлы (ожидаемо)

- `app/services/payments/growth_promo.rb` — `available?(customer, point)`
- `app/services/shop/subscription_offer_eligibility.rb` — gate через `available?`
- `app/frontend/lib/paymentMethodI18n.js` — тексты из `amount_rub`
- `app/frontend/components/PaymentMethodsSheet.svelte` — `promoAmountRub`
- `app/frontend/routes/Checkout.svelte` — amount + clear CTA cache
- `app/frontend/routes/PaymentResult.svelte` — clear CTA cache on success
- тесты growth_promo / subscription_offer / i18n

## Не ломать

- Правила eligibility / дедуп / antifraud — только фасад
- Payment Init/Charge/callback — не менять
- COMPONENT_MAP: Checkout/PaymentMethodsSheet/PaymentResult — только promo copy + cache clear

## Проверка

```bash
bundle exec ruby -Itest test/services/payments/growth_promo_test.rb   # 20 PASS
bundle exec ruby -Itest test/services/shop/subscription_offer_eligibility_test.rb  # 7 PASS
node --test test/javascript/payment_method_promo_11rub_i18n_test.mjs  # 4 PASS
```

## DoD

- [x] `GrowthPromo.available?(customer, point)`
- [x] `SubscriptionOfferEligibility` false пока available
- [x] UI amount_rub
- [x] bugbot medium → clear CTA cache
- [x] Entire + push + CI green
- [ ] deploy — только по апруву владельца

## Subtasks (patch v2)

- [x] available? фасад
- [x] gate в SubscriptionOfferEligibility
- [x] сумма → текст / nudge
- [x] invalidate CTA cache after pay
