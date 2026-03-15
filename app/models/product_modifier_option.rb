class ProductModifierOption < ApplicationRecord
  belongs_to :group, class_name: 'ProductModifierGroup', foreign_key: 'group_id'
  has_many :modifier_option_tenant_settings, dependent: :destroy
  has_many :modifier_option_recipes, dependent: :destroy

  validates :name, presence: true
  validates :price_delta, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc) }
end
