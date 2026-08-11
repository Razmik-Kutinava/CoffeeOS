# SMS.ru API — Авторизовать пользователя по звонку с его номера (callcheck)

**Дата интейка:** 2026-08-11  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_callcheck/  
**Статус:** интейк `[x]` · клиент GREEN `[x]` · PWA воронка **не** менялась (канон flash_call×2→SMS) · webhook callcheck — отдельно

> **Секреты:** api_id в примерах → `[REDACTED_API_ID]`. Боевой — только ENV.

---

Авторизовать пользователя по звонку с его номера (callcheck):  
`callcheck/add` → `check_id` + `call_phone` (пользователь звонит, ≤5 мин) ·  
`callcheck/status` → 400 pending / **401 confirmed** / 402 expired ·  
рекомендуется webhook.

Скрин UI набора: `artifacts/sms_ru_callcheck/screenshots/callcheck_example_dial_ui.png`

---

## Заметки агента

- Клиент: `callcheck_add!` / `callcheck_status!` в `SmsRuClient`
- **Не** заменяет `flash_call` в PhoneOtp без отдельного ТЗ на воронку
- Webhook callcheck — следующая задача вместе с webhook SMS
