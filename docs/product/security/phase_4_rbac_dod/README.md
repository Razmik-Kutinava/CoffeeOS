# Phase 4 — DoD «RBAC контур закрыт»

**Статус:** реализовано 2026-08-30 · ждём апрув владельца  
**Предусловие:** Phase 1–3 апрувнуты.

## Deliverables

| ID | Артефакт | Назначение |
|----|----------|------------|
| IB-4-1 | GAP REGISTER (ниже) | Readiness audit Phase 0–3 |
| IB-4-2 | [ROLES_AND_PERMISSIONS.md](../ROLES_AND_PERMISSIONS.md) | Главный doc для заказчика (RU) |
| IB-4-3 | [IB_ACCEPTANCE_CHECKLIST.md](../IB_ACCEPTANCE_CHECKLIST.md) | Чеклист приёмки |
| IB-4-6 | Docs sync (matrices, README, roadmap) | Статусы FIXED / COMPLETE |

## GAP REGISTER (остаток после Phase 4)

| ID | Source | Gap | Severity | Action |
|----|--------|-----|----------|--------|
| G-01 | Phase 3 | Kiosk auth RLS bypass | medium (prod N/A) | **FIXED** — `rls_devices_token_lookup` + `Rls::GucContext` |
| G-02 | Phase 3 | TV board device lookup bypass | medium (prod N/A) | **FIXED** — TokenResolver + GUC policy |
| G-03 | Phase 3 | ActionCable connection lookup | medium (prod N/A) | **FIXED** — `with_auth_login` (staff) + `TokenResolver` (TV cookie) |
| G-04 | Phase 0 REVIEW | Shop `phone_otp/status` auto-bind | low | **documented** — by design |
| G-05 | Phase 0 REVIEW | Shop `DELETE session` refresh deactivation | low | **documented** |
| G-06 | Phase 0 P3 | Favorites session-only | low | **FIXED** — `shop_customer_favorites` + `Shop::FavoritesStore` |
| G-07 | STAFF matrix | shift_manager + `/manager/inventory` URL | low | **FIXED** — `require_general_or_franchise_manager!` |
| G-08 | STAFF matrix | franchise + staff UI | info | **by design** — GM/UK only |
| G-09 | Phase 2 | Platform Pundit not wired | low | **FIXED Phase 5b** — PlatformPolicy + tenants/orgs authorize |
| G-10 | Phase 2 | blog_editor outside staff matrix | info | **backlog** blog CMS |
| G-11 | TECH DEBT | Global `user_roles` without `tenant_id` | low | **FIXED** — backfill migration + `has_role_in_context?` strict |
| G-12 | Phase 3 | Prep multi-point (1 kitchen → N sales) | info | **FIXED** (2026-08-31) — **data:** `prep_kitchen_sales_point_links` + `SalesPointRegistry` + same-org guard · **prep UI:** `/prep_kitchen/sales_points` · **wiring:** queue/stop-list/reports/incidents via `LinkedTenantScope` · **platform:** card on `/admin/tenants/:id` · см. IB-P-01, phase_5b README |

**NEED_MIGRATION:** none  
**Code fixes Phase 4:** none required (gaps = backlog or documented exceptions)  
**IB debt register:** [IB_SECURITY_DEBT.md](../IB_SECURITY_DEBT.md) (2026-08-31)

## Проверка

```bash
# WSL (рекомендуется на Windows-хосте)
ruby bin/audit/tenant_guc_inventory.rb
ruby bin/rails test test/integration/shop/api/ownership_idor_test.rb
ruby bin/rails test test/integration/staff/rbac_tenant_isolation_test.rb
ruby bin/rails test test/integration/staff/tenant_rls_isolation_test.rb
ruby bin/rails test test/integration/auth/
ruby bin/rails test test/integration/shop/api/
```

Prog10 (Fly HTTP, не MCP):

```bash
ruby bin/prog10/prog10_staff_rbac_isolation.rb
```

## Связанные фазы

| Фаза | Папка |
|------|-------|
| 0–3 | [phase_0_baseline/](../phase_0_baseline/) … [phase_3_tenant_rls/](../phase_3_tenant_rls/) |
| 5 | [00_ROADMAP_RBAC_ABAC.md](../00_ROADMAP_RBAC_ABAC.md) |
