# TASK_93-K / K7 — RUBY-1J

**Решение SPEC:** **B** (не Sentry ignore).

- Collector: один batch + 1× `SET LOCAL row_security = off` (уже в коде до K).
- Тест: `channel_order_stats_collector_test` — assert no per-tenant `app.current_tenant_id` · exactly 1 `row_security = off`.
- REVIEW 2026-09-18: закрыть/resolve RUBY-1J в Sentry вручную после verify на стенде (не inbound filter как DoD).
