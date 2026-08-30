# CoffeeOS — Роли и права доступа

**Дата:** 2026-08-30 · **Фаза ИБ:** 5 (ABAC-lite local)  
**Аудитория:** владелец, заказчик, менеджеры продукта

---

## 1. Зачем этот документ

CoffeeOS обслуживает несколько типов пользователей: сотрудники точек, управляющая компания, гости витрины и устройства (киоск, TV). У каждого типа — своя модель входа и свои ограничения. Этот документ описывает **кто что может делать** в продукте на текущую дату, без технического жаргона.

Документ собран по коду и результатам фаз ИБ 0–4. Детальные матрицы для разработки: [phase_0_baseline/](phase_0_baseline/), аудит RLS: [phase_3_tenant_rls/RLS_TENANT_AUDIT.md](phase_3_tenant_rls/RLS_TENANT_AUDIT.md).

---

## 2. Персонажи (кратко)

Полная карта актёров: [ACTORS_AND_ACCESS.md](phase_0_baseline/ACTORS_AND_ACCESS.md).

| Персонаж | Кто это | Вход | Панель / API |
|----------|---------|------|--------------|
| **Бариста** | Сотрудник точки, принимает заказы | `/login` | `/barista` |
| **Менеджер смены** | Старший смены | `/login` | `/manager` (ограниченный) |
| **Управляющий точки** | Полный доступ к своей точке | `/login` | `/manager` |
| **Франчайзи** | Владелец нескольких точек одной организации | `/login` + переключатель точек | `/manager` |
| **Менеджер цеха** | Склад/производство (отдельный tenant) | `/login` | `/prep_kitchen` |
| **Работник цеха** | Просмотр очереди и склада | `/login` | `/prep_kitchen` (только чтение движений) |
| **Глобальный админ УК** | Управляющая компания, все организации | `/login` | `/admin` + `/manager` (после выбора точки) |
| **Гость витрины** | Покупатель без регистрации | Витрина `/shop` | Shop API (cookie) |
| **Клиент витрины** | Покупатель после OTP | Витрина + OTP | Shop API (с `customer_id`) |
| **Киоск / TV** | Устройство точки | Токен устройства | Kiosk API / TV board |

**Важно:** сотрудник (`User`) и клиент витрины (`MobileCustomer`) — разные учётные записи. Общего логина нет.

---

## 3. Staff: роли × панели × tenant

| Роль | Панель | Привязка к точке (tenant) |
|------|--------|---------------------------|
| `barista` | `/barista/*` | `user.tenant_id` — одна точка |
| `shift_manager` | `/manager/*` | `user.tenant_id` |
| `general_manager` | `/manager/*` | `user.tenant_id` |
| `franchise_manager` | `/manager/*` + switcher | `session[:manager_tenant_id]` ∈ точки своей `organization` |
| `prep_kitchen_manager` | `/prep_kitchen/*` | `user.tenant_id` (tenant цеха, ≠ точка продаж) |
| `prep_kitchen_worker` | `/prep_kitchen/*` | `user.tenant_id` (цех) |
| `ук_global_admin` | `/admin/*`; `/manager/*` после выбора точки | platform: глобально; manager: `session[:manager_tenant_id]` |
| `blog_editor` | `/blog/*` | не привязан к точке продаж (отдельный CMS-контур) |

**Франчайзи:** переключение точки — `POST /manager/switch_tenant`; доступ только к точкам своей организации.  
**УК в manager:** без выбранной точки в сессии — редирект в `/admin`.

---

## 4. Staff: роли × ключевые действия

| Роль | Может | Не может | Панель |
|------|-------|----------|--------|
| **barista** | Очередь заказов, смена, статус/отмена заказа (Pundit), меню (чтение), отчёты | `/manager`, `/admin`, `/prep_kitchen`, чужие точки | barista |
| **shift_manager** | Dashboard, заказы, оплаты/возвраты/фискал, открытие смены, отчёты, инциденты, меню (чтение) | **Персонал**, **устройства**, TV-настройки, barista, prep_kitchen, platform | manager |
| **general_manager** | Всё у shift_manager + **склад**, **персонал** (Pundit), **устройства**, TV-настройки, **цены меню** | barista, prep_kitchen, platform admin | manager |
| **franchise_manager** | Manager на точках своей org + **switcher**; устройства (privileged) | **Персонал** (UI + Pundit), platform `/admin`, чужие org | manager |
| **prep_kitchen_manager** | Очередь, рецепты, склад, движения (создать/подтвердить/отменить), стоп-лист, отчёты | barista, manager, platform | prep_kitchen |
| **prep_kitchen_worker** | Очередь, склад, движения (просмотр) | Создание/подтверждение/отмена движений | prep_kitchen |
| **ук_global_admin** | Полный `/admin` (организации, точки, мониторинг); `/manager` после `open_as_manager` | barista, prep_kitchen без отдельной роли | admin + manager |

### Pundit на критичных операциях (manager / prep)

| Зона | Контроллеры с `authorize` | Кто допущен (policy) |
|------|---------------------------|----------------------|
| Персонал | `manager/staff` | GM, УК (`privileged_manager?` + UI gate) |
| Устройства | `manager/devices` | GM, franchise, УК |
| Смены | `manager/shifts` | менеджеры точки |
| Заказы | `manager/orders`, `barista/orders` | роль + tenant |
| Меню (цены) | `manager/menu` | GM, franchise, УК |
| Финансы | `manager/finance/*` | менеджеры точки |
| Склад цеха | `prep_kitchen/movements`, `inventory` | manager/worker по policy |

