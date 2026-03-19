module Barista
  class MenuController < BaseController
    def index
      @products = Product.joins(:product_tenant_settings)
                         .where(product_tenant_settings: { tenant_id: Current.tenant_id })
                         .includes(:category, :product_tenant_settings)
                         .order('categories.sort_order ASC, products.sort_order ASC')
      @categories = Category.active.order(sort_order: :asc)
    end
  end
end
