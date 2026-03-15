class ProductMenuVisibility < ApplicationRecord
  belongs_to :product
  belongs_to :menu_type

  validates :product_id, uniqueness: { scope: :menu_type_id }
  validates :is_visible, inclusion: { in: [true, false] }
end
