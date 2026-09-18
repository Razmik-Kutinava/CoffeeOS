# todo — #93 TASK_93-G: Tenant GUC / RLS / schema

**Канон блока G** (session `todo.md` / `GATES.md` гоняют параллельные блоки — смотри сюда).

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-G** |
| **Тип** | SBR · hot-path RLS / staff GUC |
| **Статус** | **REVIEW** · CI · Next: deploy апрув |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата G1–G6 · зонтик [`TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта G |
| **GATES** | [`GATES-block-G.md`](GATES-block-G.md) |
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
- [x] PHASE 1 `/spec` — этот файл + `RLS_PG_INVENTORY.md`
- [x] PHASE 2 RED — T-G1a/c · T-G5b · gaps · `[RED]`
- [x] PHASE 2 GREEN — R1–R6 · `[GREEN]`
- [x] `/regress` — G4
- [x] PHASE 3 `/review` — G1–G6 PASS · push · без deploy

## Файлы (ожидаемо)

- `app/controllers/concerns/with_tenant_pg_context.rb` — around_action txn + SET LOCAL
- `app/controllers/barista/base_controller.rb` — concern (manager/prep — blast)
- `lib/database_triggers.rb` — `ensure_all!` policies+triggers из инвентаря
- `app/services/rls/guc_context.rb` — `with_shop_city_lookup`
- `app/services/shop/customer_tenant_history.rb` — без `row_security = off`
- `app/models/application_record.rb` — ensure_tenant R6
- `db/migrate/*_add_rls_tenants_shop_city_lookup_policy.rb` — policy на `tenants`

### Blast-radius

- `manager/base_controller.rb` / `prep_kitchen/base_controller.rb`
- `shop/api/base_controller.rb` — эталон, не ломать
- `test/support/rls_test_bootstrap.rb`

## Матрица (must PASS)

T-G1a/b/c · T-G2a/b/c · T-G3a/b · T-G4a/b · T-G5a/b/c/d · T-G6a/b  
Без **T-G1a + T-G3a + T-G5b** блок не закрыт.

## Не ломать

1. Shop API `with_shop_tenant!` txn + GUC
2. RLS isolation (tenant A ≠ B)
3. Platform onboarding без tenant GUC
4. `Rls::GucContext` device / shop_api_key / auth_login
5. Order number после schema:load
6. City switcher UX (peers same city)

## Проверка

```bash
bin/rails test \
  test/integration/staff_pg_context_transaction_test.rb \
  test/integration/rls_tenant_isolation_test.rb \
  test/integration/db_triggers_test.rb \
  test/services/shop/customer_tenant_history_test.rb

bin/rails test test/integration/rls_tenant_isolation_test.rb \
  test/integration/db_triggers_test.rb \
  test/services/shop/customer_tenant_history_test.rb
```
