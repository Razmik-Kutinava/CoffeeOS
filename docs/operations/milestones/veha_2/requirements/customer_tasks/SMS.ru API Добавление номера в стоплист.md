# SMS.ru API — Добавление номера в стоплист

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_stoplist_add/  
**Статус:** интейк `[x]` · GREEN `[x]`

> api_id в примерах → `[REDACTED_API_ID]`. Боевой только `ENV['SMS_RU_API_ID']`.

---

`POST https://sms.ru/stoplist/add` · `stoplist_phone` + `stoplist_text` · `json=1`

## Заметки агента

- `SmsRuClient.stoplist_add!(phone:, text:)` → `StoplistAddResult`  
- Не публичный shop API (ops позже)  
- del / get — следующие методы
