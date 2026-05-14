# ISSUES

> Канон (см. `.cursorrules`): любая ошибка/баг фиксируется здесь **сразу** при обнаружении; статус ведётся до **«решено»**; в записи обязательно **что сделано и чем закрыли** (код, тесты, миграции).

## 🔴 Блокеры

## 🟡 Важно

## 🟢 Потом

## Закрытые

[2026-05-01] — SolidCache: No unique index found for key_hash
Приоритет: 🔴 | Статус: закрыта
Описание: ArgumentError при записи в SolidCache. upsert_all вызывается с unique_by: :key_hash, но в таблице solid_cache_entries нет уникального индекса на эту колонку.
Влияние: Все запросы к /shop/api/categories падали с 500 ошибкой. Rack::Attack не мог инкрементировать счетчик.
Решение: 1) Добавлен уникальный индекс на key_hash в таблицу solid_cache_entries. 2) Настроен Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new для rate limiting, так как SolidCache не поддерживает increment.
Агент: Backend
