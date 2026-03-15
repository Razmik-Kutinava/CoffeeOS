class PaymentStatusLog < ApplicationRecord
  enum source: { callback: 'callback', polling: 'polling', manual: 'manual' }

  belongs_to :payment

  validates :status_to, presence: true
  validates :source, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
