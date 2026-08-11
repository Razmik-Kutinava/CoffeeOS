# SMS.ru API — Получить информацию о дневном лимите и его использовании

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_my_limit/  
**Статус:** интейк `[x]` · GREEN `[x]`

> api_id в примерах → `[REDACTED_API_ID]`. Боевой только `ENV['SMS_RU_API_ID']`.

---

`GET/POST https://sms.ru/my/limit?api_id=…&json=1` → `{ total_limit, used_today }`

## Заметки агента

- `SmsRuClient.limit!` → `LimitResult`  
- Не публичный shop API (ops/health позже)
