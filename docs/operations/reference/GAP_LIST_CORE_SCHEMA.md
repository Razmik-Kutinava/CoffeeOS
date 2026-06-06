# GAP LIST: core -> schema

Дата: 2026-05-11  
Источник сравнения: `docs/product/core/*.md` vs `db/schema.rb`

## 1) Текущее покрытие

- Core tables total: `62`
- Present in schema: `37` (исходный baseline до батчей; актуальное число таблиц см. `db/schema.rb`)
- Missing in schema: `25` (исходный список гэпов; по таблицам из missing-table закрыто миграциями B1–B5)
- Coverage baseline: `59.7%`
- **Актуально (после B5, с rename-mapping): `62/62` (~`100%`) по табличному контуру core; остаётся осознанный drift: PL/pgSQL/триггеры из core SQL не переносились в Rails-миграции.**

### Прогресс после запуска B1 (2026-05-11)

- Созданы таблицы: `admin_audit_logs`, `feature_flags_logs` (миграция `20260511174500`).
- Тесты: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- Покрытие с учётом согласованного rename-mapping: `45/62` (≈ `72.6%`), остаётся `17`.

### Прогресс после запуска B2 (2026-05-11)

- Созданы таблицы: `billing_plans`, `billing_subscriptions`, `tenant_invitations`.
- Дополнительно: добавлена безопасная привязка `tenants.plan_id` -> `billing_plans(id)`.
- Тесты: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- Покрытие с учётом согласованного rename-mapping: `48/62` (≈ `77.4%`), остаётся `14`.

### Прогресс после запуска B3 (2026-05-11)

- Созданы таблицы: `loyalty_accounts`, `loyalty_transactions`, `promo_code_usages`, `push_notifications`, `order_feedback`.
- Тесты: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- Покрытие с учётом согласованного rename-mapping: `53/62` (≈ `85.5%`), остаётся `9`.

### Прогресс после запуска B3.5 (2026-05-11)

- Созданы таблицы: `mobile_carts`, `mobile_payment_methods`.
- Тесты: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- Покрытие с учётом согласованного rename-mapping: `55/62` (≈ `88.7%`), остаётся `7`.

### Прогресс после запуска B4 (2026-05-11)

- Созданы таблицы: `pickup_calls`, `pickup_display_settings`, `pickup_events`.
- Дополнительно (по core stage 10): в `orders` добавлены поля `ready_at`, `issued_at`, `pickup_method` + constraint/indexes.
- Тесты: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- Покрытие с учётом согласованного rename-mapping: `58/62` (≈ `93.5%`), остаётся `4`.

### Прогресс после запуска B5 (2026-05-11)

- Созданы таблицы: `production_recipes`, `production_batches`, `supply_orders`, `supply_order_items` (миграция `20260511190000`).
- Расширение `ingredients` (часть core production): `is_semifinished`, `shelf_life_hours`, `storage_temp`, `production_unit` + `chk_ingredient_storage_temp` + индексы `idx_ingredients_semifinished`, `idx_ingredients_storage_temp`.
- Не добавлялся уникальный индекс на `ingredients(name)` из core (риск при дубликатах в данных).
- Тесты: `324 runs, 1065 assertions, 0 failures, 0 errors, 0 skips`.
- Покрытие с учётом согласованного rename-mapping: `62/62` (`100%`) по таблицам из gap-контура; дальше — только B0 (доки/alias), при необходимости — SQL-функции/триггеры отдельным решением.

## 2) Классификация 25 гэпов (зафиксировано)

Легенда статусов:

- `rename-only` — таблица уже есть, различие только в имени/форме.
- `missing-table` — таблицы нет в `schema`, требуется новая миграция.
- `missing-fields` — таблица есть, но в core-контракте не хватает полей.
- `intentional-out-of-core` — сознательно вне 11-core (не используется для синхронизации ядра).

Источник правды для ядра: `core`.

- `admin_audit_log`
  - status: `missing-table`
  - progress: `done-in-b1` (реализовано как `admin_audit_logs`, canonical mapping зафиксирован)
  - batch: B1 (security/audit baseline)
- `billing_plans`
  - status: `missing-table`
  - progress: `done-in-b2`
  - batch: B2 (billing)
- `billing_subscriptions`
  - status: `missing-table`
  - progress: `done-in-b2`
  - batch: B2 (billing)
- `feature_flags_log`
  - status: `missing-table`
  - progress: `done-in-b1` (реализовано как `feature_flags_logs`, canonical mapping зафиксирован)
  - batch: B1 (security/audit baseline)
- `ingredient_tenant_stock` (в schema есть `ingredient_tenant_stocks`, требуется решение по канону имени)
  - status: `rename-only`
  - decision: не переименовывать физическую таблицу, зафиксировать canonical alias в docs и code mapping
  - batch: B0
- `loyalty_accounts`
  - status: `missing-table`
  - progress: `done-in-b3`
  - batch: B3 (loyalty)
- `loyalty_transactions`
  - status: `missing-table`
  - progress: `done-in-b3`
  - batch: B3 (loyalty)
