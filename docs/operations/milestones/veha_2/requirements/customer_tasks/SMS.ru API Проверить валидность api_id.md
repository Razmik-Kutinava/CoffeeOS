# SMS.ru API — Проверить на валидность пару логин/пароль (или api_id)

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_auth_check/  
**Статус:** интейк `[x]` · GREEN `[x]` (только api_id)

> api_id в примерах → `[REDACTED_API_ID]`. Боевой только `ENV['SMS_RU_API_ID']`.

---

`POST https://sms.ru/auth/check` · `json=1` · успех: `{ status: OK, status_code: 100 }`

## Заметки агента

- `SmsRuClient.auth_check!` → `AuthCheckResult` (api_id из ENV)  
- **login/password — SKIP** (канон CoffeeOS = только api_id)  
- Не публичный shop API (ops/health позже)
