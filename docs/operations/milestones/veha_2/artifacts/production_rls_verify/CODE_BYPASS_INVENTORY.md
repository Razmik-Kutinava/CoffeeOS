# TASK_119 этап 1 — места кода, рассчитанные на обход RLS (Subtask 10)

**Дата:** 2026-10-28 · **Шаг:** 0.4 [очереди Push + SMS](../../requirements/PUSH_SMS_QUEUE.md) · **ТЗ:** [TASK-119-…](../../requirements/customer_tasks/TASK-119-Проверка-безопасности-межточечной-истории-CODE-BLACK-в-production.md)  
**Метод:** только чтение кода и миграций (`db/migrate`, `app/`, `lib/`, `test/support`). Состояние production этим документом **не** доказывается — для этого запросы раздела 5 ТЗ ([`PROD_QUERIES_RESULT.md`](PROD_QUERIES_RESULT.md)).

## Вывод

- **FORCE ROW LEVEL SECURITY нет ни в одной миграции.** Есть только в тестах: `test/support/rls_test_bootstrap.rb:70`, `test/services/rls/device_token_lookup_test.rb:58-59`. Если роль приложения в production — владелец таблиц, политики к ней сейчас не применяются (Subtask 1 подтвердит или опровергнет).
- **`tenants`**: RLS включён (`20260918123000:6`), единственная политика — `rls_tenants_shop_city_lookup` (SELECT при `app.shop_city_lookup='on'`, только `active` + `sales_point`). Политики по `app.current_tenant_id` на `tenants` **нет** → при применении RLS к роли почти любой `Tenant.*` вернёт пусто.
- **`db:rls:ensure`** упоминается в ТЗ (раздел 3) и в `docs/operations/dev/RLS_PG_INVENTORY.md`, но такой rake-задачи в коде **нет**. Есть `db:ensure_triggers` (`lib/tasks/database_triggers.rake`, только триггеры, не RLS) и `rls:check` / `rls:test_isolation` (`lib/tasks/rls_check.rake`).
- **`set_pg_context` без открытой транзакции ничего не делает** (`application_controller.rb:51-56`, пишет warn и выходит). Где он вызывается вне транзакции, `app.current_user_id` / `app.current_tenant_id` в PostgreSQL не попадают.
- Включать применение RLS к роли приложения (FORCE или отдельная роль без владения) **нельзя**, пока каждое место из таблиц ниже не исправлено и не покрыто тестом под ролью, подчиняющейся RLS (требование Subtask 10 / 11).

## Места, названные в ТЗ (сверка фактов раздела 2)

| Место ТЗ | Сверка с кодом |
|---|---|
| `Tenant.find_by` в `shop/api/base_controller.rb:27` | совпало: `:27` до `SET app.current_tenant_id` на `:38` |
| `shop/api/base_controller.rb:38,48-58` session-level `SET`/`RESET`, ошибка сброса только логируется | совпало: `SET` `:38`, сброс `:48-58`, `rescue` → `Rails.logger.warn` `:56-57` |
| `PhoneVerifiedCustomerLinker#deactivate_empty_guest!` `:71-76` | совпало: `Order.where(customer_id: customer.id).exists?` на `:73` (без tenant) |
| `CustomerTenantHistory` `:72-83,103-105` | совпало: `with_shop_city_lookup` `:61`, `:72`, `:78`, обёртка `:103-105` |
| `Rls::GucContext.with_shop_city_lookup` `:20-21,33-41` | совпало: `ActiveRecord::Base.transaction` + `SET LOCAL` `:38-41`; во внешней транзакции это savepoint → GUC живёт до конца внешней транзакции |
| `/o/:hash` без tenant-контекста, `order_short_links_controller.rb:8` | совпало по сути: поиск заказа — `Shop::OrderReadySmsLink` `order_ready_sms_link.rb:47` `Order.find_by(id:, source: :mobile)`, контекст точки не ставится |
| Тестовая база из `schema.rb` без политик, `rls_test_bootstrap.rb:3,25-36` | совпало: комментарий `:3`, свой набор политик в bootstrap, `FORCE` `:70`; политики `shop_city_lookup` в bootstrap нет |

