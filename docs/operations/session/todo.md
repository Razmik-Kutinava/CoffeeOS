# todo — Phone OTP split Flash Call / SMS (2026-08-12)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| SMS свой код + ТЗ split | GREEN local | Fly MCP Point A (после push/deploy) |

## Цель
Разделить смешанные ТЗ: Flash Call и SMS — независимые каналы. SMS больше не требует звонка.

## Файлы (ожидаемо)
- `app/services/shop/phone_otp.rb` — **[x]**
- `test/services/shop/phone_otp_test.rb` — **[x]**
- `test/services/shop/sms_ru_phone_otp_test.rb` — **[x]**
- `test/integration/shop/api/phone_otp_test.rb` — **[x]**
- `customer_tasks/Вход по телефону Flash Call OTP.md` · `… SMS OTP.md` — **[x]**

## Не ломать
- Flash Call verify / refresh_token
- Rack::Attack 20s flash / 60s sms
- Каскад UI (autoSend sms) — шлёт новый SMS-код

## Проверка
- `bin/rails test test/services/shop/phone_otp_test.rb test/services/shop/sms_ru_phone_otp_test.rb test/integration/shop/api/phone_otp_test.rb`
