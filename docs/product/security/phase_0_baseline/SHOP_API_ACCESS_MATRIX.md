# IB-0-2 — Shop API Access Matrix

**Фаза:** 0 (baseline) · обновлено Phase 1 + Phase 4 + G-06: 2026-08-31 · **0 HOLE**

Полная матрица `namespace :shop → namespace :api` из `config/routes.rb` (строки 171–224).

Kiosk (`POST /kiosk/api/auth`) и callbacks — см. [ACTORS_AND_ACCESS.md](ACTORS_AND_ACCESS.md).

Phase 1 ownership: [SHOP_API_AUTH.md](../phase_1_rbac_closure/SHOP_API_AUTH.md) · [OWNERSHIP in README](../phase_1_rbac_closure/README.md).

---

## Сводка

| Метрика | Значение |
|---------|----------|
| **Endpoints total** | **51** (50 в production без `debug`) |
| **OK** | 45 |
| **REVIEW** | 6 |
| **HOLE** | 0 (Phase 1: 4 P0 закрыты) |

### HOLE list (Phase 0 → Phase 1 FIXED)

| Path | Было | Phase 1 |
|------|------|---------|
| `GET /shop/api/payments/status/:order_id` | tenant only | **FIXED** — `OrderOwnership#find_visible_order!` |
| `POST /shop/api/payments/widget_init` | tenant only | **FIXED** |
| `POST /shop/api/payments/sbp/init` | tenant only | **FIXED** |
| `POST /shop/api/payments/sbp/charge` | charge без session gate | **FIXED** — controller visibility before service |

---

## Shop API auth model

Из `config/initializers/shop_api_auth.rb`:

| Режим | Условие | Gate |
|-------|---------|------|
| **Browser vitrina** | Referer `…/shop` + valid `X-CSRF-Token` | CSRF + Referer |
| **Server/mobile** | `X-Shop-Api-Key` или `api_key` param | `ENV["SHOP_API_KEY"]` |
| **Test** | `Rails.env.test?` | auth skip |
| **Exception** | `GET categories` | `skip authenticate_shop_api!` |

Tenant resolution (`Shop::Concerns::TenantResolution`): `tenant_id` param → `X-Shop-Tenant` header → `SHOP_DEFAULT_TENANT_ID`.

Все endpoints: `around_action :with_shop_tenant!` → `SET LOCAL app.current_tenant_id`.

---

## Паттерны ownership в коде

### 1. Strict `customer_id` scope

```ruby
Order.where(tenant_id:, source: :mobile, customer_id: cid).find(params[:id])
```

Используется в: `orders#show`, `orders#history`, `orders#active`.

### 2. `order_visible_to_session?(order)` (concern `Shop::Api::OrderOwnership`)

Проверки (любая = true):

- `CustomerSession.customer_id` == `order.customer_id`
- `PendingOrderSession.order_id` == order.id (guest checkout)
- `reconnect_token` valid via `GuestOrderReconnect.bind!`

Используется в: `orders#abandon|cancel|finalize|wallet_pass`, `orders/email#create`.

### 3. Guest resolver (email / session)

`Shop::GuestCustomerResolver` — session customer_id или verified email.

Используется в: `user_cards#index`, `frequent_products#index`, `payments#widget_init` (partial).

---

## Полная таблица endpoints

