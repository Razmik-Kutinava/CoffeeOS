# frozen_string_literal: true

# Импорт каталога из БД coffee-shop в CoffeeOS без новых таблиц и без изменения схемы.
#
# Env:
#   COFFEE_SHOP_DATABASE_URL     — Postgres URL БД coffee-shop (обязательно)
#   COFFEE_SHOP_IMPORT_TENANT_ID — UUID точки в CoffeeOS (или SHOP_DEFAULT_TENANT_ID)
#   COFFEE_SHOP_IMPORT_DRY_RUN=1 — только считать строки на источнике, без записи
#
# Откат: bin/rails coffee_shop:rollback_import — удаляет только slug import-cs-prod-% и
# import-cs-cat-% (PTS и модификаторы уходят каскадом). Сухой прогон: тот же DRY_RUN=1.
# Если на импортный товар ссылаются order_items, destroy упадёт — сначала уберите позиции.
#
# Идемпотентность: slug import-cs-cat-<legacy_id>, import-cs-prod-<legacy_id>.
# При повторном импорте группы/опции модификаторов у таких продуктов пересоздаются
# (в coffee-shop нет UUID — иначе дублировались бы группы).
#
# Явные решения по маппингу (полей-аналогов в CoffeeOS нет или названия другие):
#   • coffee-shop modifier_type "radio" → product_modifier_groups.is_required true
#     (один обязательный выбор); "checkbox" → is_required false.
#   • Цена/остаток точки: только product_tenant_settings (как в CoffeeOS), не дублируем
#     бизнес-логику заказов coffee-shop.
#   • base_price в products = цена из coffee-shop при price > 0; иначе NULL (колонка
#     допускает NULL в schema.rb).
#   • При price <= 0: is_enabled false, price NULL (валидация ProductTenantSetting).
#   • stock <= 0 при включённом продукте: is_sold_out true, sold_out_reason stock_empty;
#     при выключенном продукте sold-out сбрасываем (chk_sold_out_reason).
#   • Отрицательный price_change в coffee-shop: в CoffeeOS price_delta >= 0, подставляем 0
#     и пишем предупреждение в stderr (другого поля под «скидку за опцию» в схеме нет).
#   • allergens, ingredients, nutrition_info (jsonb), volume_ml в coffee-shop нет отдельных
#     колонок в products CoffeeOS — сводим в одно поле description (блоки текста / JSON).
#
# Не импортируем (нет прямых аналогов каталога в текущей схеме): users, orders, order_items,
# favorites, promo_codes, promo_code_usages.
#

module CoffeeShopCatalogImport
  class SourceRecord < ActiveRecord::Base
    self.abstract_class = true
  end

  module_function

  def slug_cat(id) = "import-cs-cat-#{id}"

  def slug_prod(id) = "import-cs-prod-#{id}"

  def truncate(s, max)
    s.to_s.truncate(max, omission: "")
  end

  def non_negative_price_delta(raw, modifier_id)
    d = raw.to_d
    if d.negative?
      warn "coffee_shop modifier id=#{modifier_id}: price_change #{d} < 0 → price_delta 0 (ограничение схемы CoffeeOS)"
      0.to_d
    else
      d
    end
  end

  def map_required(modifier_type)
    modifier_type.to_s == "radio"
  end

  # Единственное текстовое поле под «описание товара» в CoffeeOS — склеиваем то, что есть в источнике.
  def compose_product_description(row)
    parts = []
    d = row["description"].to_s.strip
    parts << d if d.present?

    ing = row["ingredients"].to_s.strip
    parts << "Состав: #{ing}" if ing.present?

    al = row["allergens"].to_s.strip
    parts << "Аллергены: #{al}" if al.present?

    vol = row["volume_ml"]
    if vol.present? && vol.to_i.positive?
      parts << "Объём: #{vol.to_i} мл"
    end

    ni = row["nutrition_info"]
    if ni.present?
      json =
        case ni
        when String then ni.strip
        when Hash then ni.to_json
        else ni.to_s
        end
      parts << "Пищевая ценность: #{json}" if json.present? && json != "{}"
    end

    parts.join("\n\n").presence
  end

  def build_pts_attrs(shop_price, shop_stock, shop_active)
    price = shop_price.to_d
    stock = shop_stock.to_i
    enabled = shop_active && price.positive?
    sold_out = enabled && stock <= 0
    {
      price: (price.positive? ? price : nil),
      is_enabled: enabled,
      stock_qty: stock,
      is_sold_out: sold_out,
      sold_out_reason: sold_out ? "stock_empty" : nil
    }
  end
end

