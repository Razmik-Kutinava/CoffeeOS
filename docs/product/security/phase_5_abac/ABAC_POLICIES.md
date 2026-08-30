# ABAC — каталог правил

**Фаза:** IB Phase 5 · **Дата:** 2026-08-30 · **Правил:** 58  
**Атрибуты:** [ABAC_ATTRIBUTES.md](ABAC_ATTRIBUTES.md)

Легенда **Implemented:** `Y` — в коде Phase 5 · `Partial` — частично (controller + policy) · `N` — документ / Phase 5b

---

## A. Вход и роль (001–010)

| ID | Name (RU) | Subject attrs | Object attrs | Action | Condition | Priority | Impl | Code ref | 5b |
|----|-----------|---------------|--------------|--------|-----------|----------|------|----------|-----|
| ABAC-001 | Staff login | user.active | — | login | active = true | 100 | Y | `auth/sessions_controller`, base `active?` | |
| ABAC-002 | Barista → /barista | role=barista | — | panel_access | role in context | 100 | Y | `barista/base_controller#require_barista_role` | |
| ABAC-003 | Manager → /manager | role∈manager set | — | panel_access | has_any_role_in_context | 100 | Y | `manager/base_controller#require_manager_role` | |
| ABAC-004 | Prep → /prep_kitchen | role∈prep set | — | panel_access | prep role on tenant | 100 | Y | `prep_kitchen/base_controller` | |
| ABAC-005 | UK → /admin | role=ук_global_admin | — | panel_access | UK role | 100 | Y | `platform/base_controller` | |
| ABAC-006 | Role на tenant | role, tenant_id | — | any_staff | has_role_in_context?(role, tenant_id) | 90 | Y | `User#has_role_in_context?` Phase 2 | |
| ABAC-007 | Blog editor | role=blog_editor | — | /blog/* | blog role | 100 | **Y** | `Blog::PostPolicy` | |
| ABAC-008 | Login без ролей | role count | — | login | roles > 0 | 100 | Y | `auth/sessions_controller` | |
| ABAC-009 | Session user_id | session | — | staff_request | session present | 100 | Y | base `require_login` | |
| ABAC-010 | Tenant GUC | tenant_id | — | staff_mutation | Current.tenant_id set + SET LOCAL | 100 | Y | base `set_tenant_context` | |

---

## B. Модули точки (011–015)

| ID | Name | Subject | Object | Action | Condition | Pri | Impl | Code ref | 5b |
|----|------|---------|--------|--------|-----------|-----|------|----------|-----|
| ABAC-011 | Barista panel module | module_enabled.barista | tenant | panel | FF barista enabled or absent | 80 | **Y** | `TenantModulePolicy` + `OrderPolicy` | |
| ABAC-012 | Prep panel module | module_enabled.prep_kitchen | tenant | panel | FF prep_kitchen enabled | 80 | **Y** | `TenantModulePolicy` + `StockMovementPolicy` | |
| ABAC-013 | Shop public menu | tenant_id | tenant | read_menu | tenant resolved | 90 | Y | shop base tenant | |
| ABAC-014 | Shop API tenant | tenant_id | request | api_call | X-Shop-Tenant / slug | 90 | Y | shop API middleware | |
| ABAC-015 | Operating hours closed | tenant hours | order | create | reject if closed (shop/kiosk) | 70 | **Y** | `TenantOperatingHoursEnforcement` + shop guard | |

---

## C. Смена (016–025)

| ID | Name | Subject | Object | Action | Condition | Pri | Impl | Code ref | 5b |
|----|------|---------|--------|--------|-----------|-----|------|----------|-----|
| ABAC-016 | Barista POS create | shift_open, role=barista | Order | create | shift_open AND barista | 90 | **Y** | `OrderPolicy#create?` | |
| ABAC-017 | Barista update_status | shift_open, in_shift | Order | update_status | shift_open AND in_shift | 90 | **Y** | `OrderPolicy#update_status?` | |
| ABAC-018 | Barista cancel | shift_open, in_shift | Order | cancel | shift_open AND in_shift | 90 | **Y** | `OrderPolicy#cancel?` | |
| ABAC-019 | Barista board view | shift_open ∨ vitrina | Order | read_board | BoardOrdersQuery scope | 80 | **Y** | `OrderPolicy#read_board?` + query | |
| ABAC-020 | Open shift | shift_open | CashShift | create | NOT shift_open | 85 | **Y** | `CashShiftPolicy#create?` | |
| ABAC-021 | Close shift | shift_open | CashShift | close | shift_open | 85 | **Y** | `CashShiftPolicy#close?` | |
| ABAC-022 | Shift_manager close wizard | shift_open, role | CashShift | close_wizard | open shift exists + id match | 80 | **Y** | `CashShiftPolicy#close?` + CloseWizard | |
| ABAC-023 | Carryover preparing | shift_open | Order | update | carryover in BoardOrdersQuery | 75 | Y | `BoardOrdersQuery` SQL | |
| ABAC-024 | Order cash_shift_id POS | shift_open | Order | mutate | order.cash_shift_id = open shift OR in_shift | 90 | **Y** | OrderPolicy + query | |
| ABAC-025 | Vitrina cash_shift null | shift_open | Order(mobile) | read/mutate | created_at >= shift.opened_at | 85 | **Y** | `BoardOrdersQuery` | |

---

## D. Заказы — barista/manager (026–035)

| ID | Name | Subject | Object | Action | Condition | Pri | Impl | Code ref | 5b |
|----|------|---------|--------|--------|-----------|-----|------|----------|-----|
| ABAC-026 | Order show barista | in_shift | Order | show | barista → in_shift | 90 | **Y** | `OrderPolicy#show?` | |
| ABAC-027 | Order show manager | tenant_id | Order | show | for_current_tenant | 90 | Y | RLS + policy any_manager | |
| ABAC-028 | Order cancel barista | shift_open | Order | cancel | !shift_open → deny | 90 | **Y** | OrderPolicy | |
| ABAC-029 | Order cancel shift_manager | shift_open | Order | cancel | shift_open required | 85 | **Y** | OrderPolicy#cancel? | |
| ABAC-030 | Order cancel GM | tenant_id | Order | cancel | tenant OK, no shift gate | 85 | **Y** | OrderPolicy | |
| ABAC-031 | Order status FSM | order.status | Order | transition | valid transition | 80 | Y | `OrderStatusUpdateService` | |
| ABAC-032 | Order history manager | tenant_id | Order | history | tenant scope | 85 | Y | OrderPolicy#history? | |
| ABAC-033 | Finance payments index | tenant_id, shift? | Payment | index | tenant + shift Scope | 75 | **Y** | `Finance::PaymentPolicy::Scope` | |
| ABAC-034 | Finance refunds | tenant_id | Refund | index | tenant | 80 | Y | Finance::RefundPolicy | |
| ABAC-035 | Incidents | tenant_id | Incident | CRUD | tenant scope | 75 | **Y** | `Manager::IncidentPolicy` | |

---

## E. Manager hierarchy (036–042)

| ID | Name | Subject | Object | Action | Condition | Pri | Impl | Code ref | 5b |
|----|------|---------|--------|--------|-----------|-----|------|----------|-----|
| ABAC-036 | Staff index/create | privileged_manager | User | CRUD | privileged_manager? | 90 | Y | `UserPolicy` + UI gate | |
| ABAC-037 | Staff destroy | role=ук_global_admin | User | destroy | UK only | 95 | Y | `UserPolicy#destroy?` | |
| ABAC-038 | Devices index/create | privileged_manager | Device | CRUD | privileged_manager? | 90 | Y | `DevicePolicy` | |
| ABAC-039 | Menu price patch | privileged_manager | ProductTenantSetting | update | GM/franchise/UK | 85 | Y | `ProductTenantSettingPolicy` | |
| ABAC-040 | Shift_manager sidebar staff | role=shift_manager | — | UI | NOT staff_management_visible | 80 | Y | `staff_management_visible?` | |
| ABAC-041 | Shift_manager devices | role=shift_manager | Device | access | require_privileged_manager! | 90 | Y | devices controller gate | |
| ABAC-042 | Reports/incidents privileged | role | — | access | shift_manager OK read | 70 | **Y** | `Manager::ReportPolicy` | |

---

## F. Franchise / UK (043–048)

| ID | Name | Subject | Object | Action | Condition | Pri | Impl | Code ref | 5b |
|----|------|---------|--------|--------|-----------|-----|------|----------|-----|
| ABAC-043 | Franchise switch tenant | organization_id | Tenant | switch | tenant.org = user.org | 95 | Y | `switch_tenant` + tests | |
| ABAC-044 | Franchise data | organization_id | * | read | org match | 95 | Y | session tenant list | |
| ABAC-045 | UK manager без tenant | session.manager_tenant_id | — | /manager | tenant required | 95 | Y | `ensure_uk_manager_tenant!` | |
| ABAC-046 | UK platform orgs | role=ук_global_admin | Organization | CRUD | UK only | 95 | Y | platform base | |
| ABAC-047 | GM single tenant | user.tenant_id | Tenant | access | fixed tenant | 90 | Y | manager set_tenant_context | |
| ABAC-048 | Tenant context switch | role | Tenant | switch | franchise OR UK | 90 | Y | session guards | |

---

## G. Prep kitchen (049–052)

| ID | Name | Subject | Object | Action | Condition | Pri | Impl | Code ref | 5b |
|----|------|---------|--------|--------|-----------|-----|------|----------|-----|
| ABAC-049 | Prep tenant type | tenant.type | Tenant | panel | production_kitchen | 90 | **Y** | `StockMovementPolicy#prep_access?` | |
| ABAC-050 | Movements create | role=prep_kitchen_manager | StockMovement | create | manager + prep_access | 90 | **Y** | StockMovementPolicy | |
| ABAC-051 | Movements read worker | role=prep_kitchen_worker | StockMovement | index/show | worker + prep_access | 85 | **Y** | StockMovementPolicy | |
| ABAC-052 | Stock tenant | tenant_id | IngredientTenantStock | CRUD | for_current_tenant | 90 | Y | RLS + inventory policy | |

---

## H. Shop ownership (053–055)

| ID | Name | Subject | Object | Action | Condition | Pri | Impl | Code ref | 5b |
|----|------|---------|--------|--------|-----------|-----|------|----------|-----|
| ABAC-053 | Order show shop | customer_id | Order | show | customer_id match / guest token | 95 | Y | shop API Phase 1 | |
| ABAC-054 | Payment init | customer_id | Order | pay | order visible to session | 95 | Y | payment controllers | |
| ABAC-055 | Profile/cards | customer session | MobileCustomer | profile | OTP session | 95 | Y | shop auth | |

*(Shop — ownership, не staff role; в каталоге для полноты модели доступа.)*

---

## I. Backlog kiosk/TV (056–058)

| ID | Name | Subject | Object | Action | Condition | Pri | Impl | Code ref | 5b |
|----|------|---------|--------|--------|-----------|-----|------|----------|-----|
| ABAC-056 | Kiosk device token | device.type, token | Device | api | valid device_token + kiosk module | — | **Y** | `Devices::DeviceAuthPolicy` | |
| ABAC-057 | TV board token | device.type=tv | Device | board | token + BoardOrdersQuery scope | — | **Y** | `TvBoardPolicy` + query | |
| ABAC-058 | Kiosk order create | module kiosk | Order | create | device-bound via X-Device-Token | — | **Y** | `Devices::KioskOrderGuard` + OrderCreator | |

---

## Приложение A — Матрица shift_open=false

| Action | barista | shift_manager | general_manager |
|--------|---------|---------------|-----------------|
| Order create (POS) | **DENY** | N/A | N/A |
| Order show (in_shift) | **DENY** (no scope) | ALLOW (tenant) | ALLOW |
| Order update_status | **DENY** | N/A | N/A |
| Order cancel | **DENY** | **DENY** | ALLOW |
| Open shift (create) | ALLOW* | ALLOW* | ALLOW* |
| Close shift | DENY | DENY | DENY |

\* ABAC-020: open shift allowed when `shift_open=false` (нет открытой смены).

---

## Приложение B — Enforced in Phase 5 code

| Rule IDs | Policy / component |
|----------|-------------------|
| ABAC-016–018, 026, 028–030 | `OrderPolicy` |
| ABAC-020–021 | `CashShiftPolicy` |
| ABAC-049–051 | `StockMovementPolicy` |
| ABAC-036–038 | `UserPolicy`, `DevicePolicy` (RBAC + tenant context) |
| Infrastructure | `PolicyContext`, `pundit_user` in 3 base controllers |

**Enforced count:** 58 правил — полный каталог **Y** (barista POS вне shop hours — осознанное исключение ABAC-015, см. `OperatingHoursBoard`).

Phase 5c: policies + scopes без изменения RBAC-контура.
