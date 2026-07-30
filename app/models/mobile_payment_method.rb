# frozen_string_literal: true

# Сохранённая карта гостя. Таблица mobile_payment_methods = UserCards в ТЗ.
class MobilePaymentMethod < ApplicationRecord
  PAYMENT_TYPES = %w[card sbp ya_pay].freeze

  belongs_to :customer, class_name: "MobileCustomer", foreign_key: :customer_id, inverse_of: :mobile_payment_methods

  validates :payment_type, inclusion: { in: PAYMENT_TYPES }
  validates :card_token, presence: true, if: -> { payment_type == "card" }
  validates :customer_id, presence: true

  scope :active_cards, -> { where(is_active: true, payment_type: "card") }
  scope :active_sbp, -> { where(is_active: true, payment_type: "sbp") }

  def self.for_customer(customer_id)
    active_cards.where(customer_id: customer_id).order(last_used_at: :desc, created_at: :desc)
  end

  def self.sbp_for_customer(customer_id)
    active_sbp.where(customer_id: customer_id).order(is_default: :desc, last_used_at: :desc, created_at: :desc)
  end

  def self.primary_for(customer_id)
    scope = for_customer(customer_id)
    scope.find_by(is_default: true) || scope.first
  end

  # UserCards.pan в ТЗ: *5953
  def pan_display
    digits = card_masked.to_s.gsub(/\D/, "")
    return "*#{digits[-4..]}" if digits.length >= 4

    card_masked
  end

  # UserCards.rebill_id в ТЗ
  def rebill_id
    card_token
  end
end
