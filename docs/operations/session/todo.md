# todo тАФ #77 ╨г╨╝╨╜╤Л╨╣ ╨┐╨╛╨║╨░╨╖ ╨╛╤Д╤Д╨╡╤А╨░ ╨┐╨╛╨┤╨┐╨╕╤Б╨║╨╕ (eligibility + ╨г╨Ъ)

| ╨Я╨╛╨╗╨╡ | ╨Ч╨╜╨░╤З╨╡╨╜╨╕╨╡ |
|------|----------|
| **CBR** | #77 |
| **╨в╨Ч** | [`customer_tasks/╨г╨╝╨╜╤Л╨╣ ╨┐╨╛╨║╨░╨╖ ╨╛╤Д╤Д╨╡╤А╨░ ╨┐╨╛╨┤╨┐╨╕╤Б╨║╨╕ тАФ ╤Б╨╕╨│╨╜╨░╨╗╤Л ╤В╨╛╨╗╨╡╤А╨░╨╜╤В╨╜╨╛╤Б╤В╨╕ ╨╕ ╨г╨Ъ-╨┐╨╡╤А╨╡╨║╨╗╤О╤З╨░╤В╨╡╨╗╤М.md`](../milestones/veha_2/requirements/customer_tasks/╨г╨╝╨╜╤Л╨╣%20╨┐╨╛╨║╨░╨╖%20╨╛╤Д╤Д╨╡╤А╨░%20╨┐╨╛╨┤╨┐╨╕╤Б╨║╨╕%20тАФ%20╤Б╨╕╨│╨╜╨░╨╗╤Л%20╤В╨╛╨╗╨╡╤А╨░╨╜╤В╨╜╨╛╤Б╤В╨╕%20╨╕%20╨г╨Ъ-╨┐╨╡╤А╨╡╨║╨╗╤О╤З╨░╤В╨╡╨╗╤М.md) |
| **╨Р╤А╤В╨╡╤Д╨░╨║╤В╤Л** | [`artifacts/subscription_offer_eligibility/`](../milestones/veha_2/artifacts/subscription_offer_eligibility/) |
| **╨Т╨╡╤В╨║╨░** | `develop` |
| **╨Ь╨╛╨┤╨╡╨╗╤М ╤В╨╛╤З╨║╨╕** | `Tenant` (sales_point); `point_id` = `tenant.id` |
| **Parked** | #76 SPEC done тЖТ `/sbr` (╨╜╨╡ ╤Б╨╝╨╡╤И╨╕╨▓╨░╤В╤М) |

## SBR

- [x] **SPEC** тАФ ╤Д╨░╨╣╨╗╤Л + ╨Э╨╡ ╨╗╨╛╨╝╨░╤В╤М + ╨Я╤А╨╛╨▓╨╡╤А╨║╨░ + ╤А╨╡╤И╨╡╨╜╨╕╤П ┬з4
- [ ] **RED** тАФ ╨┐╨░╨┤╨░╤О╤Й╨╕╨╡ ╤В╨╡╤Б╤В╤Л signals / settings / eligibility / API `[RED]`
- [ ] **GREEN** тАФ ╨╝╨╕╨│╤А╨░╤Ж╨╕╨╕ + ╤Б╨╡╤А╨▓╨╕╤Б╤Л + hooks + ╨г╨Ъ + Shop CTA `[GREEN]`
- [ ] **REVIEW** тАФ bugbot + security ┬╖ Entire ┬╖ push ┬╖ CI ┬╖ Fly MCP

## ╨а╨╡╤И╨╡╨╜╨╕╤П SPEC (╨╛╤В╨║╤А╤Л╤В╤Л╨╡ ╨▓╨╛╨┐╤А╨╛╤Б╤Л ╨в╨Ч ┬з4)

