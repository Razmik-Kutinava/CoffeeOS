# todo — SMS.ru API bridge (#48+) 2026-08-11

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| intake + bridge `sms/send` | #48 docs ready | go → SPEC/код клиента **или** кидай следующий метод SMS.ru |

## #48 SMS.ru sms/send
- [x] customer_tasks + artifacts `sms_ru_api_send_http`
- [x] CBR #48 · `sms-auth.md` контракт send
- [ ] SPEC → `SmsRuClient`: вернуть `sms_id`, per-phone ERROR (после **go**)
- [ ] Не публичный shop-прокси всего API

## Очередь методов (кидай текстом по одному)
- [x] sms/send (intake)
- [ ] status / cost / callcheck / balance / limits / free / senders / auth check / stoplist / webhooks
