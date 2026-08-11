# Bridge: SMS.ru + Identity (OTP, merge, session)

## SMS.ru

| Роль | Путь |
|------|------|
| Клиент | `app/services/shop/sms_ru_client.rb` |
| Phone OTP | `app/services/shop/phone_otp.rb` |
| Email OTP | `app/services/shop/email_otp.rb` |
| Cascade ready | `OrderReadyCascadeJob` → SMS leg |
| Логи | `order_notification_logs` |
| ТЗ send | [`SMS.ru API Отправить СМС HTTP…`](../operations/milestones/veha_2/requirements/customer_tasks/SMS.ru%20API%20Отправить%20СМС%20HTTP%20запросом.md) · artifacts `sms_ru_api_send_http/` |

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

`SMS_RU_API_ID` · `SMS_RU_FROM` (или `SMS_RU_SENDER`) · для боевой отправки `SHOP_OTP_LOG_FALLBACK` не `true`  
Runbook: [`SMS_RU_SECRETS.md`](../operations/runbooks/SMS_RU_SECRETS.md)

**Запрещено:** коммитить `api_id` / login+password из доки ЛК; auth только через ENV `api_id`.  
**email2sms / SMTP (`…@sms.ru`):** не внедряем — ТЗ #49 SKIP (канон HTTP #48).

### Edge cases

- SMS.ru down → `SmsRuClient::Error`
- Cooldown → `PhoneOtp::Error`
- User online WS → SMS skip (`OrderReadyPresence`)
- SMS >70 chars → `ValidationError`

---

## SMS.ru `sms/send` (HTTP)

**URL:** `POST https://sms.ru/sms/send` · всегда `json=1`  
**Наш вызов:** `SmsRuClient#send_sms!` (OTP) · `#send_message!` (cascade ready ≤70)

### Mapping параметров

| SMS.ru | Обязат. | CoffeeOS |
|--------|---------|----------|
| `api_id` | да | `ENV['SMS_RU_API_ID']` |
| `to` | да | один номер, без `+` (`strip_plus`) |
| `msg` | да | OTP: `Ваш код: NNNN` · cascade: произвольный ≤70 |
| `json` | рек. | всегда `"1"` |
| `from` | нет | `ENV['SMS_RU_FROM']` / `SMS_RU_SENDER` |
| `ip` | нет | `request.remote_ip` гостя (OTP); cascade — опционально |
| `time` / `ttl` / `daytime` / `translit` / `partner_id` | нет | **не используем** |
| `test=1` | нет | не шлём; локально — `SHOP_OTP_LOG_FALLBACK` / blank api_id |
| multi `to[phone]=msg` | нет | **не используем** (один получатель за вызов) |
| login/password | альт. | **запрещено** — только `api_id` |

### Ответ (json) — #48

| Поле | Поведение |
|------|-----------|
| top `status` / `status_code` | OK / 100 → дальше; иначе `Error` |
| `sms[phone].sms_id` | `SendResult#sms_id`; cascade → `order_notification_logs.payload["sms_id"]` |
| `sms[phone].status` ERROR | `Error` + `status_code` / текст (даже если top OK) |
| fallback | `SendResult(sms_id: "fallback-…")` без HTTP |
| `balance` | игнор (health / my/balance — позже) |

**Не экспонируем** `sms/send` как публичный shop API-прокси — только внутренний клиент (OTP + cascade).

### SMS.ru `sms/status` (#50)

**URL:** `POST https://sms.ru/sms/status` · `json=1`  
**Вызов:** `SmsRuClient.status!(sms_ids:)` → `Array<StatusResult>`