**shift_manager + устройства:** блокируется `require_privileged_manager!` + `DevicePolicy` + интеграционный тест (`tenant_rls_isolation_test`).

---

## 5. Shop: гость vs клиент (ownership, не RBAC)

Витрина не использует staff-роли. Доступ к заказам и оплатам — по **владению**:

| Субъект | Как определяется | Примеры |
|---------|------------------|---------|
| **Гость** | Cookie-сессия, корзина, `pending_order`, `reconnect_token` | Создание заказа, guest checkout |
| **Клиент** | `customer_id` в сессии после OTP | История, профиль, карты, `GET orders/:id` |
| **Проверка заказа** | `customer_id` scope или `order_visible_to_session_customer?` | cancel, finalize, payments |

**IDOR в shop:** 4 P0-дыры Phase 1 закрыты; матрица IB-0-2: **0 HOLE** (9 REVIEW — осознанные компромиссы, не дыры).

Auth gate Shop API: Referer+CSRF (браузер) или `X-Shop-Api-Key` (сервер). Tenant: `X-Shop-Tenant` / param.

---

## 6. Изоляция точек

Два уровня защиты:

1. **RBAC + tenant context** — роль проверяется в контексте точки (`has_role_in_context?`); franchise/UK — session tenant + org guard.
2. **PostgreSQL RLS** — `SET LOCAL app.current_tenant_id` на каждом staff/shop запросе; строки других точек не видны на уровне БД.

**Франчайзи:** switcher не даёт выбрать точку чужой организации (контроллер + тесты).  
**УК:** в manager только с выбранной точкой; platform — глобальный доступ by design.

Устройства (kiosk/TV): lookup по токену до GUC — [оговорка §7](#7-что-сознательно-не-в-контуре).

---

## 7. Что сознательно не в контуре

| Область | Статус | Следующий шаг |
|---------|--------|---------------|
| **Kiosk / TV / ActionCable** RLS bypass при lookup device | **Phase 5b:** `Devices::TokenResolver` (centralized); full RLS refactor — backlog prod kiosk |
| **ABAC** (`shift_open`, атрибуты заказа) | Phase 5 local done | [phase_5_abac/](phase_5_abac/) · Phase 5b full enforce |
| **Blog RBAC** (`blog_editor`) | Отдельный CMS-контур | Не блокер coffee ops |
| **Platform Pundit** (tenants/orgs, **menu/catalog**) | **Phase 5b/5c:** PlatformPolicy + authorize tenants/orgs/menu | |
| **Favorites** в shop | Session-only, не в БД per customer | P3 backlog |
| **shift_manager + inventory URL** | URL доступен, не в FORBIDDEN_PATHS | [OWNER REVIEW] в STAFF_RBAC_MATRIX |
| **Global `user_roles` без tenant_id** | TECH DEBT — legacy grant | Мониторинг |

---

## 8. Статус на дату

**Контур RBAC закрыт с оговорками** (2026-08-30).

| Критерий DoD | Статус |
|--------------|--------|
| Shop IDOR: 0 HOLE | ✅ PASS |
| Staff: роль + tenant + Pundit на критичном CRUD | ✅ PASS |
| RLS/GUC предсказуемо, NEED_MIGRATION = 0 | ✅ PASS |
| Матрица = код | ✅ PASS (расхождения только в backlog §7) |

**Оговорки (не блокер «контур закрыт»):**

- Kiosk/TV/ActionCable — `row_security off` при lookup device ([RLS_TENANT_AUDIT.md](phase_3_tenant_rls/RLS_TENANT_AUDIT.md))
- Platform admin без полного Pundit rollout
- Blog editor — вне staff matrix Prog10

**Приёмка:** [IB_ACCEPTANCE_CHECKLIST.md](IB_ACCEPTANCE_CHECKLIST.md)  
**Следующая фаза:** Phase 5b (full ABAC enforce) · см. [phase_5_abac/](phase_5_abac/)

---

## 9. ABAC rules (summary)

Phase 5 добавляет атрибутный слой поверх RBAC. Ключевое правило для бариста:

> Отмена/изменение заказа — только при **открытой смене** и если заказ **в scope смены** (своя смена, витрина с opened_at, carryover preparing).

| Атрибут | Пример |
|---------|--------|
| `shift_open` | POS create — только при open CashShift |
| `in_shift` | show/cancel/update_status barista |
| `module_enabled` | FeatureFlag barista / prep_kitchen |
| `tenant.type` | prep_kitchen только на production_kitchen |

Полный каталог (**58 правил**): [ABAC_POLICIES.md](phase_5_abac/ABAC_POLICIES.md) · атрибуты: [ABAC_ATTRIBUTES.md](phase_5_abac/ABAC_ATTRIBUTES.md)

---

## Источники

- [ACTORS_AND_ACCESS.md](phase_0_baseline/ACTORS_AND_ACCESS.md)
- [SHOP_API_ACCESS_MATRIX.md](phase_0_baseline/SHOP_API_ACCESS_MATRIX.md)
- [STAFF_RBAC_MATRIX.md](phase_0_baseline/STAFF_RBAC_MATRIX.md)
- [DEVICE_TOKENS.md](phase_3_tenant_rls/DEVICE_TOKENS.md)
- Тесты: `test/integration/staff/`, `test/integration/auth/`, `test/integration/shop/api/ownership_idor_test.rb`
