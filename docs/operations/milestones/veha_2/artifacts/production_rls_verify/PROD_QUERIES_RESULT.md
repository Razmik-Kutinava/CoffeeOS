# TASK_119 этап 1 — результаты запросов к production (раздел 5 ТЗ)

**Статус:** выполнено 2026-10-28 ~08:30 UTC, разрешение владельца в чате («да разрешаю»).  
**Сырой вывод:** [`prod_queries_raw_2026-10-28.txt`](prod_queries_raw_2026-10-28.txt) — без хостов, URL, паролей и ключей.

## Как выполнялось

1. `fly ssh console -a coffeeos` (машина `ams`). `psql` в образе нет → запросы через `bin/rails runner`: то же соединение `ActiveRecord::Base.connection`, та же роль из `DATABASE_URL`, что у приложения (требование ТЗ к запросу 1).
2. Первой командой в сессии: `SET default_transaction_read_only = on`; проверка `SHOW default_transaction_read_only` → `on`. Запись в сессии невозможна.
3. Четыре запроса раздела 5 ТЗ дословно (без завершающих `;`). Ничего, кроме них, не выполнялось. Временный файл скрипта на машине удалён.
4. В выводе консоль Windows показала `ук_global_admin` как `╤Г╨║_global_admin` (UTF-8, прочитанный как CP866) — в сыром файле исправлено обратно; в базе значение нормальное.

## Subtask 1 — роль приложения

| rolname | rolsuper | rolbypassrls |
|---|---|---|
| `neondb_owner` | false | **true** |

- Владелец **всех 98** таблиц схемы `public` — `neondb_owner` (та же роль).
- **Итог: RLS к роли приложения не применяется ни на одной таблице** — по двум независимым причинам: атрибут `BYPASSRLS` и владение таблицами без `FORCE`. Предположение раздела 2 ТЗ («скорее всего, владелец таблиц или обходит RLS») подтверждено: верно и то, и другое.

## Subtask 2 — RLS и политики в production против миграций

### RLS включён (`relrowsecurity = true`) — только на 8 таблицах

`order_notification_logs`, `point_campaign_settings`, `prep_kitchen_sales_point_links`, `shop_api_keys`, `shop_customer_favorites`, `subscription_offer_settings`, `tenant_weekday_schedules`, `tenants`.

`relforcerowsecurity` = false **везде**.

Все 8 — таблицы из миграций 2026-06 и позже (`20260619…`, `20260804…`, `20260831…`, `20260904…`, `20260909…`, `20260918123000`).

### RLS выключен, хотя миграции его включают

Миграции stage 0–8 (`20250115000000`…`20250115000008`) делают `ENABLE ROW LEVEL SECURITY` на: `users`, `user_roles`, `sessions`, `feature_flags`, `orders`, `order_items`, `order_status_logs`, `payments`, `payment_status_logs`, `payment_polling_attempts`, `refunds`, `fiscal_receipts`, `cash_shifts`, `product_tenant_settings`, `modifier_option_tenant_settings`, `product_price_histories`, `devices`, `device_sessions`, `tv_board_settings`, `ingredient_tenant_stocks`, `stock_movements`, `stock_movement_items`, `kiosk_settings`, `kiosk_sessions`, `kiosk_carts`, `shifts`, `shift_staffs`, `shift_cash_operations`. В production на **всех** этих таблицах RLS выключен.

### Политики (16 шт.)

