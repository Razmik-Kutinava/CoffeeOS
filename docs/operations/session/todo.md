# todo — #77 Умный показ оффера подписки (eligibility + УК)

| Поле | Значение |
|------|----------|
| **CBR** | #77 |
| **ТЗ** | [`customer_tasks/Умный показ оффера подписки — сигналы толерантности и УК-переключатель.md`](../milestones/veha_2/requirements/customer_tasks/Умный%20показ%20оффера%20подписки%20—%20сигналы%20толерантности%20и%20УК-переключатель.md) |
| **Артефакты** | [`artifacts/subscription_offer_eligibility/`](../milestones/veha_2/artifacts/subscription_offer_eligibility/) |
| **Ветка** | `develop` |
| **Модель точки** | `Tenant` (sales_point); `point_id` = `tenant.id` |
| **Parked** | #76 SPEC done → `/sbr` (не смешивать) |

## SBR

- [x] **SPEC** — файлы + Не ломать + Проверка + решения §4
- [ ] **RED** — падающие тесты signals / settings / eligibility / API `[RED]`
- [ ] **GREEN** — миграции + сервисы + hooks + УК + Shop CTA `[GREEN]`
- [ ] **REVIEW** — bugbot + security · Entire · push · CI · Fly MCP

## Решения SPEC (открытые вопросы ТЗ §4)

| # | Вопрос | Решение для реализации |
|---|--------|------------------------|
| 1 | Fallback при `second_cta_mode=subscription` и `eligible=false` | **Чаевые** (существующая ветка `tips` / push|wallet) — не скрывать вторую CTA |
| 2 | Где хранить сигналы | Nullable timestamps на **`mobile_customers`** (`pwa_installed_at`, `push_enabled_at`, `email_collected_at`); отдельная таблица не нужна |
| 3 | Scope порогов | **Per-point** с первого дня (`subscription_offer_settings.point_id` → `tenants.id`) |
| 4 | `completed_orders_count` | **Query** `Order.where(… status: %w[issued closed]).count` — без денормализации |
| 5 | `second_cta_mode` enum | API: **`tips`** \| **`subscription`** (дефолт `tips`) |

Дополнительно (контракт Shop):

- `eligible_for_subscription_offer` → **`GET /shop/api/profile`** (`profile_json`)
- `enabled` + `second_cta_mode` → **`GET /shop/api/config`** (point-scoped, без доверия фронту на eligibility)
- Absent settings ≡ `enabled=false` → текущая CTA-логика без оффера

## Файлы (ожидаемо)

1. `db/migrate/*_add_engagement_signals_to_mobile_customers.rb` + `app/models/mobile_customer.rb` — nullable `pwa_installed_at` / `push_enabled_at` / `email_collected_at`; first-write-wins helpers
2. `db/migrate/*_create_subscription_offer_settings.rb` + `app/models/subscription_offer_setting.rb` — point singleton: `enabled`, `second_cta_mode`, `min_completed_orders`, `required_signals_count` (1..3, default 1)
3. `app/services/shop/subscription_offer_eligibility.rb` — `check(customer, point)` → boolean; completed orders query + signal count vs settings
4. `app/controllers/shop/api/profile_controller.rb` + `app/controllers/shop/api/config_controller.rb` — флаг eligibility в profile; `enabled`/`second_cta_mode` в config
5. `app/services/shop/push_registration_service.rb` + `app/services/orders/email_service.rb` + `app/controllers/shop/api/pwa_installs_controller.rb` (новый) — фиксация первых timestamps; `POST …/pwa_install` идемпотентно
6. `app/controllers/platform/subscription_offer_settings_controller.rb` + views УК (edit/update на точке) — CRUD point-scoped настроек
7. `app/frontend/lib/orderStatusCtaMachine.js` + `app/frontend/lib/shopPwa.js` — ветка второй CTA на `ready`; `appinstalled` → backend (ошибка не ломает UI)

### Blast-radius (соседи)

- `app/frontend/routes/OrderStatus.svelte` / `ActiveOrdersAccordion.svelte` — прокинуть `eligible` + `second_cta_mode` в machine
- `app/controllers/shop/api/push_controller.rb` — без смены контракта register; только side-effect timestamp в сервисе
- `test/integration/shop/api/push_register_test.rb` + `orders_email_test.rb` — регресс hooks

## Не ломать

- Семантика `orders_count` в `profile_json` (все заказы точки) — не подменять на `completed_orders_count`
- `orderStatusCtaMachine` ветки chat / push / wallet / tips при `enabled=false` или отсутствии settings
- FCM `POST /shop/api/push/register` и `POST /shop/api/orders/:id/email` — поведение и JSON без регресса
- `ShopPwaBanner.svelte` показ/скрытие и `beforeinstallprompt` — только добавить `appinstalled` telemetry
- `Payments::TbankAdapter`, фискализация, `promo_point_settings` / 11₽, `subscription_plans` / billing

## Проверка

- `bin/rails test test/services/shop/subscription_offer_eligibility_test.rb test/models/subscription_offer_setting_test.rb test/integration/shop/api/profile_subscription_offer_test.rb test/controllers/platform/subscription_offer_settings_controller_test.rb`
- `bin/rails test test/integration/shop/api/push_register_test.rb test/integration/shop/api/orders_email_test.rb`

> ТЗ §6 `npm test` / `tsc` — в CoffeeOS канон = `bin/rails test` (+ JS unit CTA при наличии harness). Fly MCP — PHASE 3 / subtask 21.

## Чеклист ТЗ (сжато)

- [ ] Subtasks 1–5: signals + completed_orders_count + hooks
- [ ] Subtasks 6–10: settings + eligibility + APIs
- [ ] Subtasks 11–16: УК UI + Shop CTA + fallback
- [ ] Subtasks 17–19: пороги eligibility
- [ ] Subtasks 20–22: E2E / Fly / docs integrations
