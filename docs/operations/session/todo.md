# todo — #76 УК — включение промо 11₽ при создании точки

| Поле | Значение |
|------|----------|
| **CBR** | #76 |
| **ТЗ** | [`customer_tasks/УК — включение промо 11₽ при создании точки.md`](../milestones/veha_2/requirements/customer_tasks/УК%20—%20включение%20промо%2011₽%20при%20создании%20точки.md) |
| **Артефакты** | [`artifacts/uk_point_campaign_promo_11rub/`](../milestones/veha_2/artifacts/uk_point_campaign_promo_11rub/) |
| **Предшественник** | #75 GrowthPromo + `card_binding_attempts` |
| **Ветка** | `develop` |
| **Модель точки** | `Tenant` (sales_point); `point_id` = `tenant.id` |
| **Parked** | #77 SPEC в `35c2cc35` — не смешивать |

## SBR

- [x] **SPEC** — файлы + Не ломать + Проверка
- [x] **RED** — `d4409c57` падающие тесты `[RED]`
- [x] **GREEN** — миграция + sync + GrowthPromo gate + УК UI `[GREEN]`
- [ ] **REVIEW** — bugbot + security · Entire · push · CI

## Файлы (ожидаемо)

1. `db/migrate/*_create_point_campaign_settings.rb` + `app/models/point_campaign_setting.rb`
2. `app/services/platform/point_campaign_settings_sync.rb`
3. `app/controllers/platform/tenants_controller.rb`
4. `app/views/platform/tenants/_form.html.erb`
5. `app/views/platform/tenants/show.html.erb`
6. `app/services/payments/growth_promo.rb` + `app/models/card_binding_attempt.rb` (`growth_count_for_point`)
7. тесты: tenants_controller + growth_promo_point_campaign + model/sync

## Не ломать

- Checkout полной суммы при выкл. чекбоксе
- Семантика `card_binding_attempts`
- УК CRUD / RBAC
- Изоляция threshold между точками

## Проверка

- `bin/rails test test/controllers/platform/tenants_controller_test.rb test/services/payments/growth_promo_test.rb test/services/payments/growth_promo_point_campaign_test.rb test/models/point_campaign_setting_test.rb test/services/platform/point_campaign_settings_sync_test.rb`
- `bin/rails test test/services/shop/order_creator_test.rb test/integration/shop/api/user_cards_sbp_accounts_test.rb`
