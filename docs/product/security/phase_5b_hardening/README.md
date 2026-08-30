# Phase 5b — IB hardening (2026-08-30)

**Статус:** local done · Fly Prog10 — после deploy

## Что сделано в 5b

| ID | Изменение | Зона |
|----|-----------|------|
| 5b-1 | Prog10: заказы через **barista POS** (не shop cash) | Fly smoke |
| 5b-2 | `Devices::TokenResolver` — единый device lookup (kiosk/TV/cable) | RLS backlog |
| 5b-3 | Platform Pundit: `PlatformPolicy` + `authorize` tenants/orgs | `/admin` |
| 5b-4 | `TenantPolicy#open_as_manager?` → только UK | platform |
| 5b-5 | `UserRole` validation: tenant_id обязателен для point staff | TECH DEBT G-11 |

## Остаётся (low / product)

- Blog editor ABAC (ABAC-007)
- Favorites session-only (G-06)
- Prep multi-point (G-12)
- ABAC Partial rules priority 70 (operating hours edge cases) — monitor
- Fly MCP Point A post-deploy

## Проверка

```bash
ruby bin/rails test test/services/devices/token_resolver_test.rb test/models/user_role_test.rb
ruby bin/rails test test/integration/platform/ test/integration/auth/
ruby bin/prog10/prog10_staff_rbac_isolation.rb
```

## Связанные docs

- [ABAC_POLICIES.md](../phase_5_abac/ABAC_POLICIES.md) — ABAC-056/057 → Partial via TokenResolver
- [IB_MASTER_VERIFICATION_CHECKLIST.md](../IB_MASTER_VERIFICATION_CHECKLIST.md)
