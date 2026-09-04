# frozen_string_literal: true

# #76: настройки точечных кампаний (промо 11₽ и будущие типы через campaign_type + config).
class PointCampaignSetting < ApplicationRecord
  CAMPAIGN_CARD_BINDING_PROMO = "card_binding_promo"
  DEFAULT_THRESHOLD = 100
  DEFAULT_PROMO_AMOUNT_RUB = 11

  belongs_to :point, class_name: "Tenant", foreign_key: :point_id, inverse_of: :point_campaign_settings

  validates :campaign_type, presence: true
  validates :threshold, numericality: { only_integer: true, greater_than: 0 }
  validates :counter, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :campaign_type, uniqueness: { scope: :point_id }

  def self.card_binding_promo_for(point_id)
    find_by(point_id: point_id, campaign_type: CAMPAIGN_CARD_BINDING_PROMO)
  end

  def refresh_counter!
    live = CardBindingAttempt.growth_count_for_point(point_id)
    update_column(:counter, live) if counter != live
    live
  end
end
