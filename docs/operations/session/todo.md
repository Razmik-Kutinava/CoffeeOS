# todo — SMS.ru #49 email2sms SKIP + ENV (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| #49 intake SKIP · local `.env` SMS block | HTTP-шлюз готов (код #48) | владелец: боевой api_id/FROM в `.env` · Fly secrets по апруву · следующий метод SMS.ru |

## #49 email2sms
- [x] customer_tasks + artifacts (код **не** делаем)
- [x] runbook `SMS_RU_SECRETS.md`
- [x] local `.env`: `SMS_RU_API_ID` + `SMS_RU_FROM` + `SHOP_OTP_LOG_FALLBACK=false` (плейсхолдер — замени сам)
- [ ] Fly `fly secrets set` — только по явной просьбе

## Очередь
- [x] #48 sms/send HTTP
- [x] #49 email2sms → SKIP
- [ ] status · cost · callcheck · balance · …
