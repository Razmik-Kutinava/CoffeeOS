# todo — Residual review: SMS.ru body/cache + Tbank owned-claim (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| GREEN SMS.ru Rails.cache + Tbank claimed/done | done local | `/regress` |

## Файлы (ожидаемо)
- `app/controllers/callbacks/sms_ru_controller.rb`
- `app/services/callbacks/sms_ru_webhook.rb`
- `app/controllers/callbacks/tbank_controller.rb`
- `test/controllers/callbacks/sms_ru_controller_test.rb`
- `test/controllers/callbacks/tbank_controller_test.rb`

## Не ломать
- SMS.ru sms_status / duplicate / callcheck / invalid hash
- Tbank CONFIRMED / duplicate / release-on-500 / 413 / foreign claim

## Проверка
- `ruby bin/rails test test/controllers/callbacks/sms_ru_controller_test.rb test/controllers/callbacks/tbank_controller_test.rb` → **23/0 PASS**
