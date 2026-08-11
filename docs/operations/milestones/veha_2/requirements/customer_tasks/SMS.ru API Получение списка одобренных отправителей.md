# SMS.ru API — Получение списка одобренных отправителей

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_my_senders/  
**Статус:** интейк `[x]` · GREEN `[x]`

> api_id в примерах → `[REDACTED_API_ID]`. Боевой только `ENV['SMS_RU_API_ID']`.

---

`GET/POST https://sms.ru/my/senders?api_id=…&json=1` → `{ senders: ["…"] }`

## Заметки агента

- `SmsRuClient.senders!` → `SendersResult#senders`  
- Сверка с `ENV['SMS_RU_FROM']` — ops/health позже  
- Не публичный shop API