- `mobile_carts`
  - status: `missing-table`
  - progress: `done-in-b3.5`
  - batch: B3.5 (mobile)
- `mobile_payment_methods`
  - status: `missing-table`
  - progress: `done-in-b3.5`
  - batch: B3.5 (mobile)
- `order_feedback`
  - status: `missing-table`
  - progress: `done-in-b3`
  - batch: B3 (loyalty/mobile retention)
- `order_status_log` (в schema `order_status_logs`)
  - status: `rename-only`
  - decision: оставить `order_status_logs`, выровнять название в core map
  - batch: B0
- `payment_status_log` (в schema `payment_status_logs`)
  - status: `rename-only`
  - decision: оставить `payment_status_logs`, выровнять название в core map
  - batch: B0
- `pickup_calls`
  - status: `missing-table`
  - progress: `done-in-b4`
  - batch: B4 (pickup)
- `pickup_display_settings`
  - status: `missing-table`
  - progress: `done-in-b4`
  - batch: B4 (pickup)
- `pickup_events`
  - status: `missing-table`
  - progress: `done-in-b4`
  - batch: B4 (pickup)
- `product_menu_visibility` (в schema `product_menu_visibilities`)
  - status: `rename-only`
  - decision: оставить `product_menu_visibilities`, выровнять название в core map
  - batch: B0
- `product_price_history` (в schema `product_price_histories`)
  - status: `rename-only`
  - decision: оставить `product_price_histories`, выровнять название в core map
  - batch: B0
- `production_batches`
  - status: `missing-table`
  - progress: `done-in-b5`
  - batch: B5 (production)
- `production_recipes`
  - status: `missing-table`
  - progress: `done-in-b5`
  - batch: B5 (production)
- `promo_code_usages`
  - status: `missing-table`
  - progress: `done-in-b3`
  - batch: B3 (loyalty/promo)
- `push_notifications`
  - status: `missing-table`
  - progress: `done-in-b3`
  - batch: B3 (loyalty/push)
- `shift_staff` (в schema `shift_staffs`)
  - status: `rename-only`
  - decision: оставить `shift_staffs`, выровнять название в core map
  - batch: B0
- `supply_order_items`
  - status: `missing-table`
  - progress: `done-in-b5`
  - batch: B5 (production/supply)
- `supply_orders`
  - status: `missing-table`
  - progress: `done-in-b5`
  - batch: B5 (production/supply)
- `tenant_invitations`
  - status: `missing-table`
  - progress: `done-in-b2`
  - batch: B2 (billing/admin onboarding)

## 3) Есть в schema, но не входят в core-контур

- `blog_categories`
- `blog_posts`
- `organizations`
- `solid_cache_entries`

## 4) Нейминг-расхождения (не всегда баг, но риск drift)

- singular/plural: `*_log` <-> `*_logs`, `*_visibility` <-> `*_visibilities`, `*_history` <-> `*_histories`
- единичные/множественные формы в складских и сменных таблицах

## 5) Контроль ошибок на этапе gap-list (обязательно)

- Фиксировать каждый гэп в один из статусов: `rename-only` / `missing-table` / `missing-fields` / `intentional-out-of-core`.
- Для каждого пункта указывать источник правды: `core` или `schema` (один канон, без «и так и так»).
- Перед миграцией проверять:
  - таблица/поле уже не создано под другим именем;
  - нет дублирующих индексов/констрейнтов;
  - FK и enum совместимы с текущими данными;
  - миграция обратима.
- После каждого батча:
  - `bin/rails db:migrate`
  - `bin/rails test` (или целевые тесты модуля)
  - smoke критичных API (`orders`, `payments`, `shop categories/products`).
- Любой инцидент сразу писать в `docs/operations/ISSUES.md` до фикса.

## 6) План Шага 2 (после апрува)

1. **B0 (rename-only mapping):** зафиксировать canonical mapping в docs + model/table_name при необходимости, без физического `ALTER TABLE RENAME`.
2. **B1 (audit/security):** `admin_audit_log`, `feature_flags_log`.
3. **B2 (billing/admin):** `billing_plans`, `billing_subscriptions`, `tenant_invitations`.
4. **B3 (loyalty/promo/push):** `loyalty_*`, `promo_code_usages`, `push_notifications`, `order_feedback`.
5. **B3.5 (mobile addon):** `mobile_carts`, `mobile_payment_methods`.
6. **B4 (pickup):** `pickup_*`.
7. **B5 (production/supply):** `production_*`, `supply_*`.
8. Каждый батч: `db:migrate` -> целевые тесты -> smoke (`orders/payments/shop`) -> запись в operations.

## 7) Чек-лист анти-ошибок перед каждым батчем

- Снять baseline: `bin/rails db:migrate:status`, `bin/rails test` (или модульный таргет).
- Проверить collisions: имя таблицы, имя индекса, имя FK/constraint.
- Для существующих данных: добавить миграции в 2 шага (nullable -> backfill -> not null), где нужно.
- Все risky-изменения через reversible migration (`up/down`), без destructive drop в одном шаге.
- После батча фиксировать:
  - что добавлено/изменено;
  - какие тесты запущены и результат;
  - что осталось в backlog.
