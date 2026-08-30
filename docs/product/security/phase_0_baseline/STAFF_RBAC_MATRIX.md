# IB-0-3 — Staff RBAC Matrix

**Фаза:** 0 (baseline) + Phase 2–4 updates · дата baseline: 2026-08-30 · **Phase 4 COMPLETE:** 2026-08-30

Baseline-матрица staff RBAC: роль → панель → tenant → может/не может. Сверка **код + Prog10**. ABAC — placeholder Phase 5.

**Phase 2 FIXED:** `has_role_in_context?`, Pundit на критичных manager/prep_kitchen CRUD, `test/integration/staff/rbac_tenant_isolation_test.rb`.

---

## Таблица 1 — Роли × панели

| Role code | Role name (RU) | Panel URL | Tenant rule | Post-login redirect | Blocked if inactive? |
|-----------|----------------|-----------|-------------|---------------------|----------------------|
| `barista` | Бариста | `/barista/*` | `user.tenant_id` | `barista_dashboard_path` | yes — `reset_session` (`barista/base_controller.rb:34-37`) |
| `shift_manager` | Менеджер смены | `/manager/*` | `user.tenant_id` | `manager_dashboard_path` | yes (`manager/base_controller.rb:50-53`) |
| `general_manager` | Управляющий точки | `/manager/*` | `user.tenant_id` | `manager_dashboard_path` | yes |
| `franchise_manager` | Франчайзи | `/manager/*` | `session[:manager_tenant_id]` ∈ `organization.tenants` | `manager_dashboard_path` | yes |
| `prep_kitchen_manager` | Менеджер цеха | `/prep_kitchen/*` | `user.tenant_id` (tenant цеха) | `prep_kitchen_dashboard_path` | yes (`prep_kitchen/base_controller.rb:21-24`) |
| `prep_kitchen_worker` | Работник цеха | `/prep_kitchen/*` | `user.tenant_id` (tenant цеха) | `prep_kitchen_dashboard_path` | yes |
| `ук_global_admin` | Глобальный админ УК | `/admin/*`, `/manager/*` (с точкой) | platform: global; manager: `session[:manager_tenant_id]` | `platform_root_path` | yes |
| `blog_editor` | Редактор блога | `/blog/*` (CMS) | не привязан к точке продаж | `blog_root_path` | yes (blog login checks `active?`) |

**Franchise org switcher:** `POST /manager/switch_tenant` → `session[:manager_tenant_id]`; auto-pick first tenant if invalid (`manager/base_controller.rb:61-78`).

**UK + manager:** `ensure_uk_manager_tenant!` — без `manager_tenant_id` redirect на `/admin` (`manager/base_controller.rb:82-86`). Вход в manager через `platform/tenants#open_as_manager`.

**Prep kitchen = отдельный tenant:** demo `tenant_kitchen` ≠ point of sale (`demo/environment_setup.rb`).

---

## Таблица 2 — Роли × доступ (грубый RBAC)

| Role | Can access (screens/actions) | Cannot access | Evidence |
|------|------------------------------|---------------|----------|
| **barista** | `/barista` dashboard, orders queue, shift open, order status/cancel (Pundit), menu read, reports | `/manager`, `/admin`, `/prep_kitchen` | `barista/base_controller.rb`; Prog10 barista PASS; `barista_rbac_test.rb` |
| **shift_manager** | `/manager` dashboard, orders, payments/refunds/fiscal, shifts (open), reports, incidents, menu **read** | inventory, **staff**, **devices**, tv_settings, barista, prep_kitchen, platform | `shift_manager_rbac_test.rb` FORBIDDEN_PATHS; Prog10 «sidebar без Персонал/Устройств» |
| **general_manager** | shift_manager + inventory, **staff** (Pundit), **devices**, tv_settings, menu **price** update | barista panel, prep_kitchen, platform admin | `staff_management_visible?`; Prog10 GM devices PASS |
| **franchise_manager** | `/manager` + **tenant switcher** (org tenants only) | staff management UI, platform `/admin`, tenants других org | `accessible_manager_tenants`; `require_staff_management!` blocks staff |
| **prep_kitchen_manager** | `/prep_kitchen` dashboard, queue, recipes, inventory, movements create/confirm/cancel, stop_list, reports | barista, manager, platform | `prep_kitchen_manager_rbac_test.rb`; Prog10 PASS |
| **prep_kitchen_worker** | prep_kitchen read: queue, inventory, movements **view** | movements create/confirm/cancel (policy) | `StockMovementPolicy#create?` manager only |
| **ук_global_admin** | `/admin` full platform; `/manager` после выбора точки; monitoring, tenants CRUD | barista, prep_kitchen (без отдельной роли) | `platform/base_controller.rb`; Prog10 UK PASS |
| **blog_editor** | `/blog` posts CRUD, categories, drafts | staff panels, shop admin | `blog/application_controller.rb`; `auth/sessions_controller.rb:126-127` |

