# IB-3-1 — RLS & Tenant GUC Audit

**Фаза:** 3 · дата: 2026-08-30 · **миграции RLS не делались**

## HOLE / BACKLOG (pre-code)

| # | Location | Severity | Action |
|---|----------|----------|--------|
| 1 | `kiosk/api/auth_controller.rb` | medium (prod N/A) | **BACKLOG** — Phase 3 SKIP |
| 2 | `tv_boards_controller.rb` | medium (prod N/A) | **BACKLOG** — Phase 3 SKIP |
| 3 | `application_cable/connection.rb` | medium (prod N/A) | **BACKLOG** — Phase 3 SKIP |
| 4 | `shop/customer_tenant_history.rb` | low | **OK** — cross-city shop by design |
| 5 | Jobs: `Order.find_by(id)` без GUC | low | **OK** — enqueue internal; broadcaster scopes by `order.tenant_id` |
| 6 | `Payments::StuckPaymentsCheckJob` | info | **OK** — intentional global scan |
| 7 | `Payments::TbankCallbackJob` | info | **OK** — webhook lookup by signed OrderId |
| 8 | Prep multi-point | info | **BACKLOG** — не Phase 3 |
| — | New RLS policies | — | **NEED_MIGRATION:** none (awaiting owner if found later) |

---

## Inventory table

Каждая строка = место в коде. **GUC** = `SET LOCAL app.current_tenant_id` (+ `user_id` где есть).

### HTTP — base controllers

| Location | Sets tenant GUC? | row_security off? | Why | Risk | Action |
|----------|------------------|-------------------|-----|------|--------|
| `ApplicationController#set_pg_context` | ✅ optional tenant + user | no | Единая точка GUC для staff | — | **OK** |
| `Barista::BaseController#set_tenant_context` | ✅ `user.tenant_id` + user_id | no | Staff barista = 1 tenant | cross-tenant via wrong user_roles | **OK** (Phase 2 test) |
| `Manager::BaseController#set_tenant_context` | ✅ GM/SM: user.tenant; franchise/UK: session | no | Franchise/UK switcher | org escape | **OK** + regression tests |
| `Manager::TenantContextController#update` | no (session only) | no | Switch `manager_tenant_id`; org check for franchise | foreign org tenant | **OK** (`organization_id` guard) |
| `PrepKitchen::BaseController#set_tenant_context` | ✅ user.tenant_id | no | Prep tenant ≠ sales point | multi-point backlog | **OK** |
| `Platform::BaseController#assign_current_for_rls` | user_id only (no tenant) | no | UK global admin; all orgs by design | — | **OK** |
| `Shop::Api::BaseController#with_shop_tenant!` | ✅ transaction + tenant from header | no | Shop vitrina GUC per request | wrong X-Shop-Tenant | **OK** (Phase 1) |
| `Auth::SessionsController` | sets Current on login | no | Redirect by role | — | **OK** |

### ApplicationRecord

| Location | Sets tenant GUC? | row_security off? | Why | Risk | Action |
|----------|------------------|-------------------|-----|------|--------|
| `ApplicationRecord#with_postgres_context` | ✅ on save if transaction + Current | no | Backup GUC on AR writes | double-set harmless | **OK** |
| `ApplicationRecord#set_tenant_id` | Current → column | no | Auto tenant_id on create | blank tenant in dev/test warn | **OK** |

### Device / TV / Kiosk / Cable (SKIP refactor)

| Location | Sets tenant GUC? | row_security off? | Why | Risk | Action |
|----------|------------------|-------------------|-----|------|--------|
| `Kiosk::Api::AuthController` | ✅ after device lookup | ✅ device lookup | Token lookup before tenant known | token brute-force | **BACKLOG** |
| `TvBoardsController#show` | ✅ after device lookup | ✅ device lookup | URL token auth | same | **BACKLOG** |
| `ApplicationCable::Connection` | no | ✅ user/device lookup | Session or tv cookie | guest channels separate | **BACKLOG** |

### Services

| Location | Sets tenant GUC? | row_security off? | Why | Risk | Action |
|----------|------------------|-------------------|-----|------|--------|
| `Shop::ReadyPushClaim#claim!` | ✅ in transaction | no | Atomic ready_notified claim under RLS | — | **OK** |
| `Shop::CustomerTenantHistory` | no | ✅ city peers + order stats | Cross-tenant city dropdown (shop UX) | leaks tenant list in city | **OK** (public sales_point metadata) |
| `Platform::TenantOnboarding::Provision` | ✅ `@tenant.id` | no | Onboarding bootstrap | — | **OK** |
| `Platform::Menu::ProductTenantSync` | ✅ per target tenant | no | UK menu sync | — | **OK** |
| `Demo::EnvironmentSetup#with_tenant_rls!` | ✅ | no | Demo seeds scoped | — | **OK** |

