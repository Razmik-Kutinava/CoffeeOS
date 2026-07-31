# frozen_string_literal: true

# #35 B3 — метаданные .pkpass на заказ (serial / auth token / revision).
class OrderWalletPass < ApplicationRecord
  belongs_to :order
  belongs_to :tenant
  belongs_to :customer, class_name: "MobileCustomer", optional: true

  validates :serial_number, :authentication_token, :status_label, presence: true
end
