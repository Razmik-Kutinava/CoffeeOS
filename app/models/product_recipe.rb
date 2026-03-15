class ProductRecipe < ApplicationRecord
  belongs_to :product
  belongs_to :ingredient

  validates :product_id, uniqueness: { scope: :ingredient_id }
  validates :qty_per_serving, presence: true, numericality: { greater_than: 0 }
end
