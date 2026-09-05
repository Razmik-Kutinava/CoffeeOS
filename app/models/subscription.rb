# frozen_string_literal: true

# #78: гостевая подписка PWA (customer-scoped, point-agnostic usage).
class Subscription < ApplicationRecord
  belongs_to :customer, class_name: "MobileCustomer"
  belongs_to :plan, class_name: "SubscriptionPlan"
  belongs_to :purchase_point, class_name: "Tenant"
  belongs_to :payment_method, class_name: "MobilePaymentMethod", optional: true
  belongs_to :payment, optional: true
  has_many :subscription_usage_events, dependent: :restrict_with_exception

  enum :status, {
    pending: "pending",
    active: "active",
    canceled: "canceled",
    past_due: "past_due"
  }, validate: true

  validates :drinks_used_this_period, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :auto_renew, inclusion: { in: [ true, false ] }

  scope :for_customer, ->(customer_id) { where(customer_id: customer_id) }

  def start_period_from_plan!(plan = self.plan, at: Time.current)
    params = plan.pricing_params
    self.current_period_start = at
    self.current_period_end = at + params[:period_days].days
    self.price_at_period_start = params[:price]
    self.drink_limit_at_period_start = params[:drink_limit]
    self.discount_percent_at_period_start = params[:over_limit_discount_percent]
    self.drinks_used_this_period = 0
    self
  end
end
