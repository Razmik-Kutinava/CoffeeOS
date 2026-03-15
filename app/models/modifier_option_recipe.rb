class ModifierOptionRecipe < ApplicationRecord
  belongs_to :option, class_name: 'ProductModifierOption', foreign_key: 'option_id'
  belongs_to :ingredient

  validates :option_id, uniqueness: { scope: :ingredient_id }
  validates :qty_change, presence: true
end
