class PaymentPollingAttempt < ApplicationRecord
  belongs_to :payment

  validates :attempt_number, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 10 }

  scope :recent, -> { order(created_at: :desc) }
end
