# frozen_string_literal: true

# #78: событие применения льготной цены / over-limit скидки подписки.
class SubscriptionUsageEvent < ApplicationRecord
  belongs_to :subscription
  belongs_to :order
  belongs_to :point, class_name: "Tenant"

  validates :applied_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :savings_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :pricing_kind, presence: true, length: { maximum: 32 }
end