## Работает только при обходе RLS (сломается при применении RLS к роли)

Уверенность: **высокая** — прочитан код, запрос идёт к таблице с RLS без нужного GUC.

### Таблица `tenants`

| Файл:строка | Запрос | Почему сломается |
|---|---|---|
| `app/controllers/shop/api/base_controller.rb:27` | `Tenant.find_by(id: tid)` | до установки GUC; на `tenants` нет политики по точке → «Точка не найдена» на всём shop API |
| `app/controllers/shop/concerns/tenant_resolution.rb:27-48, 61` | `Tenant.where(status: "active")…`, `Tenant.find_by(slug:)` | выбор точки витрины до GUC (комментарий `:47` это признаёт) |
| `app/controllers/shop/pages_controller.rb:9` | `Tenant.find_by(id: tid)` | HTML витрины без GUC |
| `app/controllers/manager/base_controller.rb:89` | `Tenant.where(organization_id: …)` | до `set_tenant_context` (`:109`) → у владельца франшизы «нет точек» |
| `app/controllers/health/tenants_controller.rb:11,28,48,64` | `Tenant.where` / `Tenant.find` | без GUC и без `shop_city_lookup` |
| `app/controllers/platform/tenants_controller.rb:133` и др. в `platform/*` | `Tenant.find` / списки | УК без политики на `tenants` |
| `app/services/prep_kitchen/sales_point_registry.rb:14,41` | `Tenant.where(id: …)` / по `organization_id` | без GUC |
| `app/services/analytics/channel_order_stats_collector.rb:43` | `Tenant.where(… sales_point)` | загрузка точек — до блока `row_security = off` (`:53`), который покрывает только заказы |
| `app/services/devices/expiring_tokens_processor.rb:30` | `Tenant.where(status: "active").find_each` | пустой цикл → обслуживание токенов устройств не идёт |
| `app/controllers/kiosk/api/auth_controller.rb:18` | `device.tenant` | `tenants` без `shop_city_lookup` |
| `lib/tasks/tenant_context.rake:12,41` | `Tenant.find` | rake-операции |

### Заказы и платежи без контекста точки (или до него)

| Файл:строка | Запрос | Почему сломается |
|---|---|---|
| `app/services/shop/order_ready_sms_link.rb:47` | `Order.find_by(id:, source: :mobile)` | `/o/:hash` из SMS — без GUC → ссылка «недействительна» |
| `app/controllers/payment_returns_controller.rb:19,47,56` | `Order.find_by(id: order_id)` | возврат из Т-Банка без сессии точки |
| `app/services/shop/phone_verified_customer_linker.rb:73` | `Order.where(customer_id:).exists?` | видит заказы только текущей точки → гость с заказами в другой точке считается пустым и **деактивируется** (риск из ТЗ) |
| `app/jobs/payments/tbank_callback_job.rb:26-37` | `Payment.joins(:order).where…` | до `with_order_tenant!` (`:47`) → колбэк Т-Банка не находит платёж |
| `app/services/payments/tbank_fiscal_notification_handler.rb:84-99` | `find_payment` | до `JobTenantContext` (`:27`) |
| `app/jobs/payments/stuck_payments_check_job.rb:17-22` | `Payment.pending_or_processing.where…` | межточечная джоба без контекста |
| `app/jobs/shop/ready_push_job.rb:14`, `shop/order_ready_cascade_job.rb:20`, `barista/broadcast_order_board_job.rb:11`, `shop/apple_wallet/pass_update_job.rb:10` | `Order.find_by(id:)` | до `with_order_tenant!` → пуш / каскад «Заказ готов» / табло / Wallet не срабатывают |
| `app/controllers/callbacks/events_controller.rb:208-216` | `Payment.where(tenant_id: params[:tenant_id])…` | фильтр по колонке не ставит GUC |
| `app/services/health/tenant_checker.rb:47+` | `CashShift`, `Order`, `Payment`, `Device` по `@tenant.id` | GUC в Health не ставится |

### Вход персонала (`users`, `sessions`)

