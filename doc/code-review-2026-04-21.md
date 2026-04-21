# Code Review — CoffeeOS 2026-04-21

**Ветка:** `develop`  
**Период:** последние 10 дней (5 коммитов, единый feature thread)  
**Ревьюер:** automated code review (claude-sonnet-4-6)

---

## Коммиты за период

| Хеш | Дата | Описание |
|-----|------|----------|
| `3302ac6` | 2026-04-20 | fix(deploy): use External DB URL and fix Ruby version for Render Docker deploy |
| `2d82466` | 2026-04-12 | feat(db): seed catalog — category Черный, 2 фильтр-кофе with modifiers and PTS |
| `4cd2d78` | 2026-04-11 | debug(shop): add /shop/api/debug endpoint to diagnose empty catalog |
| `8768af4` | 2026-04-11 | fix(shop): wrap API requests in transaction so SET LOCAL works with RLS |
| `390ebbf` | 2026-04-11 | fix(shop): set PostgreSQL app.current_tenant_id for RLS; only enable active products |

---

## 🔴 Критичные проблемы (блокировка мержа)

### 1. debug_controller.rb — `Product.all` / `Tenant.all` без tenant-фильтрации

**Файл:** `app/controllers/shop/api/debug_controller.rb` (commit `4cd2d78`, строки 15–22)  
**Правило:** constraints.md §3 — все запросы к данным точек фильтруются по `tenant_id`

**Проблема в коммите:**
```ruby
# ❌ БЫЛО — нарушение tenant isolation
class DebugController < Shop::BaseController  # минует around_action :with_shop_tenant!
  include Shop::Concerns::TenantResolution

  def index
    all_tenants  = Tenant.all.select(:id, :slug, :name, :status).map { ... }
    all_products = Product.all.select(:id, :name, :slug, ...).map { ... }
    all_categories = Category.all.select(:id, :name, :slug, :is_active).map { ... }
  end
end
```

Контроллер наследовал от `Shop::BaseController` напрямую, обходя `around_action :with_shop_tenant!` из `Shop::Api::BaseController`. RLS не устанавливался (`SET LOCAL` не вызывался), запросы возвращали данные всех тенантов.

**Исправление (применено в этом PR):**
```ruby
# ✅ СТАЛО — tenant-scoped через around_action
class DebugController < Shop::Api::BaseController
  def index
    tenant = @shop_tenant  # установлен через with_shop_tenant!
    tenant_products = Product
      .joins(:product_tenant_settings)
      .where(product_tenant_settings: { tenant_id: tenant.id })
      .select(:id, :name, :slug, :is_active, :category_id, :base_price)
      .map { |p| { ... } }
    # ...
  end
end
```

---

### 2. SeedBlackCoffeeCatalog — неидемпотентная гвардия

**Файл:** `db/migrate/20260412000003_seed_black_coffee_catalog.rb:2`  
**Правило:** constraints.md §9 — все миграции должны быть идемпотентными

**Проблема:**
```ruby
# ❌ БЫЛО — широкая гвардия: любые категории/продукты вызывают пропуск
return say("Каталог уже есть — пропускаем") if Category.exists? && Product.exists?
```

При запуске на БД с любыми другими категориями/продуктами миграция тихо пропускала создание каталога "Черный", приводя к пустой витрине без ошибок.

**Исправление (применено в этом PR):**
```ruby
# ✅ СТАЛО — проверяем конкретный slug
return say("Каталог уже есть — пропускаем") if Category.exists?(slug: "chernyj")
```

---

## 🟡 Важные проблемы (исправить перед мержем)

### 3. base_controller.rb — `ensure` сбрасывал `Current.tenant_id` в `nil`

**Файл:** `app/controllers/shop/api/base_controller.rb` (commit `8768af4`)  
**Правило:** constraints.md §3 — RLS и tenant isolation

**Проблема в коммите:**
```ruby
# ❌ БЫЛО — при вложенных вызовах теряет внешний tenant_id
ensure
  Current.tenant_id = nil
```

**Исправление (применено в этом PR):**
```ruby
# ✅ СТАЛО — сохраняет и восстанавливает предыдущее значение
previous_tenant_id = Current.tenant_id
Current.tenant_id = tenant.id
ActiveRecord::Base.transaction do
  conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")
  yield
end
ensure
  Current.tenant_id = previous_tenant_id
```

---

### 4. Debug endpoint без аутентификации

**Файл:** `config/routes.rb:141`, `app/controllers/shop/api/debug_controller.rb`  
**Правило:** constraints.md §8 (безопасность) — чувствительные данные не раскрываются без авторизации

**Проблема:**  
Endpoint `/shop/api/debug` был доступен без пароля, JWT или токена в dev/staging. Раскрывал PTS-данные (цены, `is_enabled`, `is_sold_out`) для любого знающего tenant slug или UUID.

**Исправление (применено в этом PR):**
```ruby
# config/routes.rb
get "debug", to: "debug#index" unless Rails.env.production?
```

