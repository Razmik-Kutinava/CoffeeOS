# frozen_string_literal: true

# #77: настройки оффера подписки на точке (вторая CTA + пороги eligibility).
class SubscriptionOfferSetting < ApplicationRecord
  SECOND_CTA_MODES = %w[tips subscription].freeze

  belongs_to :point, class_name: "Tenant", foreign_key: :point_id, inverse_of: :subscription_offer_setting

  validates :point_id, uniqueness: true
  validates :second_cta_mode, inclusion: { in: SECOND_CTA_MODES }
  validates :min_completed_orders, numericality: { only_integer: true, greater_than: 0 }
  validates :required_signals_count, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 3
  }

  def self.for_point(point_id)
    find_by(point_id: point_id)
  end

  def self.client_json_for(point_id)
    setting = for_point(point_id)
    {
      enabled: setting&.enabled? || false,
      second_cta_mode: setting&.second_cta_mode || "tips"
    }
  end

  def self.defaults_hash
    {
      enabled: false,
      second_cta_mode: "tips",
      min_completed_orders: 1,
      required_signals_count: 1
    }
  end
end