| Файл:строка | Запрос | Почему сломается |
|---|---|---|
| `app/controllers/application_controller.rb:41` | `User.find_by(id: session[:user_id])` | на каждом запросе персонала, без `auth_login` и до GUC |
| `app/services/auth/session_tracker.rb:10-17, 24` | `Session.create!` / `Session.find_by(id:)&.revoke!` | GUC не ставится; политика `sessions` требует `current_tenant_id` или `current_user_id` |

Сам логин (`auth/sessions_controller.rb:15-16,30` через `GucContext.with_auth_login`) рассчитан на работающий RLS.

### Контекст, который фактически не ставится

| Файл:строка | Проблема |
|---|---|
| `app/controllers/platform/base_controller.rb:25-29` | `set_pg_context(user_id:)` вне транзакции → пропуск → ветки политик `ук_global_admin` по `app.current_user_id` не работают |
| `app/controllers/platform/tenants_controller.rb:229-234` | `load_prep_kitchen_links` — `set_pg_context` вне транзакции (рядом `load_tv_devices` `:223-226` — в транзакции, так правильно) |
| `app/controllers/tv_boards_controller.rb:28` | `SET LOCAL app.current_tenant_id` без транзакции → PostgreSQL игнорирует → заказы на ТВ-табло пустые |
| `lib/tasks/tenant_context.rake:16-17, 45-46` | `SET LOCAL` без транзакции |
| `app/controllers/kiosk/api/auth_controller.rb:16` | `device.update_columns(last_seen_at:)` — политика `rls_devices_token_lookup` только на SELECT |

## Намеренные обходы (с обоснованием в коде)

| Механизм | Где | Комментарий в коде |
|---|---|---|
| `app.auth_login` | `rls/guc_context.rb:8-10`; логин `auth/sessions_controller.rb:15,30`; ActionCable `channels/application_cable/connection.rb:18` | есть |
| `app.device_token_lookup` | `rls/guc_context.rb:12-14`; `devices/token_resolver.rb:19` | есть |
| `app.shop_api_key_lookup` | `rls/guc_context.rb:16-18`; `shop/api_key_authenticator.rb:33,78`; `platform/tenant_onboarding/provision.rb:58`; `shop/api_keys/issue.rb:19` | есть / частично |
| `app.shop_city_lookup` | `rls/guc_context.rb:20-22`; `shop/customer_tenant_history.rb:61,72,78` | есть. Политика на `orders` (`20260918123000:23-25`) открывает **все заказы всех точек** без условия по клиенту — узкой проверки владельца нет (Subtask 6) |
| `SET LOCAL row_security = off` | `analytics/channel_order_stats_collector.rb:53`; `platform/prod_data_cleanup.rb:38`; `platform/prod_single_point_cleanup.rb:128`; `platform/prod_single_point_reset.rb:33`; `platform/prod_purge.rb:5` | есть (аналитика — `:9,46-47`; остальное — ops-скрипты) |

## Session-level GUC (риск для пула соединений, Subtask 5)

| Файл:строка | Поведение | Риск |
|---|---|---|
| `app/controllers/shop/api/base_controller.rb:37-38, 48-58` | `SET` на сессию, в `ensure` — возврат прежнего значения или `RESET` | ошибка сброса только логируется → соединение вернётся в пул с GUC чужой точки |
| `app/services/rls/job_tenant_context.rb:40-47, 54-57` | вне транзакции — `SET` на сессию, в `ensure` — `RESET` | `rescue` глотает ошибку сброса → тот же риск |

## Что дальше (этап 1)

1. Запросы раздела 5 ТЗ на production read-only → [`PROD_QUERIES_RESULT.md`](PROD_QUERIES_RESULT.md).
2. Если `rolsuper` или `rolbypassrls` = true, или роль = владелец таблиц без FORCE — политики в production не действуют, изоляция держится только на фильтрах кода (`orders.tenant_id`, `OrderOwnership`). Тогда этап 2 (шаг 13a) по решению заказчика.
3. Если RLS к роли применяется — каждое место из таблиц выше уже сейчас ломается в production; сверить с логами / Sentry.
