# todo — SMS.ru #48 sms/send · PHASE 1 SPEC (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| intake + bridge `sms/send` | **SPEC готов** | намерение → RED (тесты) |

## Цель (#48)
Клиент `sms/send` по доке SMS.ru: разбор json-ответа (`sms_id`, per-phone OK/ERROR), запись `sms_id` в лог каскада. Без DDL, без публичного shop-прокси, без captcha.

## Acceptance
- [ ] `send_message!` / `send_sms!` на success возвращают результат с `sms_id` (не голый `true`)
- [ ] top-level OK, но `sms[phone].status == ERROR` → `SmsRuClient::Error` с кодом/текстом SMS.ru
- [ ] fallback (test / blank api_id / `SHOP_OTP_LOG_FALLBACK`) — без HTTP; результат с `sms_id` вида `fallback-*` (или `nil` — зафиксировать в RED)
- [ ] `OrderReadyPaidNotifier` пишет `sms_id` в `order_notification_logs.payload` (jsonb, **без миграции**)
- [ ] flash_call / OTP verify / already_sent SMS — без регрессии
- [ ] Не трогаем: multi-to, time/ttl/daytime/translit/test=1, login/password, captcha, legacy `SmsClient`

## Файлы (ожидаемо)
- `app/services/shop/sms_ru_client.rb` — Result + parse `sms{}` / raise per-phone ERROR
- `test/services/shop/sms_ru_client_test.rb` — RED: WebMock/stub `fallback?` false + json fixtures
- `app/services/shop/order_ready_paid_notifier.rb` — payload `sms_id` из Result
- `test/services/shop/order_ready_paid_notifier_test.rb` — новый: лог содержит `sms_id` (stub client)
- `docs/integrations/sms-auth.md` — после GREEN: закрыть gap «sms_id игнор» (docs в REVIEW ок)

**Blast-radius (+):**
- `app/services/shop/phone_otp.rb` — только если сломается контракт return (сейчас return игнор) — не править без нужды
- `test/jobs/shop/order_ready_cascade_job_test.rb` — stub `send_message!` уже `**_` — проверить зелёный

## Не ломать
- Phone OTP: flash_call ×2 → sms fallback (код из БД, cooldown)
- Cascade «заказ готов»: presence skip · already `sent` · msg ≤70 ValidationError
- Durable session / merge — вне scope
- Публичные `/shop/api/*` — не добавляем sms.ru proxy

## Проверка
```bash
bin/rails test test/services/shop/sms_ru_client_test.rb test/services/shop/order_ready_paid_notifier_test.rb
bin/rails test test/jobs/shop/order_ready_cascade_job_test.rb test/integration/shop/api/phone_otp_test.rb
```

## SBR
- [x] PHASE 1 SPEC
- [ ] PHASE 2 RED `[RED]`
- [ ] PHASE 2 GREEN `[GREEN]` + регрессия «Проверка»
- [ ] PHASE 3 REVIEW (bridge gap close · ops)

## Вне этого шага (следующие методы)
status · cost · callcheck · balance · limits · senders · auth check · stoplist · webhooks
