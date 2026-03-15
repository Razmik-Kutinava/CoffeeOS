class Ingredient < ApplicationRecord
  enum unit: { g: 'g', ml: 'ml', pcs: 'pcs' }

  has_many :ingredient_tenant_stocks, dependent: :destroy
  has_many :product_recipes, dependent: :destroy
  has_many :modifier_option_recipes, dependent: :destroy

  validates :name, presence: true
  validates :unit, presence: true
  validates :is_active, inclusion: { in: [true, false] }

  scope :active, -> { where(is_active: true) }
end
