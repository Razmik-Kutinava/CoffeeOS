# todo — #77 Патч 1: 22.09.2026 · Умный показ оффера подписки

| Поле | Значение |
|------|----------|
| **ID** | #77 · Патч 1 · 22.09.2026 |
| **Док** | [Умный показ оффера подписки — сигналы толерантности и УК-переключатель.md](../milestones/veha_2/requirements/customer_tasks/Умный%20показ%20оффера%20подписки%20—%20сигналы%20толерантности%20и%20УК-переключатель.md) |
| **Google** | https://docs.google.com/document/d/16MJSOBP0lMtZThbrCN8IdtUUqwUQZ7XQdgPHZUktqrk/edit |
| **Статус** | GREEN · `18c82b91` |
| **GREEN** | `18c82b91` |
| **Scope** | Только «Исправленный сценарий» Патча 1 (Subtask 7 / 17–20 patch v2) |

## SBR: GREEN

## Файлы (ожидаемо)

- `app/services/shop/subscription_offer_eligibility.rb` — gate `GrowthPromo.available?` до толерантности
- `app/services/payments/growth_promo.rb` — только вызов `available?` (логику промо не трогаем)
- `test/services/shop/subscription_offer_eligibility_test.rb` — unit приоритета 11₽
- `test/integration/shop/api/profile_subscription_offer_test.rb` — profile API: false пока available / true после exhaust
- `docs/.../customer_tasks/Умный показ оффера подписки — …md` — секция Патч 1 синкнута с Google Doc

## Не ломать

- Механика 11₽ / `promo_point_settings` / дедуп / `Payments::TbankAdapter` / payment binding — только чтение через `GrowthPromo.available?`
- Engagement signals / `orders_count` / `subscription_offer_settings` CRUD — без изменений
- COMPONENT_MAP: `orderStatusCtaMachine.js` / OrderActionButtons — UI CTA не трогаем в этом патче (eligibility server-side)

## Проверка

```bash
bundle exec ruby -Itest test/services/shop/subscription_offer_eligibility_test.rb
bundle exec ruby -Itest test/integration/shop/api/profile_subscription_offer_test.rb
```

## DoD

- [x] `SubscriptionOfferEligibility` → `false` пока `GrowthPromo.available?`
- [x] При `available? = false` — прежние правила толерантности/заказов
- [x] Нет дублирования промо-логики в subscription-модуле
- [x] Backend-тесты приоритета (unit + profile API)
- [x] Секция Патч 1 в customer_tasks md
- [ ] REVIEW / push / deploy — отдельно

## Subtasks (patch v2)

- [x] Subtask 7 (patch v2): учитывать 11₽ в eligibility
- [x] Subtask 7 (patch v2): не дублировать промо-логику
- [x] Subtask 17–20 (patch v2): покрыть правило приоритета