| Таблица | Политика | Команда | RLS на таблице | Значит |
|---|---|---|---|---|
| `tenants` | `rls_tenants_shop_city_lookup` | SELECT | вкл | единственная политика; для роли приложения не действует (bypass) |
| `orders` | `rls_orders_shop_city_lookup` | SELECT | **выкл** | политика есть, но не действует даже теоретически |
| `payments` | `rls_payments_isolation` | ALL | **выкл** | не действует; форма — из `20260424000002` (`current_setting` без `missing_ok` → при включении RLS запрос без GUC упадёт ошибкой, а не вернёт пусто) |
| `product_tenant_settings` | `rls_pts_isolation` | ALL | **выкл** | не действует |
| `ingredient_tenant_stocks` | `rls_stock_isolation` | ALL | **выкл** | не действует |
| `devices` | `rls_devices_token_lookup` | SELECT | **выкл** | не действует |
| `users` | `rls_users_auth_login` | SELECT | **выкл** | не действует |
| `user_roles` | `rls_user_roles_auth_login` | SELECT | **выкл** | не действует |
| `order_notification_logs` | `rls_order_notification_logs_isolation` | ALL | вкл | bypass |
| `point_campaign_settings` | `rls_point_campaign_settings_isolation` | ALL | вкл | bypass |
| `prep_kitchen_sales_point_links` | `rls_prep_kitchen_sales_point_links` | ALL | вкл | bypass |
| `shop_api_keys` | `rls_shop_api_keys_isolation`, `rls_shop_api_keys_lookup` | ALL | вкл | bypass |
| `shop_customer_favorites` | `rls_shop_customer_favorites_isolation` | ALL | вкл | bypass |
| `subscription_offer_settings` | `rls_subscription_offer_settings_isolation` | ALL | вкл | bypass |
| `tenant_weekday_schedules` | `rls_tenant_weekday_schedules_isolation` | ALL | вкл | bypass |

### Политик нет, хотя миграции их создают

- Все политики изоляции по точке из stage 0–8 (`sessions`, `order_status_logs`, `payment_status_logs`, `payment_polling_attempts`, `refunds`, `fiscal_receipts`, `cash_shifts`, `devices` isolation, `device_sessions`, `tv_board_settings`, `kiosk_*`, `stock_movements`, `stock_movement_items`, `shifts`, `shift_staffs`, `shift_cash_operations`, `modifier_option_tenant_settings`, `product_price_histories`).
- Из `20260320120001_rls_franchise_organization_scope.rb`: `rls_users_isolation`, `rls_user_roles_isolation`, `rls_orders_isolation`, `rls_order_items_isolation` (есть только `rls_payments_isolation` — его пересоздал `20260424000002`).
- Из `20260320120002_rls_feature_flags_uk_global_admin.rb`: `rls_feature_flags_isolation`.

### Состояние миграций (запрос 4)

20 последних версий в production: от `20261005140000` до `20260827180200` — совпадают с 20 последними файлами `db/migrate` один в один. Неприменённых миграций среди последних 20 нет.

**Почему DDL ранних миграций нет при записанных версиях** — запросами раздела 5 не доказать (полный список `schema_migrations` и история базы в набор не входят). Гипотеза: база production создавалась из `schema.rb` (там нет DDL RLS — как и в тестовой базе, факт ТЗ раздел 2), а политики появились только от миграций, выполненных после этого.

## Выводы для заказчика

1. **RLS в production сейчас не защищает ничего** для роли приложения: роль `neondb_owner` имеет `BYPASSRLS` и владеет всеми таблицами; на заказах, платежах, пользователях и сессиях RLS вообще выключен.
2. **Изоляция точек и клиентов держится только на коде**: фильтр `orders.tenant_id`, `OrderOwnership`, ячейка сессии `CustomerSession`. Политика `shop_city_lookup` в production ни расширяет, ни сужает доступ (не действует).
3. **Перечень мест, рассчитанных на обход** ([`CODE_BYPASS_INVENTORY.md`](CODE_BYPASS_INVENTORY.md)) в production сейчас не ломается — именно потому, что RLS не применяется. Он обязателен, если когда-нибудь включать RLS (отдельная роль без `BYPASSRLS`/владения или `FORCE`).
4. **Subtask 8 (неактивные точки):** под текущей ролью видны все заказы и все точки, включая неактивные. Под политиками (если их включить) неактивные точки в `tenants` скрыты, заказы — нет.
5. **Условие этапа 2 в очереди** (шаг 13a: «только если этап 1 показал, что RLS действует») — **не выполнено**: RLS не действует. Делать ли что-то с RLS (включать, приводить к миграциям, оставить как есть и защищать кодом) — решение заказчика.
