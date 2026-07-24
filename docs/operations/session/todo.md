# todo — Вход/регистрация по телефону (SMS / Flash Call)

> **ТЗ:** [`customer_tasks/Вход и регистрация по номеру телефона SMS Flash Call.md`](../milestones/veha_2/requirements/customer_tasks/Вход%20и%20регистрация%20по%20номеру%20телефона%20SMS%20Flash%20Call.md)  
> **Артефакты:** [`artifacts/phone_otp_sms_flash_call/`](../milestones/veha_2/artifacts/phone_otp_sms_flash_call/)

## Текущая фаза

**PHASE 3: REVIEW** — GREEN локально · redeploy/MCP Fly — по апруву

---

## Чеклист (SBR)

### Backend

- [x] Шаг 1: `Shop::PhoneNormalizer` + тесты форматов
- [x] Шаг 2: `Shop::SmsClient` / `Shop::FlashCallClient` + log fallback
- [x] Шаг 3: `Shop::PhoneOtp#send_code!` (invalidate, TTL, attempts)
- [x] Шаг 4: Cooldown 60с phone + email
- [x] Шаг 5: `PhoneOtp#verify!` + linker + `MobileSessionIssuer`
- [x] Шаг 6: routes + `PhoneOtpController` + rack_attack

### Frontend

- [x] Шаг 7: форма телефона (маска) + выбор канала + экран кода + timer
- [x] Шаг 8: API wire + `shop_refresh_token` в LS + ошибки

### Gates

- [x] RED: `bcc0a2a` [RED]
- [x] GREEN: реализация + зона OTP зелёная
- [ ] Redeploy + MCP Fly — по апруву
- [ ] Апрув заказчика