| SMS.ru | CoffeeOS |
|--------|----------|
| `api_id` | `ENV['SMS_RU_API_ID']` только (не хардкод из доки) |
| `sms_id` | аргумент (из #48 `SendResult` / log payload) |
| `sms[id].status_code` | `StatusResult#status_code` (103 = доставлено) |
| per-id ERROR | `ok: false` (не raise) |
| top ERROR | `Error` |
| fallback | `ok: true`, code 103 |

Webhook статусов — отдельная задача. Не shop-прокси.

### SMS.ru `sms/cost` (#51)

**URL:** `POST https://sms.ru/sms/cost` · `json=1`  
**Вызов:** `SmsRuClient.cost!(phone:, msg:)` → `CostResult` (один номер)

| SMS.ru | CoffeeOS |
|--------|----------|
| `api_id` | ENV only |
| `to` / `msg` | аргументы; `from` из ENV если есть |
| `sms[phone].cost` / `sms` | `CostResult#cost` / `#sms_count` |
| `total_cost` / `total_sms` | поля Result |
| per-phone ERROR | `ok: false` |
| multi | **не** в этом шаге |

### SMS.ru callcheck (#52)

**Иное, чем flash_call:** пользователь **сам** звонит на `call_phone`; мы сбрасываем (бесплатно).

| Метод | Вызов | Результат |
|-------|--------|-----------|
| `POST …/callcheck/add` | `callcheck_add!(phone:)` | `CallcheckAddResult` (check_id, call_phone, pretty) |
| `POST …/callcheck/status` | `callcheck_status!(check_id:)` | `CallcheckStatusResult` (400/401/402, `confirmed`) |

- Канон PWA auth **без изменений**: flash_call×2→SMS  
- Callcheck webhook — отдельно  
- api_id только ENV

### SMS.ru `my/balance` (#53)

**URL:** `POST https://sms.ru/my/balance` · `json=1`  
**Вызов:** `SmsRuClient.balance!` → `BalanceResult#balance`  
api_id только ENV · не shop-прокси (для health/ops).

### SMS.ru `my/limit` (#54)

**URL:** `POST https://sms.ru/my/limit` · `json=1`  
**Вызов:** `SmsRuClient.limit!` → `LimitResult` (`total_limit`, `used_today`)  
api_id только ENV · не shop-прокси. Код 206 при send = дневной лимит исчерпан.

### SMS.ru `my/free` (#55)

**URL:** `POST https://sms.ru/my/free` · `json=1`  
**Вызов:** `SmsRuClient.free!` → `FreeResult` (`total_free`, `used_today`)  
Бесплатные SMS на свой номер за день · api_id только ENV · не shop-прокси.

### SMS.ru `my/senders` (#56)

**URL:** `POST https://sms.ru/my/senders` · `json=1`  
**Вызов:** `SmsRuClient.senders!` → `SendersResult#senders` (массив строк)  
Сверка с `SMS_RU_FROM` — ops позже · api_id только ENV · не shop-прокси.

### SMS.ru `auth/check` (#57)

**URL:** `POST https://sms.ru/auth/check` · `json=1`  
**Вызов:** `SmsRuClient.auth_check!` → `AuthCheckResult` (`ok`, `status_code`)  
Только `api_id` из ENV · **login/password SKIP** · не shop-прокси (health/ops).

### SMS.ru `stoplist/add` (#58)

**URL:** `POST https://sms.ru/stoplist/add` · `json=1`  
**Вызов:** `SmsRuClient.stoplist_add!(phone:, text:)` → `StoplistAddResult`  
Параметры `stoplist_phone` / `stoplist_text` · api_id только ENV · не shop-прокси.

### SMS.ru `stoplist/del` (#59)

**URL:** `POST https://sms.ru/stoplist/del` · `json=1`  
**Вызов:** `SmsRuClient.stoplist_del!(phone:)` → `StoplistDelResult`  
Параметр `stoplist_phone` · api_id только ENV · не shop-прокси.

### Антифлуд

- SMS.ru: captcha на UI + параметр `ip`
- CoffeeOS: Rack::Attack + cooldown OTP + `ip` в запросе; captcha на PWA **не** добавляем без отдельного ТЗ

### Коды (частое)

| Код | Смысл | Наше поведение |
|-----|--------|----------------|
| 100 | принято в очередь | success |
| 103 | доставлено | `status!` → StatusResult 103 |
| 200/301 | плохой api_id | Error 502 |
| 201 | нет денег | Error |
| 202/207 | нет маршрута / номер | Error |
| 206 | дневной лимит | Error |
| 209/215 | стоп-лист | Error |
| 220/500 | сервис | Error + retry policy джобы |
| 230–233 | лимиты на номер / код | Error (не крутить OTP) |

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