---

## Таблица 3 — Pundit policies

| Policy class | Actions defined | Controllers using `authorize` + `verify_authorized` | Phase 2 FIXED |
|--------------|-----------------|-----------------------------------------------------|---------------|
| `ApplicationPolicy` | index/show/create/update/destroy (default deny) | helpers → `has_role_in_context?` | ✅ |
| `OrderPolicy` | show?, index?, history?, create?, update_status?, cancel? | `barista/orders_controller`, **`manager/orders_controller`** | ✅ manager |
| `UserPolicy` | index?, show?, create?, update?, destroy? | `manager/staff_controller` | ✅ |
| `ProductTenantSettingPolicy` | index?, show?, update? | **`manager/menu_controller`** (index + update_price) | ✅ |
| `CashShiftPolicy` | show?, index?, create?, update?, close? | **`manager/shifts_controller`** | ✅ |
| `DevicePolicy` | index?, create?, create_kiosk?, update_tv_mode? | **`manager/devices_controller`** | ✅ NEW |
| `Finance::PaymentPolicy` | index? | **`manager/finance/payments_controller`** | ✅ NEW |
| `Finance::RefundPolicy` | index? | **`manager/finance/refunds_controller`** | ✅ NEW |
| `Finance::FiscalReceiptPolicy` | index? | **`manager/finance/fiscal_receipts_controller`** | ✅ NEW |
| `StockMovementPolicy` | index?, show?, create?, confirm?, cancel? | **`prep_kitchen/movements_controller`** | ✅ |
| `IngredientTenantStockPolicy` | index?, show?, update_min_qty? | **`prep_kitchen/inventory_controller`** | ✅ |
| `Manager::InventoryPolicy` | index? | **`manager/inventory_controller`** | ✅ |
| `ProductPolicy` | show?, index?, create?, update?, destroy? | — | platform Phase N |
| `CategoryPolicy` | CRUD | — | platform Phase N |
| `ProductModifierGroupPolicy` | CRUD | — | platform Phase N |
| `ProductModifierOptionPolicy` | CRUD | — | platform Phase N |
| `OrganizationPolicy` | CRUD (UK only) | — | platform Phase N |
| `TenantPolicy` | CRUD + open_as_manager? | — | platform Phase N |

**`skip_authorization` on base controllers:**

| Panel | File | Note |
|-------|------|------|
| Manager | `manager/base_controller.rb` | blanket skip; **critical controllers opt-in** (staff, menu, orders, shifts, devices, finance, **inventory**) |
| Prep kitchen | `prep_kitchen/base_controller.rb` | skip on base; **movements + inventory opt-in** |
| Platform | `platform/base_controller.rb` | UK gate only — **Phase 2 not touched** |
| Barista | — | **нет skip** — Pundit active on orders |

---

## Таблица 4 — Prog10 vs Code

| Scenario | Prog10 result | Code behavior | Match? | Risk if mismatch |
|----------|---------------|---------------|--------|------------------|
| UK → `/admin` | PASS | `require_uk_global_admin` | ✅ | — |
| UK → open_as_manager → devices | PASS | `platform/tenants#open_as_manager` sets session | ✅ | — |
| franchise → tenant switcher A/B | PASS | `ensure_franchise_tenant_session!` | ✅ | — |
| GM → `/manager/devices` | PASS | no path-level deny for GM | ✅ | — |
| shift_manager → no staff/devices | PASS | integration test FORBIDDEN_PATHS | ✅ | — |
| barista → only `/barista` | PASS | `require_barista_role` | ✅ | — |
| barista foreign order 404 | PASS (`prog10_staff_isolation.json`) | RLS + tenant scope | ✅ | — |
| prep_kitchen on sales tenant | 302 expected | barista role absent → redirect | ✅ | — |
| prep_kitchen_manager dashboard | PASS | `require_prep_kitchen_role` | ✅ | — |
| inactive user login | PASS (negative bad pwd) | `active?` check on login + each request | ✅ | — |
| blog_editor staff panels | not in Prog10 | redirect root / blog only | ⚠️ N/A | low — separate product |
| manager inventory for shift_manager | `shift_manager_rbac_test` FORBIDDEN + sidebar hidden | redirect + `Manager::InventoryPolicy` | ✅ FIXED |
| `has_role?` cross-tenant | `rbac_tenant_isolation_test` | **`has_role_in_context?`** + gate fixes | ✅ FIXED Phase 2 |
| Pundit on manager orders#show | integration + Pundit | **`authorize @order`** in manager orders | ✅ FIXED Phase 2 |

