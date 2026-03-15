class StockMovementItem < ApplicationRecord
  belongs_to :movement, class_name: 'StockMovement', foreign_key: 'movement_id'
  belongs_to :ingredient

  validates :qty_change, presence: true, numericality: { other_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
