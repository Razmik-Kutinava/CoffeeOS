# todo — Residual review: SMS.ru body/cache + Tbank owned-claim (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| Tbank mediums CLOSED | SBR residual | RED→GREEN → `/regress` |

## Файлы (ожидаемо)
- `app/controllers/callbacks/sms_ru_controller.rb` — dual body size check (как Tbank)
- `app/services/callbacks/sms_ru_webhook.rb` — idempotency + callcheck в Rails.cache
- `test/controllers/callbacks/sms_ru_controller_test.rb`
- `app/controllers/callbacks/tbank_controller.rb` — release только если claim наш и !done
- `test/controllers/callbacks/tbank_controller_test.rb` — при необходимости

## Не ломать
- SMS.ru valid sms_status → 100 + delivery_status
- duplicate sms_status → history size 1
- callcheck caches status
- invalid hash → 401
- Tbank CONFIRMED / duplicate / release-on-500 / 413

## Проверка
- `ruby bin/rails test test/controllers/callbacks/sms_ru_controller_test.rb test/controllers/callbacks/tbank_controller_test.rb`
