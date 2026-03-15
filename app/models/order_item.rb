class OrderItem < ApplicationRecord
  belongs_to :order
  # product_id без FK т.к. может измениться

  validates :product_id, presence: true
  validates :product_name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :price_consistency

  private

  def price_consistency
    return unless unit_price && quantity && total_price
    return if total_price == unit_price * quantity

    errors.add(:total_price, 'должна равняться unit_price * quantity')
  end
end
