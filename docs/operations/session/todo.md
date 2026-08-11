# todo — Security medium: Tbank body limit + Rails.cache idempotency (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| GREEN body limit + Rails.cache claim | done local | `/regress` · push по апруву |

## Файлы (ожидаемо)
- `app/controllers/callbacks/tbank_controller.rb` — MAX_BODY_BYTES + Rails.cache claim
- `test/controllers/callbacks/tbank_controller_test.rb` — 413 + Rails.cache

## Не ломать
- CONFIRMED → accepted/succeeded
- duplicate → `duplicate: true`
- claim release на 500
- invalid token → 401
- CacheCounter circuit breaker

## Проверка
- `ruby bin/rails test test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_adapter_test.rb test/services/payments/cache_counter_test.rb` → **49/0 PASS**
