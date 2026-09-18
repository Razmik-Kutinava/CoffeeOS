# todo — #93 TASK_93-I: OTP / rate limit / auth abuse

**Канон блока при race session todo** — этот файл. Session `todo.md` может быть чужим блоком.

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-I** |
| **Тип** | SBR · hot-path shop auth / Rack::Attack |
| **Статус** | **GREEN** · Next: `/regress` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата I1–I4 · зонтик [`TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта I |
| **GATES** | [`GATES-block-I.md`](GATES-block-I.md) |
| **Цель** | Attack limits **общие** на Fly (Redis); `verify_sms` (+ legacy/email) throttled → 429; SMS OTP **6** + UI; short-link без дубля |
| **OUT** | Callcheck · SMS.ru · app Solid→Redis · **Fly Redis deploy (L)** |
| **Зависимость** | C4 rule `shop/order_short_link/ip` уже в HEAD; Redis secret = **L** |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1 (I1)** | prod или `FLY_APP_NAME` → `RedisCacheStore`; URL = `RACK_ATTACK_REDIS_URL` \|\| `REDIS_URL`. Dev без URL → MemoryStore + warn. Test → MemoryStore |
| **R2** | SolidCache **запрещён** для Attack |
| **R3 (I2)** | `verify_sms` + legacy `verify`: **5 / 1.minute** по **IP** и **phone**. Имена `shop/phone_otp_verify_sms/ip`, `…/phone`. Retry-After **60** |
| **R4** | `email_otp/verify`: **5 / 1.minute** IP + email. `shop/email_otp_verify/ip`, `…/email` |
| **R5 (I3)** | **IN SCOPE**: `%06d` в `PhoneOtp#send_sms_code!`; UI `PIN_LENGTH`/`SMS_PIN_LENGTH`=6. Callcheck/flash/`test_code` не трогать |
| **R6 (I4)** | одно `shop/order_short_link/ip` — не дублировать |
| **R7** | `MAX_ATTEMPTS` defense-in-depth |
| **R8** | prod/FLY без Redis URL → **fail boot** |
| **R9** | CI redis service + `REDIS_URL`; T-I1b skip без URL locally |

## SBR

- [x] PHASE 0 `/start`
- [x] `/unlazy` — `07538476`
- [x] PHASE 1 `/spec` — этот файл (+ session todo если не race)
- [x] PHASE 2 RED — tests in `0504f088` (msg race) · T-I*
- [x] PHASE 2 GREEN — `c14f5202` · R1–R9 · Local PASS (T-I1b skip без Redis)
- [ ] `/regress` — § Проверка
- [ ] PHASE 3 `/review` — I1–I4 PASS · push · **без deploy Redis**

## Файлы (ожидаемо)

- `config/initializers/rack_attack.rb` — store + verify/email throttles
- `Gemfile` (+ lock) — `gem "redis"`
- `app/services/shop/phone_otp.rb` — `%06d`
- `app/frontend/lib/phoneAuthWizard.js` — `PIN_LENGTH = 6`
- `app/frontend/lib/shopSmsPinPad.js` — `SMS_PIN_LENGTH = 6`
- `test/integration/rack_attack_otp_verify_test.rb` — создать T-I2*
- `test/integration/rack_attack_store_test.rb` — создать T-I1*

### Blast-radius

- `test/services/shop/phone_otp_test.rb` — T-I3
- `test/integration/rack_attack_order_short_link_test.rb` — T-I4
- `.github/workflows/ci.yml` — redis (R9)
- `REDIS_RACK_ATTACK.md` — новый runbook (secret → L)

## Матрица приёмки

| ID | Assert |
|----|--------|
| T-I1a | prod/FLY+URL → Redis* store |
| T-I1b | shared increment (CI redis) |
| T-I1c | без URL → boot raise |
| T-I2a | N+1 verify_sms → 429 |
| T-I2b | under limit ≠ 429 |
| T-I2c | phone key across IPs |
| T-I2d | legacy verify → 429 |
| T-I2e | email verify → 429 |
| T-I3a–c | 6 digits + UI |
| T-I4a–c | one `/o/` rule + 429 |

Без T-I1a + T-I2a блок не закрыт.

## Не ломать

1. Callcheck 20s / SMS send 60s
2. Retry-After JSON phone OTP send/callcheck
3. Attack `enabled=false` в test по умолчанию
4. Short-link HMAC/bind (C)
5. Happy path phone/email OTP

## Проверка

```bash
bin/rails test \
  test/integration/rack_attack_store_test.rb \
  test/integration/rack_attack_otp_verify_test.rb \
  test/integration/rack_attack_order_short_link_test.rb \
  test/services/shop/phone_otp_test.rb

bin/rails test \
  test/integration/shop/api/phone_otp_test.rb \
  test/integration/shop/order_short_links_test.rb \
  test/services/shop/phone_otp_test.rb
```
