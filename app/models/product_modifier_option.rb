class ProductModifierOption < ApplicationRecord
  belongs_to :group, class_name: 'ProductModifierGroup', foreign_key: 'group_id'
  # В БД колонка option_id, не product_modifier_option_id (Rails по умолчанию угадывает неверно).
  has_many :modifier_option_tenant_settings, foreign_key: :option_id, dependent: :destroy, inverse_of: :option
  has_many :modifier_option_recipes, foreign_key: :option_id, dependent: :destroy, inverse_of: :option

  validates :name, presence: true
  validates :price_delta, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc) }
end
