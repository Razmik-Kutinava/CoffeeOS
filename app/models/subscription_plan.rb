# frozen_string_literal: true

# #78: конфигурируемый план гостевой подписки (цена/лимиты из БД).
class SubscriptionPlan < ApplicationRecord
  has_many :subscriptions, foreign_key: :plan_id, inverse_of: :plan, dependent: :restrict_with_exception

  validates :code, presence: true, uniqueness: true, length: { maximum: 64 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { maximum: 3 }
  validates :period_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :drink_limit, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :discount_price_per_drink, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :over_limit_discount_percent, presence: true,
                                          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(active: true) }

  # Единый reader параметров плана (без хардкод-констант в pricing).
  def pricing_params
    {
      price: price,
      currency: currency,
      period_days: period_days,
      drink_limit: drink_limit,
      discount_price_per_drink: discount_price_per_drink,
      over_limit_discount_percent: over_limit_discount_percent
    }
  end
end
