# todo — #76 УК — включение промо 11₽ при создании точки

| Поле | Значение |
|------|----------|
| **CBR** | #76 |
| **ТЗ** | [`customer_tasks/УК — включение промо 11₽ при создании точки.md`](../milestones/veha_2/requirements/customer_tasks/УК%20—%20включение%20промо%2011₽%20при%20создании%20точки.md) |
| **Артефакты** | [`artifacts/uk_point_campaign_promo_11rub/`](../milestones/veha_2/artifacts/uk_point_campaign_promo_11rub/) |
| **Предшественник** | #75 GrowthPromo + `card_binding_attempts` (point_allows_promo? stub) |
| **Ветка** | `develop` |
| **Модель точки** | `Tenant` (sales_point); `point_id` = `tenant.id` |

## SBR

- [x] **SPEC** — файлы + Не ломать + Проверка
- [ ] **RED** — падающие тесты point_campaign / УК toggle / counter / gate `[RED]`
- [ ] **GREEN** — миграция + sync + GrowthPromo gate + УК UI `[GREEN]`
- [ ] **REVIEW** — bugbot + security · Entire · push · CI

## Файлы (ожидаемо)

1. `db/migrate/*_create_point_campaign_settings.rb` + `app/models/point_campaign_setting.rb` — обобщённая таблица/модель (`campaign_type`, `enabled`, `threshold`, `counter`, `config` JSONB; FK `point_id` → tenants)
2. `app/services/platform/point_campaign_settings_sync.rb` — idempotent upsert `card_binding_promo` на create/update точки; не обнулять `counter`; без наследования между точками
3. `app/controllers/platform/tenants_controller.rb` — permit toggle/threshold; вызов sync; отдать status/counter/threshold на show
4. `app/views/platform/tenants/_form.html.erb` — переключатель «Промо 11₽» + порог
5. `app/views/platform/tenants/show.html.erb` — состояние промо, счётчик, порог
6. `app/services/payments/growth_promo.rb` — `point_allows_promo?`: enabled + counter &lt; threshold (агрегат growth по `point_id`, без фильтра `method_type`)
7. `test/controllers/platform/tenants_controller_test.rb` + `test/services/payments/growth_promo_test.rb` (+ net-new model/sync тесты) — create/edit/idempotency/isolation/aggregation

### Blast-radius (соседи)

- `app/services/shop/order_creator.rb` — уже зовёт `GrowthPromo.price!`; gate точки должен отключать 11₽ без ломки полного чека
- `app/controllers/shop/api/user_cards_controller.rb` — `growth_promo.eligible` для UI checkout
- `app/frontend/components/PaymentMethodsSheet.svelte` — сумма при выкл. чекбоксе (#75; регресс subtasks 16–18)

## Не ломать

- Checkout/оплата полной суммы корзины при выкл. чекбоксе привязки (карта и СБП)
- Семантика `card_binding_attempts` / growth events (#75) — только чтение агрегата по `point_id`
- Авторизация УК (`TenantPolicy` / `uk_global_admin`) и обычный CRUD точки без промо
- Промо других точек: достижение threshold в точке A не гасит точку B

## Проверка

- `bin/rails test test/controllers/platform/tenants_controller_test.rb test/services/payments/growth_promo_test.rb test/models/point_campaign_setting_test.rb`
- `bin/rails test test/services/shop/order_creator_test.rb test/integration/shop/api/user_cards_sbp_accounts_test.rb`

> ТЗ заказчика: `npm test` / `tsc` — в CoffeeOS канон = `bin/rails test` (+ JS i18n при UI-регрессе). Миграции: `bin/rails db:migrate`.

## Чеклист ТЗ (сжато)

- [ ] 1–2 модель + `campaign_type=card_binding_promo` + config JSONB
- [ ] 3–6 УК create/edit/show toggle · counter не обнулять · без наследования
- [ ] 7–9 / 19 / 23 агрегат counter по `point_id` + `is_growth_event` (card+SBP)
- [ ] 10–11 / 20 gate промо по threshold · изоляция точек
- [ ] 12 / 21 ручное выкл. без wipe counter · idempotent upsert
- [ ] 15 без подписки
- [ ] 16–18 регресс суммы при выкл. чекбоксе (уже #75; не ломать)
- [ ] 22 интеграционные тесты API/УК

## Out of scope

- Подписочный пилот / отдельные колонки под будущие campaign_type
- Таблица `promo_point_settings`
- Matching перевыпущенной карты (#75)
- Изменения внешних интеграций / INTEGRATIONS.md
