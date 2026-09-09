# todo — V3-SEC-JOB-TENANT-GUC (Solid Queue jobs → tenant GUC)

| Поле | Значение |
|------|----------|
| **ID** | `V3-SEC-JOB-TENANT-GUC` |
| **Тип** | security / background jobs / RLS |
| **Приоритет** | medium (код) · high если queue DB торчит (ops) |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-core` (tenant/RLS) · `@coffeeos-commit-ops` |
| **MVP** | **срез A** — `Rls::JobTenantContext` + wrap order-scoped jobs + тесты + audit/ops абзац |
| **Очередь** | **Solid Queue (Postgres)** — не Sidekiq/Redis (`queue_adapter = :solid_queue`; worker `./bin/jobs`) |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | signed job args · полный `tenant_guc_inventory` · Sidekiq/Redis · `fly deploy` / network audit без апрува |
| **Parked** | `V3-SEC-SHOP-API-KEYS` (GREEN+regress, ждёт `/review`) · `V3-SEC-OTP-MERGE` (SPEC) |

## SBR

- [x] **SPEC** — todo + шапки SESSION/HANDOFF
- [x] **RED** — `6dfe5038` · `test: job tenant GUC context [RED]`
- [x] **GREEN** — helper + wrap order jobs + `RLS_TENANT_AUDIT` · `feat: set tenant GUC in order-scoped jobs [GREEN]`
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI
- [ ] **Ops live** — Fly queue network / creds — **только апрув** владельца

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/services/rls/job_tenant_context.rb` | `with(order)` / `with_tenant_id` — Current + SET/SET LOCAL + ensure |
| `app/jobs/application_job.rb` | `with_order_tenant!` / `with_job_tenant_id!` |
| `app/jobs/barista/broadcast_order_board_job.rb` | GUC после find |
| `app/jobs/shop/ready_push_job.rb` | GUC |
| `app/jobs/shop/order_ready_cascade_job.rb` | GUC |
| `app/jobs/payments/tbank_callback_job.rb` | GUC после resolve order |
| `docs/product/security/phase_3_tenant_rls/RLS_TENANT_AUDIT.md` | FIXED + ops runbook |

**Соседи:** receipt email · send push · `BroadcastTvColumnsJob` · (не трогать `guc_context` flags)

## Не ломать

1. Tbank callback → RebillId / статус (`perform_now` fallback).
2. Ready cascade / push / WS board.
3. `StuckPaymentsCheckJob` + `TelegramAlertJob` global.
4. Ownership IDOR suite.

## Проверка

```bash
bin/rails test test/services/rls/job_tenant_context_test.rb
bin/rails test test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb
```
