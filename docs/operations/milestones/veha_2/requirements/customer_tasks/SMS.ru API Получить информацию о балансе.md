# SMS.ru API — Получить информацию о балансе

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_my_balance/  
**Статус:** интейк `[x]` · GREEN `[x]`

> api_id в примерах → `[REDACTED_API_ID]`. Боевой только `ENV['SMS_RU_API_ID']`.

---

`GET/POST https://sms.ru/my/balance?api_id=…&json=1` → `{ balance: … }`

## Заметки агента

- `SmsRuClient.balance!` → `BalanceResult`  
- Не публичный shop API (ops/health позже)
