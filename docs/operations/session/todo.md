# todo — Вход/регистрация по телефону (SMS / Flash Call)

> **ТЗ:** [`customer_tasks/Вход и регистрация по номеру телефона SMS Flash Call.md`](../milestones/veha_2/requirements/customer_tasks/Вход%20и%20регистрация%20по%20номеру%20телефона%20SMS%20Flash%20Call.md)  
> **Артефакты:** [`artifacts/phone_otp_sms_flash_call/`](../milestones/veha_2/artifacts/phone_otp_sms_flash_call/)

## Текущая фаза

**PHASE 1: SPEC** `[x]` · дальше RED при намерении («ебашь / сделай / go»)

---

## As-is (что уже есть)

| Зона | Факт |
|------|------|
| Email OTP | `Shop::EmailOtp` + `ShopEmailOtpCode` + Brevo (`Shop::BrevoClient`) · API `/shop/api/email_otp/{send,verify,status}` |
| Phone OTP таблицы | `mobile_otp_codes` (phone, code limit 6, attempts, expires_at, is_used) · `MobileOtpCode` модель · **сервиса отправки нет** |
| Клиенты | `mobile_customers` (phone unique, email unique partial) · `EmailVerifiedCustomerLinker` только по email |
| Сессии | `MobileSessionIssuer` + Silent Refresh (`SessionRefresh`) уже после email verify |
| Cooldown 60с | **нет** (ни phone, ни email) — только rack_attack 5/мин на email send |
| Нормализация телефона | **нет** единого хелпера под `+79XXXXXXXXX` |
| SMS / Flash Call клиенты | **нет** (Brevo = только email) |
| UI | Checkout: только email OTP · phone-формы нет |
| Тесты в репо | Minitest `test/` · JS `test/javascript/` (не RSpec/`spec/`) |

## Gap → шаги ТЗ

| Шаг ТЗ | Gap |
|--------|-----|
| 1 Нормализация | Новый `Shop::PhoneNormalizer` → `+79XXXXXXXXX` или Error |
| 2 Клиенты провайдера | `Shop::SmsClient` + `Shop::FlashCallClient` (образец Brevo) · ENV · `SHOP_OTP_LOG_FALLBACK` |
| 3 PhoneOtp Send | `Shop::PhoneOtp#send_code!` → invalidate old · write `mobile_otp_codes` · TTL 10m · attempts 0 |
| 4 Cooldown 60с | В `PhoneOtp` + **добавить в `EmailOtp#send_code!`** по `created_at` последнего кода |
| 5 Verify + link | `PhoneOtp#verify!` · secure_compare · max 5 · linker phone↔email · `MobileSessionIssuer` |
| 6 API + rack_attack | `PhoneOtpController` · routes · throttle `shop/phone_otp` |
| 7–8 Frontend | Маска + канал SMS/Flash Call · экран кода · timer 60с · LS `shop_refresh_token` |

---

## Решения SPEC (зафиксировано)

1. **DDL запрещён** для `mobile_customers` / `mobile_otp_codes`. Колонки `channel` нет — канал только в запросе; в БД храним ожидаемый `code`.
2. **Код 4–6 цифр:** колонка `string(6)` ок для 4 цифр Flash Call. Ослабить валидацию `MobileOtpCode` с жёстких 6 → `/\A[0-9]{4,6}\z/` (модель, не схема).
3. **Провайдер:** абстракция клиент + **первый адаптер SMS.ru HTTP** (ENV: `SHOP_SMS_PROVIDER` / ключи). Flash Call — Zvonok-style ENV (`SHOP_FLASHCALL_*`). Без ключей или `SHOP_OTP_LOG_FALLBACK=true` → только `Rails.logger`, без платной отправки.
4. **Cooldown:** 60с с `created_at` последней записи по phone (`mobile_otp_codes`) / email (`shop_email_otp_codes`), независимо от канала.
5. **Связка Email↔Phone (`PhoneVerifiedCustomerLinker`):**
   - есть customer в сессии с email без phone → дописать `phone` (если телефон свободен);
   - есть customer по phone без email, в сессии/verification есть email → дописать email;
   - конфликт двух разных карточек (оба заняты разными id) → Error понятным текстом, без silent merge/DDL.
6. **API ошибки провайдера:** клиент кидает typed Error → контроллер `422`/`502`, не необработанный 500 Rails.
7. **Тесты:** Minitest зеркало `test/services/shop/` + `test/integration/shop/api/phone_otp_*` · фронт — `test/javascript/` при наличии логики в lib. Пути `spec/` из ТЗ **не создаём**.
8. **Не трогать:** `Shop::BrevoClient` контракт; hot-path заказа/T-Bank; схему БД.

---

## Чеклист (SBR)

### Backend

- [ ] Шаг 1: `Shop::PhoneNormalizer` + тесты форматов
- [ ] Шаг 2: `Shop::SmsClient` / `Shop::FlashCallClient` + log fallback + сеть 400/500
- [ ] Шаг 3: `Shop::PhoneOtp#send_code!` (invalidate, TTL, attempts)
- [ ] Шаг 4: Cooldown 60с phone + email
- [ ] Шаг 5: `PhoneOtp#verify!` + linker + `MobileSessionIssuer`
- [ ] Шаг 6: routes + `PhoneOtpController` + rack_attack

### Frontend

- [ ] Шаг 7: форма телефона (маска) + выбор канала + экран кода + timer
- [ ] Шаг 8: API wire + `shop_refresh_token` в LS + ошибки 400/500

### Gates

- [ ] RED: падающие тесты закоммичены `[RED]`
- [ ] GREEN: реализация + зона shop/OTP зелёная `[GREEN]`
- [ ] REVIEW: CHANGELOG / HANDOFF / CBR статус

---

## Риски

| Риск | Митигация |
|------|-----------|
| Flash Call: код = последние 4 цифры caller | Клиент должен вернуть/зафиксировать digits до записи OTP; в log-fallback генерируем 4 цифры и пишем в лог |
| Unique phone/email конфликт при связке | Явная ошибка, без авто-merge двух id |
| Платные SMS на Fly по ошибке | Default: без ключей = log; secrets только после апрува |
| `MobileOtpCode#valid?` shadow ActiveRecord | Не использовать как AR valid?; при касании — rename/`otp_usable?` |