### Background jobs

| Location | Sets tenant GUC? | row_security off? | Why | Risk | Action |
|----------|------------------|-------------------|-----|------|--------|
| `BroadcastTvColumnsJob` | explicit `tenant_id` arg; queries `where(tenant_id:)` | no | Pattern reference for jobs | — | **OK** |
| `Barista::BroadcastOrderBoardJob` | no; uses `Order.find_by(id)` | no | Internal enqueue; broadcaster uses order.tenant_id | IDOR if job args forged | **OK** (queue internal) |
| `Shop::ReadyPushJob` | via `ReadyPushClaim` for UPDATE | no | Push on ready | — | **OK** |
| `Shop::OrderReadyCascadeJob` | no | no | SMS cascade | same as above | **OK** |
| `Shop::SendPushNotificationJob` | no; notification has tenant_id | no | FCM delivery | — | **OK** |
| `Payments::TbankCallbackJob` | no | no | Webhook: find Payment by OrderId from signed payload | — | **OK** |
| `Payments::StuckPaymentsCheckJob` | no | no | Global stuck scan + Telegram | cross-tenant read intentional | **OK** |
| `SendOrderReceiptEmailJob` | no | no | Lookup OrderEmail by PK | — | **OK** |
| `SyncContactToCrmJob` | no | no | CRM placeholder | — | **OK** |
| `TelegramAlertJob` | no | no | External HTTP only | — | **OK** |

### Rake / test / acceptance

| Location | Sets tenant GUC? | row_security off? | Why | Risk | Action |
|----------|------------------|-------------------|-----|------|--------|
| `lib/tasks/tenant_context.rake` | ✅ | no | Dev console helper | — | **OK** |
| `lib/tasks/rls_check.rake` | ✅ | no | RLS verification task | — | **OK** |
| `test/support/rls_test_helper.rb` | ✅ + ROLE | no | Integration RLS tests | — | **OK** |
| `bin/acceptance/b21_acceptance_prep.rb` | ✅ / off | ✅ | Fly acceptance script | — | **OK** (ops) |

---

## Franchise / UK guards (verified)

| Guard | Code | Test |
|-------|------|------|
| Franchise switch org | `TenantContextController`: `tenant.organization_id == current_user.organization_id` | `tenant_rls_isolation_test`, `franchise_manager_rbac_test` |
| UK manager tenant | `ensure_uk_manager_tenant!`: redirect platform if no `session[:manager_tenant_id]` | `tenant_rls_isolation_test` |
| UK platform scope | all orgs — **by design**, not limited in Phase 3 | `platform_uk_rbac_test` |

---

## Backlog section (explicit SKIP)

| File | Reason |
|------|--------|
| `app/controllers/kiosk/api/auth_controller.rb` | Phase 3 SKIP — отдельная задача когда kiosk в prod |
| `app/controllers/tv_boards_controller.rb` | Phase 3 SKIP — TV refactor отложен |
| `app/channels/application_cable/connection.rb` | Phase 3 SKIP — cable refactor отложен |
| Prep 1 kitchen → N sales points | Product backlog, не RLS Phase 3 |

---

## NEED_MIGRATION (STOP — owner approval)

**None in this audit.** Новые PostgreSQL RLS policies не предлагались.

Если при prod-включении RLS на app role jobs перестанут находить записи — рассмотреть `ApplicationRecord.with_tenant` wrapper (код) без новых policies.

---

## Job tenant strategy summary

| Strategy | Jobs |
|----------|------|
| Explicit `tenant_id` argument + scoped queries | `BroadcastTvColumnsJob` |
| GUC in service transaction | `ReadyPushClaim` (used by `ReadyPushJob`) |
| PK lookup + downstream scoped by association | `BroadcastOrderBoardJob`, receipt/cascade jobs |
| Global / webhook cross-tenant | `TbankCallbackJob`, `StuckPaymentsCheckJob` |

---

## Audit script

```bash
ruby bin/audit/tenant_guc_inventory.rb
```

Exit 0 always; human-readable report for CI/manual. **Не блокирует CI** без отдельного апрува.

---

## Sources

`application_controller.rb`, `*/base_controller.rb`, `tenant_context_controller.rb`, `shop/api/base_controller.rb`, `application_record.rb`, `app/jobs/**/*.rb`, `app/services/shop/*.rb`, `platform/tenant_onboarding/*`, `demo/environment_setup.rb`, Phase 0 `ACTORS_AND_ACCESS.md`.
