# frozen_string_literal: true

# Сохранённая карта гостя (Т-Банк RebillId). Таблица mobile_payment_methods = UserCards в ТЗ B1.12.
class MobilePaymentMethod < ApplicationRecord
  PAYMENT_TYPES = %w[card sbp ya_pay].freeze

  belongs_to :customer, class_name: "MobileCustomer", foreign_key: :customer_id, inverse_of: :mobile_payment_methods

  validates :payment_type, inclusion: { in: PAYMENT_TYPES }
  validates :card_token, presence: true, if: -> { payment_type == "card" }
  validates :customer_id, presence: true

  scope :active_cards, -> { where(is_active: true, payment_type: "card") }

  def self.for_customer(customer_id)
    active_cards.where(customer_id: customer_id).order(last_used_at: :desc, created_at: :desc)
  end

  def self.primary_for(customer_id)
    scope = for_customer(customer_id)
    scope.find_by(is_default: true) || scope.first
  end
end