| # | ╨Т╨╛╨┐╤А╨╛╤Б | ╨а╨╡╤И╨╡╨╜╨╕╨╡ ╨┤╨╗╤П ╤А╨╡╨░╨╗╨╕╨╖╨░╤Ж╨╕╨╕ |
|---|--------|------------------------|
| 1 | Fallback ╨┐╤А╨╕ `second_cta_mode=subscription` ╨╕ `eligible=false` | **╨з╨░╨╡╨▓╤Л╨╡** (╤Б╤Г╤Й╨╡╤Б╤В╨▓╤Г╤О╤Й╨░╤П ╨▓╨╡╤В╨║╨░ `tips` / push|wallet) тАФ ╨╜╨╡ ╤Б╨║╤А╤Л╨▓╨░╤В╤М ╨▓╤В╨╛╤А╤Г╤О CTA |
| 2 | ╨У╨┤╨╡ ╤Е╤А╨░╨╜╨╕╤В╤М ╤Б╨╕╨│╨╜╨░╨╗╤Л | Nullable timestamps ╨╜╨░ **`mobile_customers`** (`pwa_installed_at`, `push_enabled_at`, `email_collected_at`); ╨╛╤В╨┤╨╡╨╗╤М╨╜╨░╤П ╤В╨░╨▒╨╗╨╕╤Ж╨░ ╨╜╨╡ ╨╜╤Г╨╢╨╜╨░ |
| 3 | Scope ╨┐╨╛╤А╨╛╨│╨╛╨▓ | **Per-point** ╤Б ╨┐╨╡╤А╨▓╨╛╨│╨╛ ╨┤╨╜╤П (`subscription_offer_settings.point_id` тЖТ `tenants.id`) |
| 4 | `completed_orders_count` | **Query** `Order.where(тАж status: %w[issued closed]).count` тАФ ╨▒╨╡╨╖ ╨┤╨╡╨╜╨╛╤А╨╝╨░╨╗╨╕╨╖╨░╤Ж╨╕╨╕ |
| 5 | `second_cta_mode` enum | API: **`tips`** \| **`subscription`** (╨┤╨╡╤Д╨╛╨╗╤В `tips`) |

╨Ф╨╛╨┐╨╛╨╗╨╜╨╕╤В╨╡╨╗╤М╨╜╨╛ (╨║╨╛╨╜╤В╤А╨░╨║╤В Shop):

- `eligible_for_subscription_offer` тЖТ **`GET /shop/api/profile`** (`profile_json`)
- `enabled` + `second_cta_mode` тЖТ **`GET /shop/api/config`** (point-scoped, ╨▒╨╡╨╖ ╨┤╨╛╨▓╨╡╤А╨╕╤П ╤Д╤А╨╛╨╜╤В╤Г ╨╜╨░ eligibility)
- Absent settings тЙб `enabled=false` тЖТ ╤В╨╡╨║╤Г╤Й╨░╤П CTA-╨╗╨╛╨│╨╕╨║╨░ ╨▒╨╡╨╖ ╨╛╤Д╤Д╨╡╤А╨░

## ╨д╨░╨╣╨╗╤Л (╨╛╨╢╨╕╨┤╨░╨╡╨╝╨╛)

1. `db/migrate/*_add_engagement_signals_to_mobile_customers.rb` + `app/models/mobile_customer.rb` тАФ nullable `pwa_installed_at` / `push_enabled_at` / `email_collected_at`; first-write-wins helpers
2. `db/migrate/*_create_subscription_offer_settings.rb` + `app/models/subscription_offer_setting.rb` тАФ point singleton: `enabled`, `second_cta_mode`, `min_completed_orders`, `required_signals_count` (1..3, default 1)
3. `app/services/shop/subscription_offer_eligibility.rb` тАФ `check(customer, point)` тЖТ boolean; completed orders query + signal count vs settings
4. `app/controllers/shop/api/profile_controller.rb` + `app/controllers/shop/api/config_controller.rb` тАФ ╤Д╨╗╨░╨│ eligibility ╨▓ profile; `enabled`/`second_cta_mode` ╨▓ config
5. `app/services/shop/push_registration_service.rb` + `app/services/orders/email_service.rb` + `app/controllers/shop/api/pwa_installs_controller.rb` (╨╜╨╛╨▓╤Л╨╣) тАФ ╤Д╨╕╨║╤Б╨░╤Ж╨╕╤П ╨┐╨╡╤А╨▓╤Л╤Е timestamps; `POST тАж/pwa_install` ╨╕╨┤╨╡╨╝╨┐╨╛╤В╨╡╨╜╤В╨╜╨╛
6. `app/controllers/platform/subscription_offer_settings_controller.rb` + views ╨г╨Ъ (edit/update ╨╜╨░ ╤В╨╛╤З╨║╨╡) тАФ CRUD point-scoped ╨╜╨░╤Б╤В╤А╨╛╨╡╨║
7. `app/frontend/lib/orderStatusCtaMachine.js` + `app/frontend/lib/shopPwa.js` тАФ ╨▓╨╡╤В╨║╨░ ╨▓╤В╨╛╤А╨╛╨╣ CTA ╨╜╨░ `ready`; `appinstalled` тЖТ backend (╨╛╤И╨╕╨▒╨║╨░ ╨╜╨╡ ╨╗╨╛╨╝╨░╨╡╤В UI)

