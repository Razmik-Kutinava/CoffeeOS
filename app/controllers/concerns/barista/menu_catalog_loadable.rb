# frozen_string_literal: true

module Barista
  module MenuCatalogLoadable
    extend ActiveSupport::Concern

    private

    def load_tenant_menu!
      menu = Shop::Catalog.tenant_menu(Current.tenant_id)
      @products = menu[:products]
      @categories = menu[:categories]
      @settings_by_product_id = menu[:settings_by_product_id]
    end
  end
end
