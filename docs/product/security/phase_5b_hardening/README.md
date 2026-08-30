# Phase 5b — IB hardening (2026-08-30)

**Статус:** local done · ABAC full enforce (Phase 5c) · deploy — после апрува

## Что сделано в 5b

| ID | Изменение | Зона |
|----|-----------|------|
| 5b-1 | Prog10: заказы через **barista POS** (не shop cash) | Fly smoke |
| 5b-2 | `Devices::TokenResolver` — единый device lookup (kiosk/TV/cable) | RLS backlog |
| 5b-3 | Platform Pundit: `PlatformPolicy` + authorize tenants/orgs/**menu catalog** | `/admin` |
| 5b-4 | `TenantPolicy#open_as_manager?` → только UK | platform |
| 5b-5 | `UserRole` validation: tenant_id обязателен для point staff | TECH DEBT G-11 |
| 5c | **Full ABAC enforce** — все 58 правил `Y` в каталоге | policies + scopes |

## Phase 5c — ABAC full enforce (2026-08-30)

- `TenantModulePolicy`, `Blog::PostPolicy`, `Devices::DeviceAuthPolicy`, `TvBoardPolicy`
- `Manager::IncidentPolicy`, `Manager::ReportPolicy`
- `OrderPolicy#read_board?`, module flags на barista actions
- `CashShiftPolicy#close?` — shift_manager только своя смена
- `Finance::PaymentPolicy::Scope` — shift filter в policy
- `Devices::KioskOrderGuard` — kiosk source + module FF
- `TenantOperatingHoursEnforcement` — shop/kiosk hours guard
- TV board → `BoardOrdersQuery` scope

## Остаётся (low / product)

- Favorites session-only (G-06)
- Prep multi-point (G-12)
- Fly MCP Point A post-deploy

## Проверка

```bash
ruby bin/rails test test/policies/abac_full_enforcement_test.rb test/policies/
ruby bin/rails test test/integration/tv_board_test.rb test/integration/prep_kitchen/feature_flags_test.rb
ruby bin/prog10/prog10_staff_rbac_isolation.rb
```

## Связанные docs

- [ABAC_POLICIES.md](../phase_5_abac/ABAC_POLICIES.md) — ABAC-056/057 → Partial via TokenResolver
- [IB_MASTER_VERIFICATION_CHECKLIST.md](../IB_MASTER_VERIFICATION_CHECKLIST.md)
