# todo — #77 Патч 1: 22.09.2026 · Умный показ оффера подписки

| Поле | Значение |
|------|----------|
| **ID** | #77 · Патч 1 · 22.09.2026 |
| **Док** | [Умный показ оффера подписки — сигналы толерантности и УК-переключатель.md](../milestones/veha_2/requirements/customer_tasks/Умный%20показ%20оффера%20подписки%20—%20сигналы%20толерантности%20и%20УК-переключатель.md) |
| **Google** | https://docs.google.com/document/d/16MJSOBP0lMtZThbrCN8IdtUUqwUQZ7XQdgPHZUktqrk/edit |
| **Статус** | REVIEW done · CI green · deploy апрув |
| **GREEN** | `18c82b91` |
| **Entire** | `01M3ESPX2CJ6Z16E5ED7RFY9BK` на `0b7f0e7f` |
| **CI** | [`36240947436`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36240947436) success (+ Semgrep + CodeQL) |
| **Scope** | Только «Исправленный сценарий» Патча 1 (Subtask 7 / 17–20 patch v2) |

## SBR: REVIEW done

## Файлы (ожидаемо)

- `app/services/shop/subscription_offer_eligibility.rb` — gate `GrowthPromo.available?`
- `app/services/payments/growth_promo.rb` — только вызов `available?`
- `test/services/shop/subscription_offer_eligibility_test.rb` — unit приоритета
- `test/integration/shop/api/profile_subscription_offer_test.rb` — profile API
- customer_tasks md — секция Патч 1

## Не ломать

- Механика 11₽ / payment binding / TbankAdapter — только чтение `available?`
- Engagement signals / `orders_count` / CTA UI — без изменений
- COMPONENT_MAP: OrderActionButtons / orderStatusCtaMachine — не трогали

## Проверка

```bash
bundle exec ruby -Itest test/services/shop/subscription_offer_eligibility_test.rb  # 7 PASS
bundle exec ruby -Itest test/integration/shop/api/profile_subscription_offer_test.rb  # 9 PASS
```

## DoD

- [x] `SubscriptionOfferEligibility` → false пока `GrowthPromo.available?`
- [x] При `available? = false` — прежние правила
- [x] Нет дублирования промо-логики
- [x] Backend-тесты приоритета (unit + profile API)
- [x] bugbot + security — clean
- [x] Entire + push + CI green
- [ ] deploy — только по апруву владельца

## Subtasks (patch v2)

- [x] Subtask 7 (patch v2): учитывать 11₽ в eligibility
- [x] Subtask 7 (patch v2): не дублировать промо-логику
- [x] Subtask 17–20 (patch v2): покрыть правило приоритета
