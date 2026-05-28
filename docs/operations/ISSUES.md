# ISSUES

> Канон (см. `.cursorrules`): любая ошибка/баг фиксируется здесь **сразу** при обнаружении; статус ведётся до **«решено»**; в записи обязательно **что сделано и чем закрыли** (код, тесты, миграции).

## 🔴 Блокеры

[2026-05-28] — Shop card/sbp: 500 при Init Т-Банка на Fly (pre-prod smoke)
Приоритет: 🔴 | Статус: открыта
Описание: `POST /shop/api/orders` с `payment_method=card` на `coffeeos.fly.dev` возвращает 500 «Внутренняя ошибка сервера». Cash — 200 `accepted`. Fly logs: stack в `Payments::TbankAdapter#post_json_with_circuit_breaker:96` → `init_payment` → `OrderCreator#init_gateway_payment!`.
Влияние: нет редиректа на `pay.tbank.ru`; блокер переключения на боевой терминал.
Smoke: `QA_ACCEPTANCE_RUN.md` прогон 0 (2026-05-28); cash order `c5ffaf41-02a7-4fff-bed4-d8e88a8136d0` OK.
Следующий шаг: диагностика circuit open vs T-Bank API error; ожидать 422 с текстом, не 500; повтор smoke card/sbp.

## 🟡 Важно

## 🟢 Потом

## Закрытые

[2026-05-01] — SolidCache: No unique index found for key_hash
Приоритет: 🔴 | Статус: закрыта
Описание: ArgumentError при записи в SolidCache. upsert_all вызывается с unique_by: :key_hash, но в таблице solid_cache_entries нет уникального индекса на эту колонку.
Влияние: Все запросы к /shop/api/categories падали с 500 ошибкой. Rack::Attack не мог инкрементировать счетчик.
Решение: 1) Добавлен уникальный индекс на key_hash в таблицу solid_cache_entries. 2) Настроен Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new для rate limiting, так как SolidCache не поддерживает increment.
Агент: Backend