### Blast-radius (╤Б╨╛╤Б╨╡╨┤╨╕)

- `app/frontend/routes/OrderStatus.svelte` / `ActiveOrdersAccordion.svelte` тАФ ╨┐╤А╨╛╨║╨╕╨╜╤Г╤В╤М `eligible` + `second_cta_mode` ╨▓ machine
- `app/controllers/shop/api/push_controller.rb` тАФ ╨▒╨╡╨╖ ╤Б╨╝╨╡╨╜╤Л ╨║╨╛╨╜╤В╤А╨░╨║╤В╨░ register; ╤В╨╛╨╗╤М╨║╨╛ side-effect timestamp ╨▓ ╤Б╨╡╤А╨▓╨╕╤Б╨╡
- `test/integration/shop/api/push_register_test.rb` + `orders_email_test.rb` тАФ ╤А╨╡╨│╤А╨╡╤Б╤Б hooks

## ╨Э╨╡ ╨╗╨╛╨╝╨░╤В╤М

- ╨б╨╡╨╝╨░╨╜╤В╨╕╨║╨░ `orders_count` ╨▓ `profile_json` (╨▓╤Б╨╡ ╨╖╨░╨║╨░╨╖╤Л ╤В╨╛╤З╨║╨╕) тАФ ╨╜╨╡ ╨┐╨╛╨┤╨╝╨╡╨╜╤П╤В╤М ╨╜╨░ `completed_orders_count`
- `orderStatusCtaMachine` ╨▓╨╡╤В╨║╨╕ chat / push / wallet / tips ╨┐╤А╨╕ `enabled=false` ╨╕╨╗╨╕ ╨╛╤В╤Б╤Г╤В╤Б╤В╨▓╨╕╨╕ settings
- FCM `POST /shop/api/push/register` ╨╕ `POST /shop/api/orders/:id/email` тАФ ╨┐╨╛╨▓╨╡╨┤╨╡╨╜╨╕╨╡ ╨╕ JSON ╨▒╨╡╨╖ ╤А╨╡╨│╤А╨╡╤Б╤Б╨░
- `ShopPwaBanner.svelte` ╨┐╨╛╨║╨░╨╖/╤Б╨║╤А╤Л╤В╨╕╨╡ ╨╕ `beforeinstallprompt` тАФ ╤В╨╛╨╗╤М╨║╨╛ ╨┤╨╛╨▒╨░╨▓╨╕╤В╤М `appinstalled` telemetry
- `Payments::TbankAdapter`, ╤Д╨╕╤Б╨║╨░╨╗╨╕╨╖╨░╤Ж╨╕╤П, `promo_point_settings` / 11тВ╜, `subscription_plans` / billing

## ╨Я╤А╨╛╨▓╨╡╤А╨║╨░

- `bin/rails test test/services/shop/subscription_offer_eligibility_test.rb test/models/subscription_offer_setting_test.rb test/integration/shop/api/profile_subscription_offer_test.rb test/controllers/platform/subscription_offer_settings_controller_test.rb`
- `bin/rails test test/integration/shop/api/push_register_test.rb test/integration/shop/api/orders_email_test.rb`

> ╨в╨Ч ┬з6 `npm test` / `tsc` тАФ ╨▓ CoffeeOS ╨║╨░╨╜╨╛╨╜ = `bin/rails test` (+ JS unit CTA ╨┐╤А╨╕ ╨╜╨░╨╗╨╕╤З╨╕╨╕ harness). Fly MCP тАФ PHASE 3 / subtask 21.

## ╨з╨╡╨║╨╗╨╕╤Б╤В ╨в╨Ч (╤Б╨╢╨░╤В╨╛)

- [ ] Subtasks 1тАУ5: signals + completed_orders_count + hooks
- [ ] Subtasks 6тАУ10: settings + eligibility + APIs
- [ ] Subtasks 11тАУ16: ╨г╨Ъ UI + Shop CTA + fallback
- [ ] Subtasks 17тАУ19: ╨┐╨╛╤А╨╛╨│╨╕ eligibility
- [ ] Subtasks 20тАУ22: E2E / Fly / docs integrations
