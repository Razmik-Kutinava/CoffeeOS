# Вход по телефону — Flash Call OTP (отдельный канал)

**Дата интейка:** 2026-08-12  
**Источник:** правка владельца — разделить смешанные ТЗ SMS+Flash Call  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/phone_otp_flash_call/  
**Статус:** SPEC+GREEN `[x]` 2026-08-12 · Fly MCP `[ ]`

> **SUPERSEDES (частично):** смешанные ТЗ  
> - `Вход и регистрация по номеру телефона SMS Flash Call.md` (канал flash_call)  
> - каскад Flash×2→SMS — **не** этот док (оркестрация UI отдельно)

---

## Текст требования (канон после правки)

Бизнес-цель: клиент входит / регистрируется в PWA **только через Flash Call** (звонок-сброс SMS.ru `code/call`), без зависимости от SMS.

### Ограничения
- Таблицы `mobile_customers`, `mobile_otp_codes` — без DDL.
- Секреты только ENV (`SMS_RU_API_ID`, …). Хардкод запрещён.
- При `SHOP_OTP_LOG_FALLBACK=true` — без реального звонка, код в лог.

### Сценарий
1. Нормализация телефона → `+79XXXXXXXXX`.
2. `POST /shop/api/phone_otp/send` `{ phone, channel: "flash_call" }` → SMS.ru `/code/call` → код = последние 4 цифры из ответа → запись в `mobile_otp_codes` (TTL 10 мин).
3. Кулдаун повторного flash_call: **20 с** (сервис + Rack::Attack).
4. `POST /shop/api/phone_otp/verify` `{ phone, code }` → ≤5 попыток, `secure_compare` → сессия / `refresh_token`.
5. SMS **не** требуется для успешного входа.

### Exit
- Вход только flash_call зелёный в тестах.
- SMS отдельно — другой док.

## Заметки агента

- **SUPERSEDED 2026-08-12:** не канон. Auth = Callcheck + SMS fallback — BUG-REPORT Callcheck.
- Не путать с **callcheck** (клиент звонит нам) — теперь это основной flow.
