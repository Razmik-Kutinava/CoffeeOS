# УК «Меню», витрина и каталог (изменения)

Кратко: что сделано в рамках доработок экрана управления каталогом УК, витрины `/shop` и связанных мест. Поведение API и данных для витрины/заказов не менялось по смыслу — правки в основном UI, исправление багов и удобство админки.

## 1. Модель `ProductModifierOption` и удаление из УК

У связей `has_many :modifier_option_tenant_settings` и `modifier_option_recipes` в БД внешний ключ — колонка **`option_id`**, а не `product_modifier_option_id`. Без явного `foreign_key: :option_id` Rails строил неверный SQL при `destroy` товара/категории, транзакция откатывалась с ошибкой про несуществующую колонку.

**Исправление:** в `app/models/product_modifier_option.rb` для обеих `has_many` указаны `foreign_key: :option_id` и `inverse_of: :option`.

## 2. Очистка каталога в БД (rake)

Задача **`catalog:purge`** в `lib/tasks/catalog.rake`: в текущей БД (как в `database.yml` / `DATABASE_URL`) удаляет в безопасном порядке `order_items` → `products` → `categories` (из‑за FK `order_items` → `products` с `ON DELETE RESTRICT`). В production вне development/test нужен `FORCE_CATALOG_PURGE=1`.

Важно: ручной SQL на другой базе (например, сторонний проект `coffee_shop_development`) не затрагивает данные приложения CoffeeOS, если Rails подключён к **`coffeeos_development`**.

## 3. УК — управление меню (`/admin/menu`)

- **Загрузка фото товара:** файлы сохраняются в `public/uploads/products/`, в `products.image_url` пишется путь вида `/uploads/products/<uuid>-<hex>.<ext>`; дополнительно можно указать URL вручную. Сервис: `app/services/platform/product_image_storage.rb`. Каталог `public/uploads/` в `.gitignore`.
- **Контроллер** `Platform::MenuController` после create/update товара вызывает сохранение файла, если передан `product[image]`.
- **Стили:** `app/assets/stylesheets/platform_menu.css`, подключение в `app/views/layouts/platform.html.erb`.
- **Модификаторы:** формы групп и вариантов с доплатой (`price_delta`); подсказки и разнесение блоков по смыслу.
- **Компактный UI — аккордеон:** категории и товары в `<details>` (по умолчанию свёрнуты); внутри — прежние формы и действия. Модификаторы — отдельный сворачиваемый блок без автораскрытия. Якоря `#category-<id>` и `#product-<id>` сохранены.

## 4. Витрина `/shop` (Svelte)

- Убраны **технические баннеры** с текстами про `ProductTenantSetting`, `db:seed`, `catalog:replace` из layout витрины и из пустого состояния каталога.
- Удалены **поиск, сортировка и фильтры** на главной витрины; остаётся загрузка категорий и список секций (`CategorySection`).
- Синяя полоска «Витрина для точки…» в `shop` layout убрана.

Данные по-прежнему с API `/shop/api/categories` и товаров; логика цен и `ProductTenantSetting` не менялась.

## 5. Бариста и менеджер

- В списке меню баристы и в сетке «Создание заказа» показывается **превью** товара, если задан `image_url`.
- В меню менеджера (цены точки) у строки — **миниатюра** товара рядом с названием.

## 6. Проверка после изменений

- УК: создание/редактирование категории, товара, загрузка фото, модификаторы, удаление (если нет блокировки заказами).
- Витрина: каталог и карточка товара с картинкой при заполненном `image_url`.
- При необходимости: `bin/rails catalog:purge` (только dev/test или с флагом).

---

*Документ отражает состояние на момент добавления; при смене схемы БД или роутов сверяйтесь с кодом и `db/schema.rb`.*
