# ISSUES

> Канон (`coffeeos-commit-ops.mdc`, `RULES_INDEX.md`): баг фиксируется здесь **сразу**; статус до **«решено»** + **чем закрыли** (код, тесты, миграции).

## 🔴 Блокеры

[2026-06-19] — Fly + Supabase: compute quota exceeded (deploy + shop blocked)
Статус: **open**
Описание: `fly:release` → `db:prepare` → `PG::ConnectionBad: exceeded the compute time quota` (Supabase `52.29.229.153`). `/shop` HTTP 500; web machine stopped после failed deploy.
Проверка: логи deploy 2026-06-19; Supabase MCP `execute_sql` → connection timeout.
**Действие:** Supabase Dashboard → restore/upgrade проект → `fly deploy -a coffeeos` → MCP R2 (`bin/b112_r2_native_card_*`).
Временный фикс в коде: `bin/docker-entrypoint` — Puma стартует при fail `db:prepare` (см. `FLY_DEMO_STAND.md` §3).

[2026-06-18] — Fly: `/shop` HTTP 500 (B1.12-R2 MCP blocked)
Статус: **open**
Описание: `https://coffeeos.fly.dev/shop?tenant_id=…` → 500, нет `shop-api-key`; prep/MCP R2 не запускаются.
Проверка: `curl.exe -sS -w "%{http_code}" "https://coffeeos.fly.dev/shop?tenant_id=655aaccb-004a-4bb9-a50a-ce618854dda3"` → 500.
Следующий шаг: `fly logs` / deploy develop → повтор `bin/b112_r2_native_card_prep_fly.rb`.

## 🟡 Важно

[2026-05-30] — Kiosk: POST /kiosk/api/auth
Статус: resolved
Описание: Flutter/планшет нужен tenant по device_token; отдельного эндпоинта не было.
Решение: `Kiosk::Api::AuthController`, контракт [`FLUTTER_API.md`](milestones/veha_2/runbooks/FLUTTER_API.md); shop API без дублирования.
Проверка: 6 tests; curl smoke в FLUTTER_API.md.

[2026-05-28] — Fly: worker crash loop (DB pool < Solid Queue threads)
Статус: resolved
Описание: `bin/jobs` exit code 1 — «Solid Queue is configured to use 5 threads but the database connection pool is 3»; worker machine stopped, jobs не обрабатывались.
Решение: `DB_POOL=8` в `fly.toml`; `database.yml` — `ENV.fetch("DB_POOL")`; rake `fly:callback_smoke` для prod retest.
Проверка: worker `2871332` started; `TbankCallbackJob` Processed order `85bef120` через SolidQueue(critical), без perform_now fallback.

[2026-05-28] — Fly: Solid Queue worker + live табло без F5
Приоритет: 🟡 | Статус: **решено**
Описание: broadcast через async job не доходил до табло (worker/job lag).
Решение: sync `OrderBoardBroadcaster` из витрины и callback; worker для `TbankCallbackJob` retry; CI scale web=1 worker=1. Commits `a7f469e`, `97baa77`, `0bde33d`.
Проверка: MCP — barista открыт → cash LiveSmoke2 → ACCEPTED 5→6 без F5; `/cable` 101.

[2026-05-28] — Fly: Solid Queue/Cable schema не загружались → callback 500, barista broadcast 500
Приоритет: 🟡 | Статус: **решено**
Описание: `solid_queue_jobs` / `solid_cable_messages` отсутствовали; idempotency callback на SolidCache → RangeError.
Решение: idempotency → `Payments::CacheCounter`; callback `perform_now` fallback; `fly:release` → `DatabaseTasks.load_schema` для queue/cache/cable; barista broadcast rescue.
Проверка: E2E callback `f8427fc4-…` → `accepted`; barista `##202605-0008` на табло; 544/0 tests.

## 🟢 Потом

## Закрытые

[2026-05-28] — Shop card/sbp: 500 при Init Т-Банка на Fly (pre-prod smoke)
Приоритет: 🔴 | Статус: **решено**
Описание: Circuit breaker использовал `Rails.cache.increment` / SolidCache → `ActiveRecord::RangeError` (key_hash out of range) → 500 вместо 422.
Решение: `Payments::CacheCounter` на `MemoryStore` (как Rack::Attack); ApiError не трипит CB; `void_pending_online_order!` при ошибке Init; `rescue_from Shop::OrderCreator::Error` → 422. Коммиты `80e38be`, `884cdea`.
Проверка: smoke card → 200, `payment_url` `https://pay.tbank.ru/…`, 179₽ на форме Т-Банка; cash → 200 `accepted`. Prod terminal *(2026-05-28)*: Init `EJe3CaXH`, форма 179₽.

[2026-05-01] — SolidCache: No unique index found for key_hash
Приоритет: 🔴 | Статус: закрыта
Описание: ArgumentError при записи в SolidCache. upsert_all вызывается с unique_by: :key_hash, но в таблице solid_cache_entries нет уникального индекса на эту колонку.
Влияние: Все запросы к /shop/api/categories падали с 500 ошибкой. Rack::Attack не мог инкрементировать счетчик.
Решение: 1) Добавлен уникальный индекс на key_hash в таблицу solid_cache_entries. 2) Настроен Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new для rate limiting, так как SolidCache не поддерживает increment.
Агент: Backend
