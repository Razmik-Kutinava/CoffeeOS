# SMS.ru API — Удаление номера из стоплиста

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_stoplist_del/  
**Статус:** интейк `[x]` · GREEN `[x]`

> api_id в примерах → `[REDACTED_API_ID]`. Боевой только `ENV['SMS_RU_API_ID']`.

---

`POST https://sms.ru/stoplist/del` · `stoplist_phone` · `json=1`

## Заметки агента

- `SmsRuClient.stoplist_del!(phone:)` → `StoplistDelResult`  
- Не публичный shop API · get — следующий метод