---

## Таблица 5 — ABAC placeholder (Phase 5)

| Attribute | Subject/Object | Example rule (future) | Currently in code? |
|-----------|----------------|----------------------|-------------------|
| `role` | User | shift_manager ≠ staff UI | partial — redirects, not policy |
| `shift_open` | User, CashShift | barista create order if shift open | partial — layout `@shift`, not enforced on all actions |
| `cash_shift_id` | Order | order belongs to open shift | yes — barista order creation service |
| `order.status` | Order | guest cancel only accepted/preparing | yes — `GuestOrderCancellationService` |
| `organization_id` | User, Tenant | franchise tenants filter | yes — `Tenant.where(organization_id:)` |
| `tenant.type` | Tenant | beta features | partial — tenant flags |
| `module_enabled` | Tenant, FeatureFlag | barista/prep_kitchen module | yes — `require_*_module!` |
| `user.active` | User | block all panels | yes — BUG-013 fix on bases |

---

## Таблица 6 — `[OWNER REVIEW]`

| Topic | Question to owner |
|-------|-------------------|
| shift_manager + `/manager/inventory` | **Нет** — только GM/franchise; URL redirect + Pundit + sidebar скрыт | ✅ FIXED 2026-08-30 |
| franchise_manager + staff | Нужен ли франчайзи доступ к персоналу своих точек? Сейчас `staff_management_visible?` = GM \| UK only. |
| `has_role?` без tenant | **Phase 2:** `has_role_in_context?` в staff gates; `has_role?` legacy | ✅ Phase 2 |
| blog_editor в staff matrix | **Phase 2 skipped — backlog** (отдельный blog CMS) | backlog |
| Manager Pundit rollout | Phase 2: devices, finance, orders, shifts, menu, prep_kitchen | ✅ done |

---

## Phase 2 — `has_role_in_context?` rules

| Role code | Tenant check |
|-----------|--------------|
| `barista`, `shift_manager`, `general_manager` | `user_roles.tenant_id` = context tenant OR `[TECH DEBT]` `tenant_id` nil |
| `franchise_manager` | role + `organization_id` match; tenant via `session[:manager_tenant_id]` |
| `ук_global_admin` | global role; manager mode uses `Current.tenant_id` from session |
| `prep_kitchen_manager`, `prep_kitchen_worker` | `user_roles.tenant_id` = prep kitchen tenant |
| `blog_editor` | **out of scope Phase 2** — legacy `has_role?` |

**`[TECH DEBT]`** Global `user_roles` without `tenant_id` still grant access in context — fix in Phase 3+.

**API:** `User#has_role_in_context?(code, tenant_id: Current.tenant_id, organization_id: nil)` · `has_any_role_in_context?`

---

## Дополнительно: role context (Phase 2)

`has_role?` — legacy, без tenant filter (для blog и обратной совместимости).

`has_role_in_context?` — **канон staff gates** (`app/models/user.rb`).

`UserRole.tenant_id` используется в `point_staff_role_in_context?`.

`Manager::StaffController` фильтрует staff по `UserRole.where(tenant_id: tid)` — эталон tenant-aware назначения ролей.

**shift_manager Pundit denies:** `UserPolicy` (staff) — `privileged_manager?` false; `DevicePolicy` — `privileged_manager?` false; `Manager::InventoryPolicy` — `general_or_franchise_manager?` false; UI gates `require_staff_management!` / `require_privileged_manager!` / `inventory_management_visible?` — defense in depth.

---

## Роли в demo / seeds

`Demo::EnvironmentSetup::ROLES` + `USERS` — 8 ролей coffee ops (без blog_editor). blog_editor создаётся в `lib/tasks/setup.rake` / `blog.rake`.

---

## Источники

Policies: `app/policies/*.rb`, `app/policies/finance/*.rb`. Controllers: manager/barista/prep_kitchen/platform/blog bases. Tests: `test/integration/auth/*_rbac_test.rb`, **`test/integration/staff/rbac_tenant_isolation_test.rb`**. Prog10: `prog10_rbac_matrix.md`, `prog10_staff_isolation.json`.