namespace :coffee_shop do
  desc "Импорт категорий, продуктов, модификаторов из БД coffee-shop в текущую БД CoffeeOS"
  task import_catalog: :environment do
    url = ENV.fetch("COFFEE_SHOP_DATABASE_URL")
    tenant_id = ENV["COFFEE_SHOP_IMPORT_TENANT_ID"].presence || ENV["SHOP_DEFAULT_TENANT_ID"].presence
    raise "Задайте COFFEE_SHOP_IMPORT_TENANT_ID или SHOP_DEFAULT_TENANT_ID (UUID точки CoffeeOS)" if tenant_id.blank?

    tenant = Tenant.find(tenant_id)
    dry = ENV["COFFEE_SHOP_IMPORT_DRY_RUN"].present?

    CoffeeShopCatalogImport::SourceRecord.establish_connection(url)
    src = CoffeeShopCatalogImport::SourceRecord.connection

    cats = src.select_all("SELECT id, name, active, position FROM categories ORDER BY position, id").to_a
    prods = src.select_all(<<~SQL.squish).to_a
      SELECT id, category_id, name, description, image_url, price, stock, active,
             allergens, ingredients, nutrition_info, volume_ml
      FROM products ORDER BY id
    SQL
    groups = src.select_all(
      "SELECT id, product_id, name, modifier_type, position FROM modifier_groups ORDER BY product_id, position, id"
    ).to_a
    mods = src.select_all(
      "SELECT id, modifier_group_id, name, price_change, position FROM modifiers ORDER BY modifier_group_id, position, id"
    ).to_a

    puts "Источник: categories=#{cats.size}, products=#{prods.size}, modifier_groups=#{groups.size}, modifiers=#{mods.size}"
    next if dry

    mods_by_group = mods.group_by { |r| r["modifier_group_id"].to_i }

    ActiveRecord::Base.transaction do
      Current.tenant_id = tenant.id

      cat_uuid_by_legacy = {}

      cats.each do |row|
        legacy_id = row["id"]
        slug = CoffeeShopCatalogImport.slug_cat(legacy_id)
        cat = Category.find_or_initialize_by(slug: slug)
        cat.assign_attributes(
          name: CoffeeShopCatalogImport.truncate(row["name"], 255),
          is_active: row["active"] != false,
          sort_order: row["position"].to_i
        )
        cat.save!
        cat_uuid_by_legacy[legacy_id.to_i] = cat.id
      end

      prods.each do |row|
        legacy_cid = row["category_id"].to_i
        category_uuid = cat_uuid_by_legacy[legacy_cid]
        unless category_uuid
          warn "Пропуск product id=#{row['id']}: нет category_id=#{legacy_cid} в импортированных категориях"
          next
        end

        legacy_pid = row["id"]
        slug = CoffeeShopCatalogImport.slug_prod(legacy_pid)
        price = row["price"].to_d
        product = Product.find_or_initialize_by(slug: slug)
        product.assign_attributes(
          category_id: category_uuid,
          name: CoffeeShopCatalogImport.truncate(row["name"], 255),
          description: CoffeeShopCatalogImport.compose_product_description(row),
          image_url: CoffeeShopCatalogImport.truncate(row["image_url"], 500),
          base_price: (price.positive? ? price : nil),
          is_active: row["active"] != false,
          sort_order: row["id"].to_i
        )
        product.save!

        pts = ProductTenantSetting.find_or_initialize_by(tenant_id: tenant.id, product_id: product.id)
        pts.assign_attributes(CoffeeShopCatalogImport.build_pts_attrs(row["price"], row["stock"], row["active"] != false))
        pts.save!

        # Пересборка модификаторов для идемпотентности (только импортные продукты).
        product.product_modifier_groups.destroy_all if slug.start_with?("import-cs-prod-")

        groups.select { |g| g["product_id"].to_i == legacy_pid.to_i }.each do |g|
          grp = product.product_modifier_groups.create!(
            name: CoffeeShopCatalogImport.truncate(g["name"], 100),
            is_required: CoffeeShopCatalogImport.map_required(g["modifier_type"]),
            sort_order: g["position"].to_i
          )
          (mods_by_group[g["id"].to_i] || []).each do |m|
            grp.product_modifier_options.create!(
              name: CoffeeShopCatalogImport.truncate(m["name"], 100),
              price_delta: CoffeeShopCatalogImport.non_negative_price_delta(m["price_change"], m["id"]),
              is_active: true,
              sort_order: m["position"].to_i
            )
          end
        end
      end
    ensure
      Current.tenant_id = nil
    end

    puts "Импорт завершён для tenant_id=#{tenant.id}"
  end

  desc "Удалить каталог импорта coffee-shop (slug import-cs-prod-*, import-cs-cat-*)"
  task rollback_import: :environment do
    dry = ENV["COFFEE_SHOP_IMPORT_DRY_RUN"].present?
    prod_scope = Product.where("slug LIKE ?", "import-cs-prod-%")
    cat_scope = Category.where("slug LIKE ?", "import-cs-cat-%")

    puts "К удалению: products=#{prod_scope.count}, categories=#{cat_scope.count}"
    if dry
      puts "(COFFEE_SHOP_IMPORT_DRY_RUN=1 — удаление не выполнялось)"
      next
    end

    ActiveRecord::Base.transaction do
      prod_scope.order(:id).find_each(&:destroy!)
      cat_scope.order(:id).find_each(&:destroy!)
    end
    puts "Откат импорта coffee-shop выполнен."
  rescue ActiveRecord::RecordNotDestroyed => e
    warn "Не удалось удалить запись: #{e.record.class}##{e.record.id} — #{e.record.errors.full_messages.join(', ')}"
    raise
  rescue ActiveRecord::DeleteRestrictionError => e
    warn "Ограничение связей: #{e.message} (возможно, не импортный товар в импортной категории)"
    raise
  rescue ActiveRecord::InvalidForeignKey => e
    warn "Внешний ключ БД: #{e.message} — проверьте order_items и другие ссылки на этот product_id"
    raise
  end
end
