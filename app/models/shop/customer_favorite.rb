# frozen_string_literal: true

module Shop
  class CustomerFavorite < ApplicationRecord
    self.table_name = "shop_customer_favorites"

    belongs_to :customer, class_name: "MobileCustomer"
    belongs_to :tenant
    belongs_to :product

    validates :customer_id, uniqueness: { scope: %i[tenant_id product_id] }
  end
end
