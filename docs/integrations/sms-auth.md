# Bridge: SMS.ru + Identity (OTP, merge)

## SMS.ru

| Роль | Путь |
|------|------|
| Клиент | `app/services/shop/sms_ru_client.rb` |
| OTP | `app/services/shop/phone_otp.rb` |
| Cascade ready | `OrderReadyCascadeJob` → `OrderReadyPaidNotifier` |
| Логи | `order_notification_logs` |

### Shop API

- `POST …/phone_otp/send` · `verify` · `GET …/status`
- Каналы: **`flash_call`** → **`sms`** fallback. `messenger` **снят**.

### Mapping OTP

| Ключ | Где |
|------|-----|
| phone E.164 | `PhoneNormalizer` → `mobile_otp_codes`, `mobile_customers` |
| код | `mobile_otp_codes` (TTL 10m, max 5 attempts) |
| cooldown | flash 20s, sms 60s; Rack::Attack |

### ENV

`SMS_RU_API_ID` · `SMS_RU_FROM` · dev без ключа → код в лог

### Edge cases

- SMS.ru down → `SmsRuClient::Error`
- Cooldown → `PhoneOtp::Error`
- User online WS → SMS skip (`OrderReadyPresence`)
- SMS >70 chars → `ValidationError`

### Проверка

```bash
bin/rails test test/services/shop/sms_ru_client_test.rb
bin/rails test test/integration/auth/phone_otp_test.rb
```

---

## Identity & merge

**«Одно чиним — другое ломается»** часто здесь: два `mobile_customers` на один phone/email.

| Роль | Путь |
|------|------|
| Merge | `app/services/shop/customer_profile_merger.rb` |
| Phone OTP → customer | `shop/phone_otp` controllers |
| Email | `app/services/shop/email_otp.rb` |

### Mapping

| Ключ | Правило |
|------|---------|
| phone | `link_phone!` → merge donor→survivor |
| email | `link_email!` → merge |
| customer_id | FK orders, cards, push, loyalty — `reassign_foreign_keys!` |

### Перенос при merge

orders · mobile_payment_methods · mobile_sessions · push_notifications · mobile_carts · loyalty_accounts (+ txns) · order_feedback · promo_code_usages

**Не ломать:** transaction + lock; donor soft-deactivate.

### Edge cases

- Два профиля / один телефон → `profile_merge_test.rb`
- Гость→регистрация, старые заказы → merge при verify/link
- **Запрещено:** тестовый OTP на профиле заказчика (Point A / DEMO_LOGINS)
