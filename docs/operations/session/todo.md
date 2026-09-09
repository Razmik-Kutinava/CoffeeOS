# todo — V3-SEC-JOB-TENANT-GUC (Solid Queue jobs → tenant GUC)

| Поле | Значение |
|------|----------|
| **ID** | `V3-SEC-JOB-TENANT-GUC` |
| **Тип** | security / background jobs / RLS |
| **Приоритет** | medium (код) · high если queue DB торчит (ops) |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-core` · `@coffeeos-commit-ops` |
| **MVP** | срез A — `Rls::JobTenantContext` + wrap order-scoped jobs + audit/ops |
| **Очередь** | **Solid Queue** — не Sidekiq |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Parked** | `V3-SEC-SHOP-API-KEYS` REVIEW pushed (CI/deploy апрув) · `V3-SEC-OTP-MERGE` SPEC |

## SBR

- [x] **SPEC** — `022552d5`
- [x] **RED** — `6dfe5038`
- [x] **GREEN** — `8f9f5aa2`
- [x] **regress** — helper+jobs **28/86 PASS** (2026-09-09)
- [x] **REVIEW** — local PASS · Entire `01M22D5GHQKN7FEQE7Y87CCN3T` · bugbot/security **usage blocked** · push CI
- [ ] **Ops live** — Fly queue network — только апрув

## Файлы

| Path | Зачем |
|------|--------|
| `app/services/rls/job_tenant_context.rb` | Current + SET/SET LOCAL |
| `app/jobs/application_job.rb` | wrappers |
| order-scoped jobs + `RLS_TENANT_AUDIT.md` | GUC + FIXED |

## Не ломать

1. Tbank callback / RebillId
2. Ready cascade / push / WS board
3. StuckPayments + TelegramAlert global
4. Ownership IDOR

## Проверка

```bash
bin/rails test test/services/rls/job_tenant_context_test.rb test/jobs/barista/broadcast_order_board_job_test.rb
bin/rails test test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb test/jobs/send_order_receipt_email_job_test.rb
```
