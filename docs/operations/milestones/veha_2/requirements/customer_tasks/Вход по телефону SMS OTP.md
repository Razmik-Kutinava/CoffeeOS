# Вход по телефону — SMS OTP (отдельный канал)

**Дата интейка:** 2026-08-12  
**Источник:** правка владельца — разделить смешанные ТЗ SMS+Flash Call  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/phone_otp_sms/  
**Статус:** SPEC+GREEN `[x]` 2026-08-12 · Fly MCP `[ ]`

> **SUPERSEDES (частично):**  
> - `Вход и регистрация по номеру телефона SMS Flash Call.md` (канал sms)  
> - ошибочное правило каскада «SMS шлёт код от flash_call» / «сначала запросите звонок»

---

## Текст требования (канон после правки)

Бизнес-цель: клиент входит / регистрируется в PWA **только через SMS** (SMS.ru `sms/send`), **без** предварительного Flash Call.

### Ограничения
- Без DDL `mobile_customers` / `mobile_otp_codes`.
- Секреты только ENV (`SMS_RU_API_ID`, `SMS_RU_FROM`).
- При `SHOP_OTP_LOG_FALLBACK=true` — без платной SMS, код в лог.

### Сценарий
1. Нормализация телефона → `+79XXXXXXXXX`.
2. `POST /shop/api/phone_otp/send` `{ phone, channel: "sms" }` → **генерируется новый 4‑значный код** → запись в `mobile_otp_codes` → отправка текста «Ваш код: XXXX» через `sms/send`.
3. **Запрещено** требовать активный код от звонка («Нет активного кода. Запросите звонок сначала» — баг смешанного ТЗ).
4. Повтор SMS: throttle **60 с** (Rack::Attack).
5. `POST /shop/api/phone_otp/verify` → сессия / `refresh_token` (как у flash_call).

### Exit
- SMS-вход без flash_call зелёный в тестах.
- Flash Call — другой док.
- UI-каскад Flash→SMS (если нужен) — оркестрация уже независимых каналов, не смешение кодов.

## Заметки агента

- Исправление: `Shop::PhoneOtp#send_sms!` генерирует код сам, не reuse flash.
- Profile link phone через SMS тоже опирается на этот канон.
