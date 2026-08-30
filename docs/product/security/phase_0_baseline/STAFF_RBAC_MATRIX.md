# IB-0-3 — Staff RBAC Matrix

**Фаза:** 0 (baseline) · **Код не менялся** · дата: 2026-08-30

Baseline-матрица staff RBAC: роль → панель → tenant → может/не может. Сверка **код + Prog10**. ABAC — placeholder Phase 5.

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

| Policy class | Actions defined | Controllers using `authorize` | Panels with `skip_authorization` |
|--------------|-----------------|------------------------------|----------------------------------|
| `ApplicationPolicy` | index/show/create/update/destroy (default deny) | — | — |
| `OrderPolicy` | show?, index?, history?, create?, update_status?, cancel? | `barista/orders_controller.rb` | barista: **no skip** |
| `UserPolicy` | index?, show?, create?, update?, destroy? | `manager/staff_controller.rb` | manager base: **skip** (staff overrides) |
| `ProductTenantSettingPolicy` | index?, show?, update? | `manager/menu_controller.rb` (update_price) | manager base: skip except menu |
| `CashShiftPolicy` | show?, index?, create?, update?, close? | — (не вызывается из controllers) | manager, barista |
| `ProductPolicy` | show?, index?, create?, update?, destroy? | — | manager, platform |
| `CategoryPolicy` | CRUD | — | platform |
| `ProductModifierGroupPolicy` | CRUD | — | platform |
| `ProductModifierOptionPolicy` | CRUD | — | platform |
| `OrganizationPolicy` | CRUD (UK only) | — | platform |
| `TenantPolicy` | CRUD + open_as_manager? | — | platform |
| `StockMovementPolicy` | index?, show?, create?, confirm?, cancel? | — | prep_kitchen |
| `IngredientTenantStockPolicy` | index?, show?, update_min_qty? | — | prep_kitchen |

**`skip_authorization` on base controllers:**

| Panel | File | Note |
|-------|------|------|
| Manager | `manager/base_controller.rb:12` | blanket skip; staff + menu opt-in |
| Prep kitchen | `prep_kitchen/base_controller.rb:11` | role gate only |
| Platform | `platform/base_controller.rb:11` | UK gate only |
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
| manager inventory for shift_manager | not explicit in Prog10 | **no redirect** — path accessible | ⚠️ REVIEW | shift_manager may open inventory URL |
| `has_role?` cross-tenant | not tested | **no tenant filter on UserRole** | ❌ HOLE | role leak across tenant switch |
| Pundit on manager orders#show | not in Prog10 | **no authorize** — role gate only | ⚠️ REVIEW | relies on RLS + manager_role |

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
| shift_manager + `/manager/inventory` | Должен ли shift_manager видеть склад (inventory)? Сейчас URL не в FORBIDDEN_PATHS теста — только staff/devices/tv. |
| franchise_manager + staff | Нужен ли франчайзи доступ к персоналу своих точек? Сейчас `staff_management_visible?` = GM \| UK only. |
| `User#has_role?` без tenant | Закрывать в Phase 2: `has_role?(code, tenant_id: Current.tenant_id)`? |
| blog_editor в staff matrix | Оставляем вне coffee ops RBAC или включаем в Phase 4 DoD? |
| TenantPolicy#open_as_manager? = true | Ограничить только UK или любой manager role? Сейчас platform gate достаточен. |
| Manager Pundit rollout | Phase 2: приоритет — devices, inventory, shift close, refunds? |

---

## Дополнительно: `has_role?` и tenant

```33:35:app/models/user.rb
  def has_role?(role_code)
    roles.exists?(code: role_code)
  end
```

`UserRole` имеет `tenant_id`, но **не используется** в `has_role?`:

```1:7:app/models/user_role.rb
class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
  belongs_to :tenant, optional: true
```

`Manager::StaffController` фильтрует staff по `UserRole.where(tenant_id: tid)` — эталон tenant-aware назначения ролей.

---

## Роли в demo / seeds

`Demo::EnvironmentSetup::ROLES` + `USERS` — 8 ролей coffee ops (без blog_editor). blog_editor создаётся в `lib/tasks/setup.rake` / `blog.rake`.

---

## Источники

Policies: `app/policies/*.rb`. Controllers: manager/barista/prep_kitchen/platform/blog bases. Tests: `test/integration/auth/*_rbac_test.rb`. Prog10: `prog10_rbac_matrix.md`, `prog10_staff_isolation.json`.
