# RLS / PG inventory (must-have) — TASK_93-G

**Канон воспроизведения:** R3-B — `schema.rb` + `DatabaseTriggers.ensure_all!` / `db:rls:ensure` (не `structure.sql` в блоке G).  
**Источник DDL:** `db/migrate/*` (explore 2026-09-18). Полный список ~39 RLS-таблиц — вне DoD G; здесь только **must-have**.

## Policies (ENABLE RLS + ≥1 policy)

| Table | Policy (канон имени) | Примечание |
|-------|----------------------|------------|
| `orders` | `rls_orders_isolation` | stage_1 + franchise supersede |
| `order_items` | `rls_order_items_isolation` | |
| `order_status_logs` | `rls_order_status_logs_isolation` | |
| `payments` | `rls_payments_isolation` | franchise isolation fixes |
| `product_tenant_settings` | `rls_pts_isolation` | |
| `cash_shifts` | `rls_cash_shifts_isolation` | |
| `ingredient_tenant_stocks` | `rls_stock_isolation` | |
| `stock_movements` | `rls_stock_movements_isolation` | |
| `devices` | `rls_devices_isolation` (+ `rls_devices_token_lookup`) | MVP |
| `kiosk_settings` | `rls_kiosk_settings_isolation` | MVP |
| `tenants` | *(новая)* shop city lookup | G5: `app.shop_city_lookup = 'on'` + active sales_point + same city |

**N для T-G4a:** `pg_policies` count ≥ **11** на must-have tables выше (после ensure; city policy после migrate G5).

## Triggers

| Trigger | Table | Function |
|---------|-------|----------|
| `trg_generate_order_number` | `orders` | `generate_order_number()` |
| `trg_auto_deduct_ingredients` | `orders` | `auto_deduct_ingredients_on_order_accept()` |
| `trg_auto_stop_list` | `ingredient_tenant_stocks` | `auto_stop_list_on_zero_stock()` |
| `trg_update_*_updated_at` (stage_9 set) | tenants/users/roles/orders/… | `update_updated_at_column()` |

## Functions (зависимости)

- `generate_order_number()`
- `auto_deduct_ingredients_on_order_accept()`
- `auto_stop_list_on_zero_stock()`
- `update_updated_at_column()`

## GUC allowlist (app.*)

| GUC | Назначение |
|-----|------------|
| `app.current_tenant_id` | staff / shop / save |
| `app.current_user_id` | staff |
| `app.auth_login` | login policies |
| `app.device_token_lookup` | devices |
| `app.shop_api_key_lookup` | shop API keys |
| `app.shop_city_lookup` | **G5** city peers (новое) |

## Gaps pre-GREEN

- `DatabaseTriggers` сегодня: только `ensure_order_number!` — нет `ensure_all!`
- City: нет policy/`with_shop_city_lookup`; `CustomerTenantHistory` ещё с `row_security = off`
- Staff: `set_pg_context` вне txn в barista/manager/prep
