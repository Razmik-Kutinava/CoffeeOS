# todo — #93 TASK_93-G: Tenant GUC / RLS / schema

Зеркало session `todo.md` (параллельные блоки не затирают канон G).

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-G** |
| **Тип** | SBR · hot-path RLS / staff GUC |
| **Статус** | **SPEC** · Next: `/sbr` RED |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата G1–G6 · зонтик [`TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта G |
| **GATES** | [`session/GATES.md`](../../../session/GATES.md) · [`GATES-block-G.md`](GATES-block-G.md) |
| **Инвентарь** | [`docs/operations/dev/RLS_PG_INVENTORY.md`](../../../../dev/RLS_PG_INVENTORY.md) |
| **Цель** | Staff `SET LOCAL` внутри txn; must-have policies/triggers после load; city switcher без `row_security = off`; `ensure_tenant_id` строго |
| **OUT** | A–F / H–K · полный аудит 39 таблиц сверх must-have · R3-A `structure.sql` · deploy (L) |
| **Зависимость** | A soft-fail — не откатывать; `trg_auto_deduct` must exist |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1** | Request-scoped `SET LOCAL` tenant/user — только внутри AR transaction |
| **R2** | Concern `WithTenantPgContext` → barista / manager / prep (как Shop `around_action`) |
| **R3** | **B:** `schema.rb` + `DatabaseTriggers.ensure_all!` / `db:rls:ensure` (не `:sql` в G) |
| **R4** | Must-have = `RLS_PG_INVENTORY.md` |
| **R5** | GUC `app.shop_city_lookup` + policy на `tenants`; запрет `row_security = off` |
| **R6** | `ensure_tenant_id` raise везде кроме `test?` (allow+warn) |

## SBR

- [x] PHASE 0 `/start`
- [x] `/unlazy` — GATES G `576d37bf`
- [x] PHASE 1 `/spec` — зеркало session `todo.md`
- [ ] PHASE 2 RED — T-G1a/c · T-G5b · gaps · `[RED]`
- [ ] PHASE 2 GREEN — R1–R6 · `[GREEN]`
- [ ] `/regress` — G4
- [ ] PHASE 3 `/review` — G1–G6 PASS · push · без deploy

## Файлы (ожидаемо)

- `app/controllers/concerns/with_tenant_pg_context.rb`
- `app/controllers/barista/base_controller.rb` (+ manager/prep blast)
- `lib/database_triggers.rb`
- `app/services/rls/guc_context.rb`
- `app/services/shop/customer_tenant_history.rb`
- `app/models/application_record.rb`
- `db/migrate/*_add_rls_tenants_shop_city_lookup_policy.rb`

## Не ломать / Проверка

См. session `todo.md` (Shop API · RLS A≠B · lookups · order_number · city UX).
