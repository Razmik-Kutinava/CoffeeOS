# todo — #77 Умный показ оффера подписки (eligibility + УК)

| Поле | Значение |
|------|----------|
| **CBR** | #77 |
| **ТЗ** | [`customer_tasks/Умный показ оффера подписки — сигналы толерантности и УК-переключатель.md`](../milestones/veha_2/requirements/customer_tasks/Умный%20показ%20оффера%20подписки%20—%20сигналы%20толерантности%20и%20УК-переключатель.md) |
| **Артефакты** | [`artifacts/subscription_offer_eligibility/`](../milestones/veha_2/artifacts/subscription_offer_eligibility/) |
| **Ветка** | `develop` |
| **Модель точки** | `Tenant` (sales_point); `point_id` = `tenant.id` |
| **Parked** | #76 GREEN/regress done — REVIEW отдельно |

## SBR

- [x] **SPEC** — файлы + Не ломать + Проверка + решения §4
- [x] **RED** — `6dc4df51` падающие тесты `[RED]`
- [x] **GREEN** — миграции + сервисы + hooks + УК + Shop CTA `[GREEN]`
- [x] **/regress** — Local PASS (20+10)
- [ ] **REVIEW** — bugbot + security · Entire · push · CI · Fly MCP

## Решения SPEC (§4)

| # | Решение |
|---|---------|
| 1 | Fallback при не eligible → **tips** |
| 2 | Сигналы на **mobile_customers** timestamps |
| 3 | Пороги **per-point** |
| 4 | `completed_orders_count` = query issued/closed |
| 5 | `second_cta_mode`: `tips` \| `subscription` |

- eligibility → `GET /shop/api/profile`
- `enabled` + `second_cta_mode` → `GET /shop/api/config` → `subscription_offer`
- Absent settings ≡ enabled=false

## Файлы (ожидаемо)

1. migration + `mobile_customer` — engagement timestamps
2. migration + `subscription_offer_setting`
3. `shop/subscription_offer_eligibility.rb`
4. `profile_controller` + `config_controller`
5. push + email services + `pwa_installs_controller`
6. `platform/subscription_offer_settings_controller` + views
7. `orderStatusCtaMachine.js` + `shopPwa.js`

### Blast-radius

- OrderStatus / ActiveOrdersAccordion — прокинуть flags
- push_controller — без смены контракта
- push_register + orders_email tests

## Не ломать

- `orders_count` семантика
- CTA при enabled=false
- FCM register / orders email
- ShopPwaBanner show/hide
- Tbank / фискал / 11₽ / billing

## Проверка

- `bin/rails test test/services/shop/subscription_offer_eligibility_test.rb test/models/subscription_offer_setting_test.rb test/integration/shop/api/profile_subscription_offer_test.rb test/controllers/platform/subscription_offer_settings_controller_test.rb`
- `bin/rails test test/integration/shop/api/push_register_test.rb test/integration/shop/api/orders_email_test.rb`
