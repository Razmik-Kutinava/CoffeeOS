# todo — Задача-2: промо-цена из `point_campaign_settings`

| Поле | Значение |
|------|----------|
| **Тип** | Fix / hot-path оплата (growth promo) |
| **Цель** | `price!` / `charge_amount` / API `amount_rub` читают `promo_amount_rub` из конфига точки; единый fallback `11₽` |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Запрет** | миграции / структура `point_campaign_settings`; УК-форма точки; `card_binding_attempts`; velocity; antifraud; `TbankAdapter`; billing подписки; `INTEGRATIONS.md` |

## SBR

- [x] **SPEC** — пути + Не ломать + Проверка + решения
- [ ] **RED** — failing-тесты: `promo_amount_rub=15` → 15₽; fallback без ключа → 11₽; API `amount_rub=15` (in progress)
- [ ] **GREEN** — `price!` / `charge_amount` / `UserCardsController` на один источник; убрать дубль констант
- [ ] **/regress** — growth/one-click suite из «Проверка»
- [ ] **REVIEW** — bugbot + security-review + Entire + push; live Point A — только после deploy (апрув)

## Решения SPEC

| # | Решение |
|---|---------|
| 1 | Канон дефолта: **`PointCampaignSetting::DEFAULT_PROMO_AMOUNT_RUB` (= 11)**. `Payments::GrowthPromo::AMOUNT_RUB` — либо удалить, либо сделать тонкий alias на этот дефолт (без второго литерала `11`) |
| 2 | Источник суммы при eligible: `point_campaign_settings.config["promo_amount_rub"]` для `campaign_type=card_binding_promo` текущей точки; нет ключа / нет записи → `DEFAULT_PROMO_AMOUNT_RUB` |
| 3 | Один helper (напр. `promo_amount_rub(tenant)`) внутри `GrowthPromo` — им пользуются `price!`, `charge_amount` и (через сервис) API |
| 4 | `Shop::Api::UserCardsController#growth_promo_payload` / anonymous payload: `amount_rub` из того же helper, **не** константа |
| 5 | Структура БД / sync / УК-форма — **не** менять; `point_campaign_settings_sync` трогать только если нужно убрать дубль литерала (оставить `DEFAULT_PROMO_AMOUNT_RUB`) |
| 6 | Тесты проекта — **Minitest** (`bin/rails test`), не RSpec из черновика задачи |
| 7 | Live-проверка конфига на тестовой точке — **после deploy** (REVIEW/апрув), не гейт GREEN |
| 8 | Предыдущий `todo` (emergency rollback subscription offer) — **закрыт ops 2026-09-05** (`enabled=false`+tips); не смешивать scope |

## Файлы (ожидаемо)

1. `app/services/payments/growth_promo.rb` — `price!` / `charge_amount` + helper чтения `promo_amount_rub`
2. `app/controllers/shop/api/user_cards_controller.rb` — `amount_rub` из того же источника
3. `app/models/point_campaign_setting.rb` — канон `DEFAULT_PROMO_AMOUNT_RUB` (без смены схемы)
4. `test/services/payments/growth_promo_test.rb` — RED: 15₽ / fallback 11₽ / регресс is_growth + дедуп
5. `test/controllers/shop/api/user_cards_controller_test.rb` — **новый**: API `amount_rub` при `promo_amount_rub=15` и дефолт 11

### Blast-radius (соседи, менять только при необходимости)

6. `test/services/payments/growth_promo_point_campaign_test.rb` — регресс point-campaign eligible
7. `app/services/platform/point_campaign_settings_sync.rb` — только если убрать дубль литерала дефолта

## Не ломать

- `Payments::TbankAdapter` и create/callback платежа (сумма уже приходит из growth; адаптер не трогаем)
- Дедуп промо: `CardBindingAttempt` по `phone` / `method_hash`; `is_growth_event` независим от суммы
- Velocity / antifraud / binding step-up
- Обычный checkout без чекбокса bind → полная сумма корзины
- Billing / `subscription_*` / CTA подписки

## Проверка

- `bin/rails test test/services/payments/growth_promo_test.rb test/services/payments/growth_promo_point_campaign_test.rb test/controllers/shop/api/user_cards_controller_test.rb`
- `bin/rails test test/integration/shop/api/qa_section_2_3_payment_cart_test.rb test/services/shop/order_creator_test.rb`  
  (зона оплата §2.3; TbankAdapter suite **не** гоняем без нужды — адаптер вне scope)

## Чеклист (Gherkin → SBR)

- [ ] Subtask 1–3, 6: RED/GREEN `GrowthPromo` — 15₽ из конфига + fallback 11₽
- [ ] Subtask 4–5: единый дефолт, без дубля литерала `11`
- [ ] Subtask 7–8: API `amount_rub` синхронен с `charge_amount`
- [ ] Subtask 9–10: регресс дефолт 11₽ + `is_growth_event`/дедуп
- [ ] Subtask 11: regress «Проверка»
- [ ] Subtask 12: live Point A — после deploy (апрув)
)
