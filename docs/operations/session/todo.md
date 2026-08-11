# todo — Bugbot fixes: Tbank idempotency + CacheCounter + CI (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| Bugbot 4 findings fixed | done local | security-review · push по апруву |

## Файлы
- `app/controllers/callbacks/tbank_controller.rb`
- `app/services/payments/cache_counter.rb`
- `.github/workflows/ci.yml`
- `test/controllers/callbacks/tbank_controller_test.rb`
- `test/services/payments/cache_counter_test.rb`

## Не ломать
- CONFIRMED → accepted/succeeded
- duplicate → `duplicate: true`
- race AUTHORIZED после polling
- SMS.ru webhook (тот же CacheCounter)

## Проверка
- `ruby bin/rails test test/controllers/callbacks/tbank_controller_test.rb test/services/payments/cache_counter_test.rb test/services/payments/tbank_adapter_test.rb` → **47/0 PASS**
