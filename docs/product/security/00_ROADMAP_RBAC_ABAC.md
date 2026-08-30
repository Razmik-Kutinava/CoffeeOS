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

## Phase 4 — DoD «RBAC контур закрыт» ✅

**Статус:** done 2026-08-30 · [phase_4_rbac_dod/](phase_4_rbac_dod/) · [ROLES_AND_PERMISSIONS.md](ROLES_AND_PERMISSIONS.md)

**Критерии готовности базового контура:**

- [x] Shop API: 0 HOLE в матрице IB-0-2
- [x] Staff: роли покрыты integration-тестами; Prog10 Fly SKIP (shop config), last PASS 2026-06-02
- [x] `has_role_in_context?` tenant-aware (Phase 2)
- [x] Manager/prep: Pundit на критичном CRUD; platform — backlog
- [x] RLS: audit complete; kiosk/TV/cable — documented backlog
- [ ] Fly MCP Point A — post-deploy, не блокер Phase 4

---

## Phase 5 — ABAC-lite ✅ (local)

**Статус:** local done 2026-08-30 · [phase_5_abac/](phase_5_abac/)

**Цель:** тонкий атрибутный слой поверх закрытого RBAC.

| Deliverable | Статус |
|-------------|--------|
| ABAC_ATTRIBUTES.md + ABAC_POLICIES.md (58 rules) | ✅ |
| PolicyContext + pundit_user (3 panels) | ✅ |
| Order/CashShift/StockMovement ABAC enforce | ✅ |
| ABAC tests ≥15 | ✅ |

**Phase 5b:** kiosk/TV, full enforce Partial rules, platform ABAC.

Атрибуты:

| Attribute | Пример правила |
|-----------|----------------|
| `shift_open` | barista: create order только при открытой смене |
| `order.status` | cancel: только `accepted`/`preparing` для guest |
| `organization_id` | franchise: tenants только своей org |
| `module_enabled` | FeatureFlag `barista` / `prep_kitchen` |
| `user.active` | блокировка на каждом запросе (уже частично) |
| `tenant.type` | beta vs prod capabilities |

Реализация — [phase_5_abac/](phase_5_abac/) · Phase 5b — full enforce.
