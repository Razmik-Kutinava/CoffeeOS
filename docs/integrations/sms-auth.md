# Bridge: SMS.ru + Identity (OTP, merge, session)

## SMS.ru

| Роль | Путь |
|------|------|
| Клиент | `app/services/shop/sms_ru_client.rb` |
| Phone OTP | `app/services/shop/phone_otp.rb` |
| Email OTP | `app/services/shop/email_otp.rb` |
| Cascade ready | `OrderReadyCascadeJob` → SMS leg |
| Логи | `order_notification_logs` |

### Phone Shop API

- `POST /shop/api/phone_otp/send` · `verify` · `GET …/status`
- **Канон каналов:** `flash_call` (×2 retry) → `sms` fallback
- **`messenger` снят** (2026-08) — не восстанавливать без ТЗ

### Email Shop API

- `POST /shop/api/email_otp/send` · `verify` · `GET …/status`
- Checkout email verify + durable session issuer

### Mapping OTP

| Ключ | Где |
|------|-----|
| phone E.164 | `PhoneNormalizer` → `mobile_otp_codes`, `mobile_customers` |
| email | `mobile_otp_codes`, `shop_email_verifications` |
| код | TTL 10m, max 5 attempts |
| cooldown | flash 20s, sms 60s; Rack::Attack |

### ENV

`SMS_RU_API_ID` · `SMS_RU_FROM` · dev без ключа → код в лог

### Edge cases

- SMS.ru down → `SmsRuClient::Error`
- Cooldown → `PhoneOtp::Error`
- User online WS → SMS skip (`OrderReadyPresence`)
- SMS >70 chars → `ValidationError`

---

## Durable session (PWA)

| Роль | Путь |
|------|------|
| Refresh | `Shop::SessionRefresh` |
| Issuer | `Shop::MobileSessionIssuer` (on OTP verify) |
| Cookie | `config/initializers/session_store.rb` — 90d, `_coffeeos_session` |
| FE | `shopLocalStorage.js` — `shop_refresh_token`, sliding TTL |

| Method | Body | Success |
|--------|------|---------|
| `POST /shop/api/session/refresh` | `{ refresh_token }` | 200 + new token + profile |
| | invalid/expired | 401 |

**Mapping `mobile_sessions`:** `customer_id`, `refresh_token`, `expires_at`, `is_active`, `last_used_at`

**Edge:** ротация — старый token после refresh → 401. Слабая Rails session + пустой `user/cards` в repeat-flow.

**Tests:** `session_refresh_test.rb` · `guest_session_restore_test.rb`

---

## Identity & merge

**«Одно чиним — другое ломается»** — два `mobile_customers` на один phone/email.

| Роль | Путь |
|------|------|
| Merge | `app/services/shop/customer_profile_merger.rb` |
| Link | `POST profile/link_email` · `link_phone` |

### Mapping

| Ключ | Правило |
|------|---------|
| phone | `link_phone!` → merge donor→survivor |
| email | `link_email!` → merge |
| customer_id | FK orders, **cards**, push, loyalty |

### Перенос при merge

orders · **mobile_payment_methods** · mobile_sessions · push_notifications · mobile_carts · loyalty_accounts · order_feedback · promo_code_usages

**Не ломать:** transaction + lock; donor soft-deactivate.

### Edge cases

- Два профиля / один телефон → `profile_merge_test.rb`
- Гость→регистрация → merge при verify/link
- **Запрещено:** тестовый OTP на профиле заказчика (Point A / DEMO_LOGINS)

---

## Проверка

```bash
bin/rails test test/services/shop/sms_ru_client_test.rb
bin/rails test test/integration/shop/api/phone_otp_test.rb
bin/rails test test/integration/shop/api/email_otp_checkout_test.rb
bin/rails test test/integration/shop/api/profile_merge_test.rb
bin/rails test test/integration/shop/api/session_refresh_test.rb
bin/rails test test/integration/shop/auth_funnel_wizard_ui_test.rb
```
