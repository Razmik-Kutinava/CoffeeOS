# SMS.ru API — Проверить стоимость сообщений перед отправкой

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_api_cost/  
**Статус:** интейк `[x]` · GREEN `[x]` 2026-08-11 · апрув `[ ]`

> **Секреты:** `api_id` в примерах → `[REDACTED_API_ID]`. Боевой ключ только `ENV['SMS_RU_API_ID']`.

---

Проверить стоимость сообщений перед отправкой  
`https://sms.ru/sms/cost` · params: `to`, `msg`, `json=1`, опц. `from` / `translit` · auth: `api_id` (ENV)  
Ответ: `sms[phone].cost` / `sms` (кол-во сегментов), `total_cost`, `total_sms`; per-phone ERROR возможен при top OK.

---

## Заметки агента

- CoffeeOS: `SmsRuClient.cost!(phone:, msg:)` — один номер (как send); multi — не в этом шаге
- Не shop-прокси; api_id не из доки
