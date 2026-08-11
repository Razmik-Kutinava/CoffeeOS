# SMS.ru API — Выгрузить весь стоплист

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_stoplist_get/  
**Статус:** интейк `[x]` · GREEN `[x]`

> api_id в примерах → `[REDACTED_API_ID]`. Боевой только `ENV['SMS_RU_API_ID']`.

---

`POST https://sms.ru/stoplist/get` · `json=1` → `{ stoplist: { "phone" => "note" } }`

## Заметки агента

- `SmsRuClient.stoplist_get!` → `StoplistGetResult#stoplist` (Hash)  
- Не публичный shop API · webhooks — дальше
