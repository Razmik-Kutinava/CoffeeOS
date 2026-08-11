# todo — SMS.ru #61 webhooks · GREEN (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| #61 `POST /callbacks/sms_ru` | done local | deploy + URL в ЛК SMS.ru · callcheck funnel |

## Очередь
- [x] #48–#61 (клиент + stoplist + webhooks)
- [ ] PWA funnel на callcheck — только по ТЗ
- [ ] Fly secrets + webhook URL в ЛК — апрув владельца

## Файлы (ожидаемо) — #61
- `app/controllers/callbacks/sms_ru_controller.rb`
- `app/services/callbacks/sms_ru_webhook.rb`
- `config/routes.rb`
- `test/controllers/callbacks/sms_ru_controller_test.rb`
- `docs/integrations/sms-auth.md`

## Не ломать
- Т-Банк `POST /callbacks/tbank`
- cascade SMS `order_notification_logs` (status sent)
- OTP flash_call funnel

## Проверка
- `bin/rails test test/controllers/callbacks/sms_ru_controller_test.rb`
- `bin/rails test test/services/shop/sms_ru_client_test.rb`