| # | Method | Path | Controller#action | Access class | Auth gate | Tenant | Ownership rule | Checks customer_id? | Pundit? | IDOR risk | Code reference | Gap / Phase 1 action |
|---|--------|------|-------------------|--------------|-----------|--------|----------------|----------------------|---------|-----------|----------------|----------------------|
| 1 | GET | `/shop/api/config` | `config#show` | PUBLIC | mixed | resolved | tenant only | no | no | OK | `config_controller.rb:6-14` | — |
| 2 | GET | `/shop/api/tenants` | `tenants#index` | GUEST | mixed | resolved | session history | no | no | OK | `tenants_controller.rb:6-8` | — |
| 3 | POST | `/shop/api/push/register` | `push#register` | CUSTOMER | mixed | resolved | `current_shop_customer` required | yes | no | OK | `push_controller.rb:11-12` | — |
| 4 | GET | `/shop/api/debug` | `debug#index` | INTERNAL | mixed | resolved | non-prod only | no | no | OK | `debug_controller.rb:9-10`, `routes.rb:175` | route absent in production |
| 5 | GET | `/shop/api/categories` | `categories#index` | PUBLIC | **none** (skip API key) | resolved | catalog public | no | no | REVIEW | `categories_controller.rb:6` | intentional public catalog; rate limit? |
| 6 | GET | `/shop/api/frequent_products` | `frequent_products#index` | GUEST | mixed | resolved | GuestCustomerResolver; empty if no customer | optional | no | OK | `frequent_products_controller.rb:8-24` | — |
| 7 | GET | `/shop/api/products` | `products#index` | PUBLIC | mixed | resolved | catalog scope | no | no | OK | `products_controller.rb:6-37` | — |
| 8 | GET | `/shop/api/products/:id` | `products#show` | PUBLIC | mixed | resolved | catalog scope | no | no | OK | `products_controller.rb:40-47` | — |
| 9 | POST | `/shop/api/cart/add` | `cart#add` | GUEST | mixed | resolved | session cart | no | no | OK | `cart_controller.rb:6-14` | session-bound |
| 10 | GET | `/shop/api/cart` | `cart#show` | GUEST | mixed | resolved | session cart | no | no | OK | `cart_controller.rb:24-26` | — |
| 11 | DELETE | `/shop/api/cart` | `cart#clear` | GUEST | mixed | resolved | session cart | no | no | OK | `cart_controller.rb:29-31` | — |
| 12 | DELETE | `/shop/api/cart/items/:index` | `cart#destroy` | GUEST | mixed | resolved | session cart | no | no | OK | `cart_controller.rb:34-40` | — |
| 13 | PATCH | `/shop/api/cart/items/:index` | `cart#update` | GUEST | mixed | resolved | session cart | no | no | OK | `cart_controller.rb:43-56` | — |
| 14 | POST | `/shop/api/email_otp/send` | `email_otp#send_code` | GUEST | mixed | resolved | rate limit in service | no | no | OK | `email_otp_controller.rb:6-10` | — |
| 15 | POST | `/shop/api/email_otp/verify` | `email_otp#verify` | GUEST | mixed | resolved | OTP verify → link customer | sets session | no | OK | `email_otp_controller.rb:13-30` | — |
| 16 | GET | `/shop/api/email_otp/status` | `email_otp#status` | GUEST | mixed | resolved | verified email in session/DB | optional | no | OK | `email_otp_controller.rb:39-54` | — |
| 17 | POST | `/shop/api/phone_otp/init_callcheck` | `phone_otp#init_callcheck` | GUEST | mixed | resolved | phone OTP | no | no | OK | `phone_otp_controller.rb:6-19` | — |
| 18 | GET | `/shop/api/phone_otp/check_status` | `phone_otp#check_status` | GUEST | mixed | resolved | callcheck session | links customer | no | OK | `phone_otp_controller.rb:26-51` | — |
| 19 | POST | `/shop/api/phone_otp/send_sms` | `phone_otp#send_sms` | GUEST | mixed | resolved | SMS OTP | no | no | OK | `phone_otp_controller.rb:62-71` | — |
| 20 | POST | `/shop/api/phone_otp/verify_sms` | `phone_otp#verify_sms` | GUEST | mixed | resolved | SMS verify → link | sets session | no | OK | `phone_otp_controller.rb:74-88` | — |
| 21 | POST | `/shop/api/phone_otp/send` | `phone_otp#send_code` | GUEST | mixed | resolved | legacy SMS | no | no | OK | `phone_otp_controller.rb:98-106` | legacy alias |
| 22 | POST | `/shop/api/phone_otp/verify` | `phone_otp#verify` | GUEST | mixed | resolved | delegates verify_sms | sets session | no | OK | `phone_otp_controller.rb:115-116` | legacy alias |
| 23 | GET | `/shop/api/phone_otp/status` | `phone_otp#status` | GUEST | mixed | resolved | phone match / auto-bind | REVIEW | no | REVIEW | `phone_otp_controller.rb:119-143` | auto `set_customer_id!` by phone lookup |
| 24 | POST | `/shop/api/orders` | `orders#create` | GUEST | mixed | resolved | OrderCreator session | optional | no | OK | `orders_controller.rb:10-19` | creates order for session/guest |
| 25 | POST | `/shop/api/payments/new_card` | `payments#new_card` | GUEST | mixed | resolved | creates order in service | via new order | no | OK | `payments_controller.rb:16-19`, `new_card_payment_service.rb` | card ownership N/A (new card) |
| 26 | POST | `/shop/api/payments/one_click` | `payments#one_click` | CUSTOMER | mixed | resolved | RecurrentOrderCreator: card.customer == customer | yes | no | OK | `one_click_payment_service.rb`, `recurrent_order_creator.rb:23-25` | — |
| 27 | POST | `/shop/api/payments/sbp/init` | `payments#sbp_init` | GUEST | mixed | resolved | `find_visible_order!` | via helper | no | **OK** | `payments_controller.rb:38-43` | Phase 1 FIXED |
| 28 | POST | `/shop/api/payments/sbp/charge` | `payments#sbp_charge` | CUSTOMER | mixed | resolved | `find_visible_order!` + service cid check | yes | no | **OK** | `payments_controller.rb:59-62` | Phase 1 FIXED |
| 29 | POST | `/shop/api/payments/widget_init` | `payments#widget_init` | GUEST | mixed | resolved | `find_visible_order!` | via helper | no | **OK** | `payments_controller.rb:80-82` | Phase 1 FIXED |
| 30 | GET | `/shop/api/payments/status/:order_id` | `payments#status` | GUEST | mixed | resolved | `find_visible_order!` | via helper | no | **OK** | `payments_controller.rb:111-122` | Phase 1 FIXED |
| 31 | GET | `/shop/api/payments/card_config` | `payments#card_config` | PUBLIC | mixed | resolved | RSA public key | no | no | OK | `payments_controller.rb:11-12` | public key by design |
| 32 | GET | `/shop/api/user/cards` | `user_cards#index` | GUEST | mixed | resolved | GuestCustomerResolver(email) | optional | no | REVIEW | `user_cards_controller.rb:8-11` | empty without customer; email param needs verified email |
| 33 | GET | `/shop/api/orders/history` | `orders#history` | CUSTOMER | mixed | resolved | `where(customer_id: cid)` | yes | no | OK | `orders_controller.rb:110-140` | empty array if no cid |
| 34 | GET | `/shop/api/orders/active` | `orders#active` | CUSTOMER | mixed | resolved | `where(customer_id: cid)` | yes | no | OK | `orders_controller.rb:147-165` | — |
| 35 | POST | `/shop/api/session/reconnect` | `session#reconnect` | GUEST | mixed | resolved | `GuestOrderReconnect` token | via token | no | OK | `session_controller.rb:6-23` | needs valid reconnect_token |
| 36 | POST | `/shop/api/session/refresh` | `session#refresh` | CUSTOMER | mixed | resolved | `MobileSession` refresh_token | yes | no | OK | `session_controller.rb:26-34` | — |
| 37 | DELETE | `/shop/api/session` | `session#destroy` | GUEST | mixed | resolved | clears session; deactivates refresh if param | REVIEW | no | REVIEW | `session_controller.rb:37-45` | anyone with refresh_token can deactivate |
| 38 | POST | `/shop/api/orders/:id/abandon` | `orders#abandon` | GUEST | mixed | resolved | `order_visible_to_session_customer?` | via helper | no | OK | `orders_controller.rb:40-45` | guest pending path by design |
| 39 | POST | `/shop/api/orders/:id/cancel` | `orders#cancel` | GUEST | mixed | resolved | `order_visible_to_session_customer?` | via helper | no | OK | `orders_controller.rb:64-68` | — |
| 40 | POST | `/shop/api/orders/:id/finalize` | `orders#finalize` | GUEST | mixed | resolved | `order_visible_to_session_customer?` | via helper | no | OK | `orders_controller.rb:84-88` | — |
| 41 | GET | `/shop/api/orders/:id/wallet_pass` | `orders#wallet_pass` | GUEST | mixed | resolved | `order_visible_to_session_customer?` | via helper | no | OK | `orders_controller.rb:169-173` | — |
| 42 | GET | `/shop/api/orders/:id` | `orders#show` | CUSTOMER | mixed | resolved | `where(customer_id: cid)` | **yes** | no | OK | `orders_controller.rb:22-31` | fixed 2026-08-28 |
| 43 | POST | `/shop/api/orders/:order_id/email` | `orders/email#create` | GUEST | mixed | resolved | `order_visible_to_session_customer?` | via helper | no | OK | `orders/email_controller.rb:6-8` | — |
| 44 | POST | `/shop/api/promo_codes/apply` | `promo_codes#apply` | GUEST | mixed | resolved | always rejects | no | no | OK | `promo_codes_controller.rb:14-16` | feature disabled |
| 45 | GET | `/shop/api/profile` | `profile#show` | CUSTOMER | mixed | resolved | `require_customer!` | yes | no | OK | `profile_controller.rb:6-8,62-67` | — |
| 46 | PATCH | `/shop/api/profile` | `profile#update` | CUSTOMER | mixed | resolved | `require_customer!` | yes | no | OK | `profile_controller.rb:12-21` | — |
| 47 | POST | `/shop/api/profile/link_email` | `profile#link_email` | CUSTOMER | mixed | resolved | `require_customer!` + OTP | yes | no | OK | `profile_controller.rb:26-37` | — |
| 48 | POST | `/shop/api/profile/link_phone` | `profile#link_phone` | CUSTOMER | mixed | resolved | `require_customer!` + OTP | yes | no | OK | `profile_controller.rb:46-51` | — |
| 49 | GET | `/shop/api/favorites` | `favorites#index` | GUEST/CUSTOMER | mixed | resolved | `FavoritesStore` session + DB if `customer_id` | yes (logged-in) | no | OK | `favorites_controller.rb:6-28` | G-06 FIXED — guest session bucket; customer persist + merge on login |
| 50 | POST | `/shop/api/favorites` | `favorites#create` | GUEST/CUSTOMER | mixed | resolved | `FavoritesStore#add!` | yes (logged-in) | no | OK | `favorites_controller.rb:31-37` | — |
| 51 | DELETE | `/shop/api/favorites/:product_id` | `favorites#destroy` | GUEST/CUSTOMER | mixed | resolved | `FavoritesStore#remove!` | yes (logged-in) | no | OK | `favorites_controller.rb:39-42` | — |

