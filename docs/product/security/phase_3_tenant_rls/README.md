# Phase 3 — Tenant + RLS (жёсткость изоляции)

**Статус:** реализовано 2026-08-30 · апрув → Phase 4  
**Предусловие:** Phase 1 (shop ownership) + Phase 2 (staff Pundit) апрувнуты.

## Deliverables

| ID | Артефакт | Назначение |
|----|----------|------------|
| IB-3-1 | [RLS_TENANT_AUDIT.md](RLS_TENANT_AUDIT.md) | Инвентаризация GUC / `row_security off` / jobs |
| IB-3-4 | [DEVICE_TOKENS.md](DEVICE_TOKENS.md) | Runbook создания/отзыва устройств |
| IB-3-aux | `bin/audit/tenant_guc_inventory.rb` | Статический grep-отчёт (exit 0, не блокирует CI) |
| IB-3-3 | `test/integration/staff/tenant_rls_isolation_test.rb` | Franchise / UK / barista regression |

## Scope OUT (backlog, не Phase 3)

- Kiosk auth refactor (`kiosk/api/auth_controller.rb`)
- TV board deep audit (`tv_boards_controller.rb`)
- ActionCable connection refactor (`application_cable/connection.rb`)
- Prep multi-point (1 цех → N точек)
- `last_seen_at`, token auto-rotation
- Новые PostgreSQL RLS policies / миграции без апрува

## Связанные фазы

| Фаза | Папка |
|------|-------|
| 0 | [phase_0_baseline/](../phase_0_baseline/) |
| 1 | [phase_1_rbac_closure/](../phase_1_rbac_closure/) |
| 2 | [phase_2_abac_layer/](../phase_2_abac_layer/) |
| 4+ | [00_ROADMAP_RBAC_ABAC.md](../00_ROADMAP_RBAC_ABAC.md) |

## Проверка

```bash
ruby bin/audit/tenant_guc_inventory.rb
ruby bin/rails test test/integration/staff/tenant_rls_isolation_test.rb
ruby bin/rails test test/integration/auth/franchise_manager_rbac_test.rb
ruby bin/rails test test/integration/auth/platform_uk_rbac_test.rb
```
