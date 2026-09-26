# frozen_string_literal: true

# #78: гостевая подписка PWA (customer-scoped, point-agnostic usage).
class Subscription < ApplicationRecord
  OFFER_CHANNELS = %w[banner lk push].freeze
  ROLLING_USAGE_DAYS = 7

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
  validates :offer_channel, inclusion: { in: OFFER_CHANNELS }, allow_nil: true

  scope :for_customer, ->(customer_id) { where(customer_id: customer_id) }

  def start_period_from_plan!(plan = self.plan, at: Time.current)
    params = plan.pricing_params
    self.current_period_start = at
    self.current_period_end = at + params[:period_days].days
    self.price_at_period_start = params[:price]
    self.drink_limit_at_period_start = params[:drink_limit]
    self.discount_percent_at_period_start = params[:over_limit_discount_percent]
    # Патч 1: счётчик колонки не источник истины; events не трогаем.
    self.drinks_used_this_period = 0
    self
  end

  # Скользящее окно последних 7 дней относительно at (время заказа).
  def usage_events_in_rolling_window(at: Time.current)
    window_start = at - ROLLING_USAGE_DAYS.days
    subscription_usage_events.where(created_at: window_start..at)
  end

  def usage_count_in_rolling_window(at: Time.current)
    usage_events_in_rolling_window(at: at).count
  end

  # Факт использования внутри текущего оплаченного периода (cancel / auto_renew).
  def usage_events_in_current_period
    raise ArgumentError, "period bounds missing" if current_period_start.blank? || current_period_end.blank?

    subscription_usage_events.where(created_at: current_period_start..current_period_end)
  end

  def used_in_current_period?
    usage_events_in_current_period.exists?
  end
end
