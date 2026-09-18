# todo — #93 TASK_93-G: Tenant GUC / RLS / schema

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-G** |
| **Тип** | SBR · hot-path RLS / staff GUC |
| **Статус** | **SPEC** · Next: `/sbr` RED |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата G1–G6 · зонтик [`TASK-93-Critical-path-hardening.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта G |
| **GATES** | [`GATES-block-G.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-G.md) (канон блока; `session/GATES.md` может быть чужим блоком) |
| **Инвентарь** | [`docs/operations/dev/RLS_PG_INVENTORY.md`](../dev/RLS_PG_INVENTORY.md) |
| **Зеркало** | [`todo-block-G.md`](../milestones/veha_2/artifacts/critical_path_hardening/todo-block-G.md) — канон при race session todo |
| **Цель** | Staff `SET LOCAL` внутри txn; must-have policies/triggers после load; city switcher без `row_security = off`; `ensure_tenant_id` строго |
| **OUT** | A–F / H–K продуктовые · полный аудит 39 таблиц сверх must-have · `schema_format = :sql` (R3-A отложен) · deploy (L) |
| **Зависимость** | A soft-fail deduction — **не** откатывать; триггер `trg_auto_deduct` всё равно must exist (G3/G4) |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1** | Любой request-scoped `SET LOCAL app.current_tenant_id` / `app.current_user_id` — **только** внутри `ActiveRecord::Base.transaction` (или `connection.transaction`) |
| **R2** | Staff = Shop API: `around_action` → Current → `transaction { SET LOCAL; yield }` → ensure reset Current. Concern `WithTenantPgContext` → barista / manager / prep |
| **R3** | **B (зафиксировано):** ruby `schema.rb` + обязательный post-load `DatabaseTriggers.ensure_all!` (+ policies из инвентаря) через initializer / `db:ensure_triggers` / `db:rls:ensure`. **Не** переключать `schema_format = :sql` в этом блоке (R3-A = backlog после L) |
| **R4** | Must-have = [`RLS_PG_INVENTORY.md`](../dev/RLS_PG_INVENTORY.md); T-G2/G4 падают, если объекта нет |
| **R5** | City: GUC **`app.shop_city_lookup`** (`'on'`) + `Rls::GucContext.with_shop_city_lookup` + узкая policy на `tenants` (active `sales_point` + same city). **Запрет** `row_security = off` в `CustomerTenantHistory` |
| **R6** | `ensure_tenant_id`: **raise** если `tenant_id` blank во **всех** env, **кроме** `Rails.env.test?` (там allow + warn для фикстур без Current). Dev = raise (production-like). Запрет: production-like без raise |

## SBR

- [x] PHASE 0 `/start` — бриф TASK_93-G в чате
- [x] `/unlazy` — GATES G `576d37bf` (G1–G4 unmet · G5→L)
- [x] PHASE 1 `/spec` — этот todo (+ зеркало `todo-block-G.md` · inventory)
- [ ] PHASE 2 RED — T-G1a/c · T-G5b · T-G2/G3 gaps · коммит `[RED]`
- [ ] PHASE 2 GREEN — R1–R6 · коммит `[GREEN]` · все T-G* PASS
- [ ] `/regress` — GATES G4 §8
- [ ] PHASE 3 `/review` — таблица G1–G6 PASS · push · **без deploy**

## Файлы (ожидаемо)

- `app/controllers/concerns/with_tenant_pg_context.rb` — новый `around_action` txn + SET LOCAL (как Shop)
- `app/controllers/barista/base_controller.rb` — заменить голый `before_action` set_pg на concern (manager/prep — blast)
- `lib/database_triggers.rb` — `ensure_all!`: order_number + auto_deduct + stop_list (+ updated_at must-have) + policies SQL из инвентаря
- `app/services/rls/guc_context.rb` — `with_shop_city_lookup` (`app.shop_city_lookup`)
- `app/services/shop/customer_tenant_history.rb` — убрать `row_security = off` → city GUC
- `app/models/application_record.rb` — `ensure_tenant_id` по R6
- `db/migrate/*_add_rls_tenants_shop_city_lookup_policy.rb` — узкая policy на `tenants`

### Blast-radius (+соседи)

- `app/controllers/manager/base_controller.rb` / `prep_kitchen/base_controller.rb` — тот же concern
- `app/controllers/shop/api/base_controller.rb` — эталон; **не** ломать txn GUC
- `test/support/rls_test_bootstrap.rb` — `ensure_all_inventory!` / расширить под T-G4
- `docs/operations/dev/RLS_PG_INVENTORY.md` — канон must-have (уже SPEC)

## Матрица приёмки (RED → GREEN)

| ID | Тест | Файл |
|----|------|------|
| T-G1a | barista: SET LOCAL при `transaction_open?`; GUC = tenant | `staff_pg_context_transaction_test` (новый) |
| T-G1b | manager/prep same pattern | ↑ shared helper |
| T-G1c | `set_pg_context` вне txn — no-op/forbid; staff всегда wraps | unit / integration |
| T-G2a | инвентарь закоммичен | `RLS_PG_INVENTORY.md` |
| T-G2b | must-have tables: `pg_policies` count > 0 | `pg_inventory_test` или bootstrap assert |
| T-G2c | триггеры order_number / auto_deduct / stop_list в `pg_trigger` | ↑ |
| T-G3a | `ensure_all!` на БД без объектов → T-G2b/c green | `db_triggers_test` |
| T-G3b | prepare/ensure hook не «только order_number» | docs/rake + тест |
| T-G4a/b | fresh/bootstrap: policies ≥ N · triggers present | `rls_tenant_isolation` / `pg_inventory_test` |
| T-G5a | city peers same city | `customer_tenant_history_test` |
| T-G5b | source **без** `row_security = off` | grep/assert |
| T-G5c | без city GUC — не полный dump tenants | isolation |
| T-G5d | `last_ordered_tenant_id` cross-tenant same customer | регресс |
| T-G6a | production-like blank tenant_id → raise | `application_record` / ensure_tenant test |
| T-G6b | test env = allow+warn (R6); suite green | ↑ |

Без **T-G1a + T-G3a + T-G5b** блок не закрыт.

## Не ломать

1. Shop API `with_shop_tenant!` txn + GUC (эталон)
2. RLS isolation tests (tenant A ≠ B)
3. Platform onboarding без tenant GUC
4. `Rls::GucContext` device / shop_api_key / auth_login lookup
5. Order number generation после schema:load
6. City switcher UX: список точек того же города

## Проверка

```bash
# G1 — матрица G (staff GUC · inventory · city · ensure_tenant)
bin/rails test \
  test/integration/staff_pg_context_transaction_test.rb \
  test/integration/rls_tenant_isolation_test.rb \
  test/integration/db_triggers_test.rb \
  test/services/shop/customer_tenant_history_test.rb

# G2 — регресс зоны RLS / triggers (§8)
bin/rails test test/integration/rls_tenant_isolation_test.rb \
  test/integration/db_triggers_test.rb \
  test/services/shop/customer_tenant_history_test.rb
```

Информативно (REVIEW): `ruby bin/audit/tenant_guc_inventory.rb`