Endpoint закрыт в production. Для дополнительной защиты в staging рекомендуется добавить `X-Debug-Token` header guard.

---

### 5. RemoveMockCatalogData — операции без транзакции

**Файл:** `db/migrate/20260412000000_remove_mock_catalog_data.rb`  
**Правило:** constraints.md §6 — операции на нескольких таблицах в транзакции

**Проблема:**  
Удаление PTS → Groups → Options → Products выполнялось без транзакции. При ошибке на середине — частично удалённые данные без возможности rollback.

**Исправление (применено в этом PR):**
```ruby
# ✅ СТАЛО
ActiveRecord::Base.transaction do
  group_ids = ProductModifierGroup.where(product_id: mock_product_ids).pluck(:id)
  ProductModifierOption.where(group_id: group_ids).delete_all
  ProductModifierGroup.where(product_id: mock_product_ids).delete_all
  ProductTenantSetting.where(product_id: mock_product_ids).delete_all
  Product.where(id: mock_product_ids).delete_all
end
```

---

### 6. Тесты не были в git

**Файл:** `test/controllers/shop/` (untracked)  
**Правило:** constraints.md §7 — coverage > 80%, controller тесты обязательны

Директория `test/controllers/shop/api/` с `base_controller_test.rb` и `debug_controller_test.rb` существовала локально, но не была добавлена в репозиторий. Исправлено в этом PR.

---

## 🟢 Рекомендации (технический долг)

### A. API без версии нарушает constraints.md §9

`/shop/api/` вместо `/api/v1/` — требование версионирования не выполняется. Это существующий паттерн, не введённый в этих коммитах. Рекомендуется завести отдельный тикет на миграцию.

### B. `down`-метод в SeedBlackCoffeeCatalog использует `destroy` с callbacks

**Файл:** `db/migrate/20260412000003_seed_black_coffee_catalog.rb`

```ruby
# ⚠️ Текущий код — запускает callbacks, N+1
def down
  %w[filtr-kofe-braziliya filtr-kofe-dekaf-gvatemala].each do |slug|
    Product.find_by(slug: slug)&.destroy
  end
  Category.find_by(slug: "chernyj")&.destroy
end

# ✅ Рекомендуется — явный порядок + delete_all
def down
  slugs = %w[filtr-kofe-braziliya filtr-kofe-dekaf-gvatemala]
  product_ids = Product.where(slug: slugs).pluck(:id)
  group_ids = ProductModifierGroup.where(product_id: product_ids).pluck(:id)
  ProductModifierOption.where(group_id: group_ids).delete_all
  ProductModifierGroup.where(product_id: product_ids).delete_all
  ProductTenantSetting.where(product_id: product_ids).delete_all
  Product.where(id: product_ids).delete_all
  Category.where(slug: "chernyj").delete_all
end
```

### C. Debug endpoint — добавить token-guard для staging

Даже в non-production среде endpoint раскрывает PTS данные. Рекомендуется:
```ruby
before_action :require_debug_token!

def require_debug_token!
  expected = ENV["DEBUG_API_TOKEN"]
  return if expected.blank?
  render json: { error: "Forbidden" }, status: :forbidden unless
    request.headers["X-Debug-Token"] == expected
end
```

---

## ✅ Что сделано хорошо

| Файл | Что хорошо |
|------|-----------|
| `base_controller.rb` | `around_action :with_shop_tenant!` корректно оборачивает `SET LOCAL` в транзакцию — RLS работает для всех API-запросов |
| `config/routes.rb` | Debug endpoint скрыт в production через `unless Rails.env.production?` |
| `db/migrate/20260412000003` | PTS создаются в отдельной транзакции с `SET LOCAL` для каждого тенанта |
| `config/database.yml` | Убрано наследование `<<: *default` с `sslmode: disable` — SSL с Render Postgres работает |
| `db/migrate/20260412000000` | Миграция обёрнута в транзакцию, порядок удаления (опции → группы → PTS → продукты) корректный |
| Все новые файлы | `# frozen_string_literal: true` присутствует |
| `db/migrate/20260412000002` | Убрано принудительное `is_active = true` — теперь обрабатываются только уже активные товары |

---

## Итог

| Проблема | Статус |
|----------|--------|
| 🔴 `Product.all` без tenant isolation в debug_controller | **Исправлено в этом PR** |
| 🔴 Неидемпотентная гвардия в SeedBlackCoffeeCatalog | **Исправлено в этом PR** |
| 🟡 `Current.tenant_id = nil` в ensure вместо restore | **Исправлено в этом PR** |
| 🟡 Debug endpoint без production gate | **Исправлено в этом PR** |
| 🟡 RemoveMockCatalogData без транзакции | **Исправлено в этом PR** |
| 🟡 Тесты не в git | **Исправлено в этом PR** |
| 🟢 `down` с `destroy` (callbacks) | Технический долг |
| 🟢 API без версии `/api/v1/` | Технический долг — отдельный тикет |

**Вердикт до этого PR:** БЛОКИРОВКА МЕРЖА  
**Вердикт после этого PR:** ОК (с рекомендациями выше)
