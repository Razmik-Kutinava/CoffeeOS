class ProductModifierGroup < ApplicationRecord
  belongs_to :product
  has_many :product_modifier_options, foreign_key: :group_id, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(sort_order: :asc) }
end
