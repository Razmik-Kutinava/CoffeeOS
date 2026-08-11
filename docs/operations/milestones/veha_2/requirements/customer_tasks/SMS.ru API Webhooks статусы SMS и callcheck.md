# SMS.ru API — Webhooks (статусы SMS + callcheck)

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_webhooks/  
**Статус:** интейк `[x]` · GREEN `[x]`

> api_id в примерах → `[REDACTED_API_ID]`. Боевой только `ENV['SMS_RU_API_ID']`.

---

SMS.ru шлёт POST на наш обработчик: `data[1]…data[100]` + `hash` (SHA256 от `api_id` + склейки data).  
Ответ **обязан** быть телом `100`.

Типы:
- `sms_status` — sms_id · status_code · unix_ts  
- `callcheck_status` — check_id · status (401/402) · unix_ts  

## Заметки агента

- Endpoint: `POST /callbacks/sms_ru`  
- `sms_status` → обогащает `order_notification_logs.payload` (`delivery_status*`)  
- `callcheck_status` → лог (persist check_id — когда появится воронка callcheck)  
- Не shop-прокси
