# Phase 5b — IB hardening (2026-08-30)

**Статус:** local done · ABAC full enforce (Phase 5c) · deploy — после апрува

## Что сделано в 5b

| ID | Изменение | Зона |
|----|-----------|------|
| 5b-1 | Prog10: заказы через **barista POS** (не shop cash) | Fly smoke |
| 5b-2 | `Devices::TokenResolver` — единый device lookup (kiosk/TV/cable) | RLS backlog |
| 5b-3 | Platform Pundit: `PlatformPolicy` + authorize tenants/orgs/**menu catalog** | `/admin` |
| 5b-4 | `TenantPolicy#open_as_manager?` → только UK | platform |
| 5b-5 | `UserRole` validation + backfill legacy `tenant_id` | TECH DEBT G-11 **FIXED** |
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

- Fly MCP Point A post-deploy (после включения kiosk/TV на точке)

## G-06 favorites persist (2026-08-31)

- `shop_customer_favorites` (RLS per tenant) + `Shop::FavoritesStore`
- Login merge session → DB via `CustomerSession.set_customer_id!`

## G-12 prep multi-point (2026-08-31)

- `prep_kitchen_sales_point_links` + `PrepKitchen::SalesPointRegistry`
- Demo: kitchen → Point A/B; dashboard + **UI `/prep_kitchen/sales_points`**
- **Queue wiring:** `LinkedSalesPointOrdersQuery` — заказы linked points (RLS per tenant GUC)

## Legacy shop CI (2026-08-31)

- CI: сняты exclude 4 файлов; `FakeTbankInit` stub — без skip на card pending

## Phase 6 prep — device tokens (2026-08-31)

- `rls_devices_token_lookup` — без `row_security off`
- `Rls::GucContext` — auth_login + device_token_lookup
- Manager: revoke + rotate_token UI
- Rack::Attack: tv_board throttles

## G-11 legacy user_roles (2026-08-31)

- Migration `backfill_user_roles_tenant_id` — NULL point staff → `users.tenant_id`
- `has_role_in_context?` — убран global nil bypass

## Device token lifecycle (2026-08-31)

- `Devices::TokenCredentials` + ENV `DEVICE_TOKEN_TTL_DAYS`
- Manager: revoke, rotate, reactivate + **policy banner + expiry pills** в UI
- Cron auto-rotation — out of scope

## ABAC-015 barista POS (2026-08-31)

- By design: shop/kiosk guard, barista POS при открытой смене вне расписания — не блокируется
- Каталог §B + `abac_full_enforcement_test`

## ActionCable G-03 (2026-08-31)

- `ApplicationCable::Connection` — auth_login + TV TokenResolver
- `OrdersChannel` — connection.current_user; tests `connection_test`

## Проверка

```bash
ruby bin/rails test test/policies/abac_full_enforcement_test.rb test/policies/
ruby bin/rails test test/integration/tv_board_test.rb test/integration/prep_kitchen/feature_flags_test.rb
ruby bin/prog10/prog10_staff_rbac_isolation.rb
```

## Связанные docs

- [ABAC_POLICIES.md](../phase_5_abac/ABAC_POLICIES.md) — ABAC-056/057 → Partial via TokenResolver
- [IB_MASTER_VERIFICATION_CHECKLIST.md](../IB_MASTER_VERIFICATION_CHECKLIST.md)