**Count check:** 51 rows = 51 routes in `routes.rb` (including `debug`; 50 in production).

---

## Phase 1 backlog (закрыто / остаток)

| Priority | Endpoint | Status |
|----------|----------|--------|
| ~~P0~~ | payments status / widget_init / sbp/init / sbp/charge | **FIXED** Phase 1 |
| P2 | `GET phone_otp/status` | REVIEW — document auto-bind |
| P2 | `DELETE session` | REVIEW — refresh_token binding |
| P3 | ~~favorites persist per customer~~ | **FIXED G-06** — `shop_customer_favorites` + `Shop::FavoritesStore` |
| P3 | `GET categories` public | OWNER REVIEW |

---

## Access class legend

| Class | Meaning |
|-------|---------|
| **PUBLIC** | Достаточно tenant (каталог, config, card_config) |
| **GUEST** | Cookie-сессия; `customer_id` опционален |
| **CUSTOMER** | Требуется `customer_id` / OTP-сессия |
| **INTERNAL** | debug (non-prod) |

## IDOR risk legend

| Risk | Meaning |
|------|---------|
| **OK** | ownership проверен или данные публичные в рамках tenant |
| **REVIEW** | осознанный компромисс / слабая привязка к customer |
| **HOLE** | чтение или действие над чужим ресурсом при знании id |
