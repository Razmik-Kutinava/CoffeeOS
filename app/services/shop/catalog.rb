# frozen_string_literal: true

module Shop
  module Catalog
    module_function

    def products_scope(tenant_id)
      Product.active.joins(:product_tenant_settings)
        .where(product_tenant_settings: { tenant_id: tenant_id })
        .merge(ProductTenantSetting.available)
        .distinct
    end

    def stock_for_display(setting)
      return 999 if setting.stock_qty.nil?

      setting.stock_qty.to_i
    end

    # Товары, доступные на витрине для точки (есть PTS и включено / не sold_out).
    def enabled_products_count(tenant_id)
      products_scope(tenant_id).count
    end

    # Меню точки: те же товары/категории, что на витрине (products_scope + Category.active).
    def tenant_menu(tenant_id)
      products = products_scope(tenant_id)
        .includes(:category)
        .order("categories.sort_order ASC, products.sort_order ASC")
        .to_a

      category_ids = products.map(&:category_id).uniq
      categories = Category.active.where(id: category_ids).ordered.to_a

      settings_by_product_id = ProductTenantSetting
        .where(product_id: products.map(&:id), tenant_id: tenant_id)
        .index_by(&:product_id)

      { products: products, categories: categories, settings_by_product_id: settings_by_product_id }
    end

    # category_name => [product_id, ...] — для сверки витрина / barista / тесты.
    def category_product_ids(tenant_id)
      menu = tenant_menu(tenant_id)
      menu[:categories].each_with_object({}) do |cat, acc|
        ids = menu[:products].select { |p| p.category_id == cat.id }.map(&:id)
        acc[cat.id] = ids
      end
    end
  end
end
