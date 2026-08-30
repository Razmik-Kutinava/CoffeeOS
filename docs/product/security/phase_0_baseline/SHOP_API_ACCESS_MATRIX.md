# IB-0-2 — Shop API Access Matrix

**Фаза:** 0 (baseline) · **Код не менялся** · дата: 2026-08-30

Полная матрица `namespace :shop → namespace :api` из `config/routes.rb` (строки 171–224).

Kiosk (`POST /kiosk/api/auth`) и callbacks — см. [ACTORS_AND_ACCESS.md](ACTORS_AND_ACCESS.md).

---

## Сводка

| Метрика | Значение |
|---------|----------|
| **Endpoints total** | **51** (50 в production без `debug`) |
| **OK** | 38 |
| **REVIEW** | 9 |
| **HOLE** | 4 |

### HOLE list (кратко)

| Path | File:line | Проблема |
|------|-----------|----------|
| `GET /shop/api/payments/status/:order_id` | `payments_controller.rb:111-122` | Статус платежа любого заказа tenant без `customer_id` |
| `POST /shop/api/payments/widget_init` | `payments_controller.rb:80-82` | Init widget по `order_id` без ownership check |
| `POST /shop/api/payments/sbp/init` | `sbp_payment_initiator.rb:41-48` | SBP init для любого `pending_payment` заказа tenant |
| `POST /shop/api/payments/sbp/charge` | `sbp_autopay_charge_service.rb:41-58` | Charge без session: `cid = order.customer_id` — инициация оплаты чужого заказа |

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

### 2. `order_visible_to_session_customer?(order)`

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
| 27 | POST | `/shop/api/payments/sbp/init` | `payments#sbp_init` | GUEST | mixed | resolved | **tenant + order_id only** | **no** | no | **HOLE** | `sbp_payment_initiator.rb:41-48` | add `order_visible_to_session_customer?` |
| 28 | POST | `/shop/api/payments/sbp/charge` | `payments#sbp_charge` | CUSTOMER | mixed | resolved | partial: rejects session≠order customer | partial | no | **HOLE** | `sbp_autopay_charge_service.rb:52-58` | require session ownership; no charge on foreign order |
| 29 | POST | `/shop/api/payments/widget_init` | `payments#widget_init` | GUEST | mixed | resolved | **tenant + order_id only** | partial (rebill only) | no | **HOLE** | `payments_controller.rb:80-82` | add ownership before Init |
| 30 | GET | `/shop/api/payments/status/:order_id` | `payments#status` | GUEST | mixed | resolved | **tenant only** | **no** | no | **HOLE** | `payments_controller.rb:111-122` | scope by customer or visibility helper |
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
| 49 | GET | `/shop/api/favorites` | `favorites#index` | GUEST | mixed | resolved | `session[:shop_favorites]` | no | no | REVIEW | `favorites_controller.rb:8-29` | session-only, not persisted per customer |
| 50 | POST | `/shop/api/favorites` | `favorites#create` | GUEST | mixed | resolved | session array | no | no | REVIEW | `favorites_controller.rb:32-36` | — |
| 51 | DELETE | `/shop/api/favorites/:product_id` | `favorites#destroy` | GUEST | mixed | resolved | session array | no | no | REVIEW | `favorites_controller.rb:41-45` | — |

**Count check:** 51 rows = 51 routes in `routes.rb` (including `debug`; 50 in production).

---

## Phase 1 backlog (code fixes)

| Priority | Endpoint | File:line | Proposed fix (1 line) |
|----------|----------|-----------|------------------------|
| P0 | `GET payments/status/:order_id` | `payments_controller.rb:111` | After find order, `return 404 unless order_visible_to_session_customer?(order)` (extract shared concern) |
| P0 | `POST payments/widget_init` | `payments_controller.rb:80` | Same visibility check before `WidgetPaymentInitiator.call` |
| P0 | `POST payments/sbp/init` | `payments_controller.rb:38-43` | Pass session into initiator; reject unless order visible to session |
| P0 | `POST payments/sbp/charge` | `payments_controller.rb:59-62` | Require `session_cid` present and match `order.customer_id`; never charge on order_id alone |
| P2 | `GET phone_otp/status` | `phone_otp_controller.rb:136-140` | Document or restrict auto-bind; require prior OTP in session |
| P2 | `DELETE session` | `session_controller.rb:40-43` | Bind refresh_token deactivation to same customer session |
| P3 | `GET/POST/DELETE favorites` | `favorites_controller.rb` | Persist favorites per `customer_id` when logged in |
| P3 | `GET categories` | `categories_controller.rb:6` | [OWNER REVIEW] keep public or require API key on all routes |

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
