class OrderStatusLog < ApplicationRecord
  enum source: {
    system: 'system',
    barista: 'barista',
    shift_manager: 'shift_manager',
    payment_callback: 'payment_callback',
    customer: 'customer'
  }

  belongs_to :order
  belongs_to :changed_by, class_name: 'User', optional: true
  belongs_to :device, optional: true

  # status_from и status_to хранятся как строки (order_status ENUM из БД)
  validates :status_to, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_order, ->(order_id) { where(order_id: order_id).order(created_at: :asc) }
end
