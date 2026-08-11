# todo — Security medium: Tbank body limit + Rails.cache idempotency (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| Security Review 2 medium | SBR RED→GREEN | /regress после GREEN |

## Файлы (ожидаемо)
- `app/controllers/callbacks/tbank_controller.rb` — MAX_BODY_BYTES + claim через Rails.cache
- `test/controllers/callbacks/tbank_controller_test.rb` — 413 + Rails.cache claim/release

## Не ломать
- CONFIRMED → accepted/succeeded
- duplicate → `duplicate: true`
- claim release на 500 → retry обрабатывается
- подпись invalid → 401
- CacheCounter circuit breaker (не трогаем STORE)

## Проверка
- `ruby bin/rails test test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_adapter_test.rb test/services/payments/cache_counter_test.rb`
