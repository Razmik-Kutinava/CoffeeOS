# frozen_string_literal: true

module Platform
  # #76: upsert card_binding_promo для точки УК. Counter не обнуляется; без наследования между точками.
  class PointCampaignSettingsSync
    def self.call(tenant:, enabled:, threshold: nil)
      new(tenant: tenant, enabled: enabled, threshold: threshold).call
    end

    def initialize(tenant:, enabled:, threshold: nil)
      @tenant = tenant
      @enabled = ActiveModel::Type::Boolean.new.cast(enabled)
      @threshold = threshold
    end

    def call
      return true if tenant.blank?

      setting = PointCampaignSetting.find_or_initialize_by(
        point_id: tenant.id,
        campaign_type: PointCampaignSetting::CAMPAIGN_CARD_BINDING_PROMO
      )

      setting.enabled = @enabled
      if @threshold.present?
        setting.threshold = @threshold.to_i
      elsif setting.new_record?
        setting.threshold = PointCampaignSetting::DEFAULT_THRESHOLD
      end
      setting.counter = 0 if setting.new_record?
      setting.config = default_config.merge(setting.config.is_a?(Hash) ? setting.config : {})

      setting.save!
      true
    rescue ActiveRecord::RecordInvalid => e
      tenant.errors.add(:base, e.record.errors.full_messages.to_sentence.presence || e.message)
      false
    end

    private

    attr_reader :tenant

    def default_config
      { "promo_amount_rub" => PointCampaignSetting::DEFAULT_PROMO_AMOUNT_RUB }
    end
  end
end
