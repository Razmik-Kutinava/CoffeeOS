class ProductModifierGroup < ApplicationRecord
  belongs_to :product
  has_many :product_modifier_options, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(sort_order: :asc) }
end
