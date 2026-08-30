# CoffeeOS — Roadmap RBAC → ABAC

Краткая дорожная карта согласованного с владельцем контура ИБ.

## Phase 0 — Baseline docs (текущая)

**Цель:** зафиксировать «как есть» без изменений `app/`.

| Deliverable | Описание |
|-------------|----------|
| IB-0-1 | Карта актёров и трёх моделей доступа |
| IB-0-2 | Полная матрица Shop API + HOLE/REVIEW backlog |
| IB-0-3 | Staff RBAC matrix + сверка Prog10 vs code |

**Выход:** апрув владельца → Phase 1.

---

## Phase 1 — Shop ownership + IDOR fixes

**Цель:** закрыть дыры ownership в `/shop/api/*`.

- Единый guard `order_visible_to_session_customer?` (или эквивалент) на payment endpoints
- `payments/status`, `widget_init`, `sbp/init`, `sbp/charge` — обязательная проверка владельца заказа
- Регрессия: `test/integration/shop/` + Fly MCP Point A

**Не в scope:** staff Pundit, ABAC.

---

## Phase 2 — Staff Pundit + role×tenant

**Цель:** закрыть грубый RBAC staff в коде.

- Убрать blanket `skip_authorization` на manager/prep_kitchen/platform base (поэтапно)
- `authorize` на критичных экранах manager (devices, inventory, shifts close, …)
- `User#has_role?` — учёт `tenant_id` на `user_roles` (или явный scope)
- Интеграционные тесты RBAC расширить под матрицу IB-0-3

---

## Phase 3 — RLS audit + device tokens

**Цель:** аудит RLS и device-bound access.

- Инвентаризация `row_security = off` (kiosk lookup, TV, cable)
- Ротация / TTL `device_token`, audit `last_seen_at`
- Health API (`/health/*`) — политика доступа
- Background jobs: единый паттерн `SET LOCAL app.current_tenant_id`

---

## Phase 4 — DoD «RBAC контур закрыт»

**Критерии готовности базового контура:**

- [ ] Shop API: 0 HOLE в матрице IB-0-2 (или явные исключения с апрувом)
- [ ] Staff: все роли из IB-0-3 покрыты тестами + Prog10 PASS
- [ ] `has_role?` tenant-aware
- [ ] Manager/Platform: Pundit на привилегированных действиях
- [ ] RLS: нет незадокументированных bypass
- [ ] Fly MCP Point A + staff smoke на стенде

---

## Phase 5 — ABAC-lite

**Цель:** тонкий атрибутный слой поверх закрытого RBAC.

Атрибуты (placeholder в STAFF_RBAC_MATRIX):

| Attribute | Пример правила |
|-----------|----------------|
| `shift_open` | barista: create order только при открытой смене |
| `order.status` | cancel: только `accepted`/`preparing` для guest |
| `organization_id` | franchise: tenants только своей org |
| `module_enabled` | FeatureFlag `barista` / `prep_kitchen` |
| `user.active` | блокировка на каждом запросе (уже частично) |
| `tenant.type` | beta vs prod capabilities |

Реализация — отдельные SBR после Phase 4.
