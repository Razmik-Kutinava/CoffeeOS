# SMS.ru API — Получить информацию о бесплатных сообщениях и его использовании

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_my_free/  
**Статус:** интейк `[x]` · GREEN `[x]`

> api_id в примерах → `[REDACTED_API_ID]`. Боевой только `ENV['SMS_RU_API_ID']`.

---

`GET/POST https://sms.ru/my/free?api_id=…&json=1` → `{ total_free, used_today }`  
(бесплатные SMS на свой номер за день)

## Заметки агента

- `SmsRuClient.free!` → `FreeResult`  
- Не публичный shop API (ops/health позже)
