# todo — Задача-2: промо-цена из `point_campaign_settings`

| Поле | Значение |
|------|----------|
| **Тип** | Fix / hot-path оплата (growth promo) |
| **Цель** | `price!` / `charge_amount` / API `amount_rub` читают `promo_amount_rub` из конфига точки; единый fallback `11₽` |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Запрет** | миграции / структура `point_campaign_settings`; УК-форма точки; `card_binding_attempts`; velocity; antifraud; `TbankAdapter`; billing подписки; `INTEGRATIONS.md` |
| **GREEN sha** | `34a899d4` · Entire `01M1R4VQH6TPMM6SQ2RZ5JTM46` |
| **note** | #78 SPEC в истории (`15f24cb5`) — отдельный SBR; не смешивать |

## SBR

- [x] **SPEC** — пути + Не ломать + Проверка + решения
- [x] **RED** — failing-тесты: `promo_amount_rub=15` → 15₽; fallback без ключа → 11₽; API `amount_rub=15`
- [x] **GREEN** — `price!` / `charge_amount` / `UserCardsController` на один источник; убрать дубль констант
- [ ] **/regress** — growth/one-click suite из «Проверка»
- [ ] **REVIEW** — bugbot + security-review + Entire + push; live Point A — только после deploy (апрув)

## Решения SPEC

| # | Решение |
|---|---------|
| 1 | Канон дефолта: **`PointCampaignSetting::DEFAULT_PROMO_AMOUNT_RUB`**. `AMOUNT_RUB` — alias на этот дефолт |
| 2 | Источник: `config["promo_amount_rub"]` для `card_binding_promo`; нет ключа → DEFAULT |
| 3 | Helper `GrowthPromo.promo_amount_rub(tenant)` — `price!`, `charge_amount`, API |
| 4 | `UserCardsController` `amount_rub` из helper |
| 5 | Sync/УК/миграции — не трогать |
| 6 | Minitest, не RSpec |
| 7 | Live — после deploy |

## Файлы (ожидаемо)

1. `app/services/payments/growth_promo.rb` — helper + `price!` / `charge_amount`
2. `app/controllers/shop/api/user_cards_controller.rb` — `amount_rub`
3. `app/models/point_campaign_setting.rb` — канон DEFAULT (без смены схемы)
4. `test/services/payments/growth_promo_test.rb`
5. `test/controllers/shop/api/user_cards_controller_test.rb`

### Blast-radius

6. `test/services/payments/growth_promo_point_campaign_test.rb`
7. `app/services/platform/point_campaign_settings_sync.rb` — skip (уже использует DEFAULT)

## Не ломать

- `Payments::TbankAdapter`
- Дедуп `CardBindingAttempt` / `is_growth_event`
- Velocity / antifraud / binding step-up
- Checkout без bind → полная сумма
- Billing / `subscription_*`

## Проверка

- `bin/rails test test/services/payments/growth_promo_test.rb test/services/payments/growth_promo_point_campaign_test.rb test/controllers/shop/api/user_cards_controller_test.rb`
- `bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb test/services/shop/order_creator_test.rb`

## Чеклист

- [x] Subtask 1–3, 6: GrowthPromo 15₽ + fallback 11₽
- [x] Subtask 4–5: единый дефолт
- [x] Subtask 7–8: API `amount_rub`
- [x] Subtask 9–10: регресс дефолт + is_growth/дедуп
- [ ] Subtask 11: regress «Проверка»
- [ ] Subtask 12: live Point A — после deploy
