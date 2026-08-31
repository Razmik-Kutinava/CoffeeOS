# ABAC — каталог атрибутов

**Фаза:** IB Phase 5 · **Дата:** 2026-08-30  
**Связь:** [ABAC_POLICIES.md](ABAC_POLICIES.md) · [ROLES_AND_PERMISSIONS.md](../ROLES_AND_PERMISSIONS.md)

---

## 1. Назначение

ABAC (Attribute-Based Access Control) в CoffeeOS — **тонкий слой поверх RBAC**. Роль (`role`) остаётся первым атрибутом; дополнительные атрибуты уточняют «можно ли действие в текущем контексте» (смена открыта, заказ в scope смены, тип точки и т.д.).

Реализация: `PolicyContext` → Pundit policies.

---

## 2. Атрибуты субъекта (Subject)

| Атрибут | Тип | Источник | Описание |
|---------|-----|----------|----------|
| `role` | string | `UserRole` + `Current.role_code` | RBAC-роль в контексте tenant (`has_role_in_context?`) |
| `user.active` | boolean | `users.status` | Заблокированный пользователь — deny на все staff-панели |
| `user.id` | uuid | session | Актёр для audit |
| `tenant_id` | uuid | `Current.tenant_id` / `user.tenant_id` | Точка продаж или цех |
| `organization_id` | uuid | `users.organization_id` | Франшиза — scope точек org |
| `privileged_manager` | derived | GM ∨ franchise ∨ UK | Персонал, устройства, цены |
| `shift_open` | boolean | open `CashShift` на tenant | Смена открыта на точке |
| `module_enabled.*` | boolean | `FeatureFlag` | Модули barista / prep_kitchen |

---

## 3. Атрибуты объекта (Object)

| Атрибут | Тип | Источник | Описание |
|---------|-----|----------|----------|
| `order.tenant_id` | uuid | Order | RLS + `for_current_tenant` |
| `order.cash_shift_id` | uuid? | Order | Привязка к смене; NULL — витрина |
| `order.status` | enum | Order | FSM статусов |
| `order.source` | string | Order | mobile / barista / kiosk / manual |
| `in_shift` | derived | `BoardOrdersQuery.shift_accessible_scope` | Заказ виден баристе в текущей смене |
| `tenant.type` | enum | Tenant | `sales_point` / `production_kitchen` |
| `customer_id` | uuid? | Order / MobileCustomer | Shop ownership (не role) |
| `tenant.hours_open` | derived | `TenantOperatingHours#open_now?` | Точка в расписании УК (B1.11) |
| `device.type` | string | Device | kiosk / tv (Phase 5b backlog) |

---

## 4. PolicyContext

Путь: `app/policies/policy_context.rb`

```ruby
PolicyContext.build(
  user: current_user,
  tenant_id: Current.tenant_id,
  role_code: Current.role_code,
  shift: open_cash_shift,      # nil если закрыта
  tenant: current_tenant       # опционально
)
```

### Helpers

| Метод | Смысл |
|-------|-------|
| `shift_open?` | Есть open CashShift |
| `in_shift?(order)` | Заказ в scope текущей смены (POS + vitrina + carryover) |
| `module_enabled?(:barista)` | FeatureFlag; nil → enabled (как в base controller) |
| `tenant_open?` | `TenantOperatingHoursEnforcement.accepting_online_orders?` — shop/kiosk guard (ABAC-015); **не** применяется к barista POS |
| `production_kitchen?` | tenant.type = production_kitchen |
| `user_active?` | status active |

### Передача в Pundit

`pundit_user` в `Barista::BaseController`, `Manager::BaseController`, `PrepKitchen::BaseController` возвращает `PolicyContext`.

---

## 5. Группы правил (см. ABAC_POLICIES)

| Группа | ID | Кол-во |
|--------|-----|--------|
| A. Вход и роль | ABAC-001…010 | 10 |
| B. Модули точки | ABAC-011…015 | 5 |
| C. Смена | ABAC-016…025 | 10 |
| D. Заказы barista/manager | ABAC-026…035 | 10 |
| E. Manager hierarchy | ABAC-036…042 | 7 |
| F. Franchise / UK | ABAC-043…048 | 6 |
| G. Prep kitchen | ABAC-049…052 | 4 |
| H. Shop ownership | ABAC-053…055 | 3 |
| I. Backlog kiosk/TV | ABAC-056…058 | 3 |
| **Итого** | | **58** |

---

## 6. Phase 5 vs Phase 5b

| Phase 5 (сейчас) | Phase 5b (backlog) |
|------------------|-------------------|
| Каталог ≥50 правил | Полный enforce всех правил в коде |
| PolicyContext + 4 policies | Kiosk/TV token ABAC |
| shift_open / in_shift на barista orders | Blog ABAC |
| ≥15 ABAC tests | Platform Pundit + ABAC |
