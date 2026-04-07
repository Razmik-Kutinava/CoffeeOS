# frozen_string_literal: true

# Полная замена меню точки на рабочий каталог CoffeeOS из db/seeds_shop_catalog.rb
# (те же Product / Category / PTS, что бариста и админки).
#
#   bin/rails catalog:replace
#   CATALOG_TENANT_SLUG=my-point bin/rails catalog:replace
# (устаревшее имя: CODEBLACK_TENANT_SLUG)
#

namespace :catalog do
  desc "Полностью очистить категории и товары в текущей БД (как в database.yml / DATABASE_URL). " \
       "Сначала удаляет order_items (FK restrict на products). Только development или FORCE_CATALOG_PURGE=1."
  task purge: :environment do
    unless Rails.env.development? || Rails.env.test? || ENV["FORCE_CATALOG_PURGE"] == "1"
      raise "Отказ: задайте FORCE_CATALOG_PURGE=1 для запуска вне development/test"
    end

    db = ActiveRecord::Base.connection_db_config.database
    puts "[catalog:purge] БД: #{db} (#{Rails.env})"

    n_oi = OrderItem.delete_all
    n_p = Product.delete_all
    n_c = Category.delete_all
    puts "[catalog:purge] Удалено: order_items=#{n_oi}, products=#{n_p}, categories=#{n_c}"
    puts "[catalog:purge] Готово. Витрина и УК читают эту же БД — обновите страницу."
  end

  desc "Удалить заказы точки и старый демо-каталог, загрузить каталог CoffeeOS (см. db/seeds_shop_catalog.rb)"
  task replace: :environment do
    slug = ENV["CATALOG_TENANT_SLUG"].presence || ENV["CODEBLACK_TENANT_SLUG"].presence || "test-cafe"
    tenant = Tenant.find_by(slug: slug)
    raise "Tenant со slug=#{slug.inspect} не найден. Создайте точку или задайте CATALOG_TENANT_SLUG." unless tenant

    legacy_slugs = %w[
      cappuccino-m cappuccino-l latte-m latte-l americano-m espresso flat-white raf-coffee
      green-tea black-tea tea-lemon croissant sandwich salad donut cheesecake cake cookie
    ].freeze

    puts "[catalog] Заказы tenant_id=#{tenant.id} (#{slug})..."
    Order.where(tenant_id: tenant.id).find_each(&:destroy!)

    puts "[catalog] Старые товары (barista seed, seed-shop, import-cs, устаревшие cb-prod-*)..."
    rel = Product.where(slug: legacy_slugs)
    rel = rel.or(Product.where("slug LIKE ?", "seed-shop-%"))
    rel = rel.or(Product.where("slug LIKE ?", "import-cs-prod-%"))
    rel = rel.or(Product.where("slug LIKE ?", "cb-prod-%"))
    rel.find_each do |product|
      product.destroy!
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::DeleteRestrictionError => e
      warn "[catalog] пропуск #{product.slug}: #{e.message}"
    end

    puts "[catalog] Пустые категории coffee/tea/food/desserts, import-cs-cat-*, cb-cat-*..."
    Category.where(slug: %w[coffee tea food desserts]).find_each do |cat|
      cat.destroy! if cat.products.none?
    rescue ActiveRecord::DeleteRestrictionError
      warn "[catalog] категория #{cat.slug} не пуста — оставлена"
    end
    Category.where("slug LIKE ?", "import-cs-cat-%").find_each do |cat|
      cat.destroy! if cat.products.none?
    rescue ActiveRecord::DeleteRestrictionError
      warn "[catalog] категория #{cat.slug} не пуста — оставлена"
    end
    Category.where("slug LIKE ?", "cb-cat-%").find_each do |cat|
      cat.destroy! if cat.products.none?
    rescue ActiveRecord::DeleteRestrictionError
      warn "[catalog] категория #{cat.slug} не пуста — оставлена"
    end

    ENV["CATALOG_TENANT_SLUG"] = slug
    ENV["CODEBLACK_TENANT_SLUG"] = slug
    load Rails.root.join("db/seeds_shop_catalog.rb")
    puts "[catalog] Готово. Обнови /shop (кэш каталога) или открой в инкогнито."
  end
end
