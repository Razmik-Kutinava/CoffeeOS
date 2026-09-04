# frozen_string_literal: true

require "test_helper"

# #76 [TDD][RED] point_campaign_settings: модель, counter по point_id, gate GrowthPromo.
class PointCampaignSettingTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @other = create_tenant!(slug: "other-#{SecureRandom.hex(3)}")
  end

  test "creates card_binding_promo with config jsonb and zero counter" do
    setting = PointCampaignSetting.create!(
      point_id: @tenant.id,
      campaign_type: "card_binding_promo",
      enabled: true,
      threshold: 50,
      counter: 0,
      config: { "promo_amount_rub" => 11 }
    )

    assert setting.persisted?
    assert_equal "card_binding_promo", setting.campaign_type
    assert setting.enabled?
    assert_equal 50, setting.threshold
    assert_equal 0, setting.counter
    assert_equal 11, setting.config["promo_amount_rub"]
  end

  test "unique point_id + campaign_type" do
    PointCampaignSetting.create!(
      point_id: @tenant.id,
      campaign_type: "card_binding_promo",
      enabled: true,
      threshold: 10,
      counter: 0,
      config: {}
    )

    assert_raises(ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid) do
      PointCampaignSetting.create!(
        point_id: @tenant.id,
        campaign_type: "card_binding_promo",
        enabled: false,
        threshold: 10,
        counter: 0,
        config: {}
      )
    end
  end

  test "growth_count_for_point sums card and sbp growth only for that point" do
    CardBindingAttempt.record!(
      method_type: "card", method_hash: "g-card-1", phone: "+79001110001",
      point_id: @tenant.id, result: "ok", is_growth_event: true
    )
    CardBindingAttempt.record!(
      method_type: "sbp", method_hash: "g-sbp-1", phone: "+79001110002",
      point_id: @tenant.id, result: "ok", is_growth_event: true
    )
    CardBindingAttempt.record!(
      method_type: "card", method_hash: "g-fail", phone: "+79001110003",
      point_id: @tenant.id, result: "fail", is_growth_event: false
    )
    CardBindingAttempt.record!(
      method_type: "card", method_hash: "g-other", phone: "+79001110004",
      point_id: @other.id, result: "ok", is_growth_event: true
    )

    assert_equal 2, CardBindingAttempt.growth_count_for_point(@tenant.id)
    assert_equal 1, CardBindingAttempt.growth_count_for_point(@other.id)
  end
end
