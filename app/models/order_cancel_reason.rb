class OrderCancelReason < ApplicationRecord
  has_many :orders, foreign_key: 'cancel_reason_code', primary_key: 'code', dependent: :nullify

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc) }
end
