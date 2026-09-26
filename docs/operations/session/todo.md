# todo — Патч 1: 22.09.2026 · Привязка способа оплаты и промо 11₽

| Поле | Значение |
|------|----------|
| **ID** | Патч 1 · 22.09.2026 · Google Doc «Привязка способа оплаты и промо 11₽» |
| **Док** | https://docs.google.com/document/d/1hP-1JZnB3J_3V-cm5Dl7bFRrCk6JWIvrZOZir250x3Y/edit |
| **Статус** | SPEC → RED |
| **Scope** | Только «Исправленный сценарий» Патча 1; остальные Subtask документа — контекст, не трогать |

## SBR: SPEC

## Файлы (ожидаемо)

- `app/services/payments/growth_promo.rb` — `available?(customer, point)` фасад существующих правил
- `app/services/shop/subscription_offer_eligibility.rb` — gate через `GrowthPromo.available?` (не копировать условия)
- `app/frontend/lib/paymentMethodI18n.js` — тексты промо из `amount_rub`, без hardcoded `11`
- `app/frontend/components/PaymentMethodsSheet.svelte` — прокинуть `promoAmountRub` в i18n
- `app/frontend/routes/Checkout.svelte` — взять `growth_promo.amount_rub` из API → sheet
- `test/services/payments/growth_promo_test.rb` — тесты `available?`
- `test/services/shop/subscription_offer_eligibility_test.rb` — приоритет 11₽ над оффером
- `test/javascript/payment_method_promo_11rub_i18n_test.mjs` — amount из конфига

## Не ломать

- Правила eligibility промо / `promo_point_settings` / дедуп phone+method_hash / antifraud — только фасад, без новых правил (`Не трогать` патча)
- Checkout/payment Init/Charge/callback — не менять механику оплаты (COMPONENT_MAP: Checkout, PaymentMethodsSheet — только promo copy + amount prop)
- `SubscriptionOfferEligibility` не дублирует условия GrowthPromo — только вызов `available?`
- Существующие тесты #75/#77 без PointCampaignSetting — поведение оффера без кампании не ломать

## Проверка

```bash
bin/rails test test/services/payments/growth_promo_test.rb test/services/shop/subscription_offer_eligibility_test.rb
node --test test/javascript/payment_method_promo_11rub_i18n_test.mjs
```

## DoD

- [ ] `Payments::GrowthPromo.available?(customer, point)` — true только при праве на промо на точке
- [ ] `SubscriptionOfferEligibility` → false пока `available?` == true
- [ ] UI: `Сохрани — счёт сегодня [amount_rub] ₽.` / nudge с `[amount_rub]` из API
- [ ] Тесты зоны зелёные; RED+GREEN коммиты
- [ ] Ops: SESSION_STATE / CHANGELOG / HANDOFF (после GREEN / REVIEW)

## Subtasks (patch v2)

- [ ] Дать читаемый метод доступности промо
- [ ] Использовать как состояние «11₽ доступно / исчерпано» в SubscriptionOfferEligibility
- [ ] Сумма промо → основной текст
- [ ] Сумма промо → nudge
