# frozen_string_literal: true

require "test_helper"

# #76 [TDD][RED] upsert card_binding_promo для точки УК — без wipe counter, без наследования.
class Platform::PointCampaignSettingsSyncTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @city_twin = create_tenant!(slug: "twin-#{SecureRandom.hex(3)}", city: @tenant.city)
  end

  test "upsert enables promo with threshold and counter zero" do
    ok = Platform::PointCampaignSettingsSync.call(
      tenant: @tenant,
      enabled: true,
      threshold: 25
    )
    assert ok

    setting = PointCampaignSetting.find_by!(point_id: @tenant.id, campaign_type: "card_binding_promo")
    assert setting.enabled?
    assert_equal 25, setting.threshold
    assert_equal 0, setting.counter
    assert_equal 11, setting.config["promo_amount_rub"]
  end

  test "disable keeps historical counter" do
    Platform::PointCampaignSettingsSync.call(tenant: @tenant, enabled: true, threshold: 10)
    setting = PointCampaignSetting.find_by!(point_id: @tenant.id, campaign_type: "card_binding_promo")
    setting.update!(counter: 7)

    Platform::PointCampaignSettingsSync.call(tenant: @tenant, enabled: false, threshold: 10)
    setting.reload
    refute setting.enabled?
    assert_equal 7, setting.counter
  end

  test "idempotent save does not duplicate rows" do
    2.times do
      Platform::PointCampaignSettingsSync.call(tenant: @tenant, enabled: true, threshold: 40)
    end

    assert_equal 1, PointCampaignSetting.where(point_id: @tenant.id, campaign_type: "card_binding_promo").count
  end

  test "does not copy campaign to another point in same city" do
    Platform::PointCampaignSettingsSync.call(tenant: @tenant, enabled: true, threshold: 15)

    assert_nil PointCampaignSetting.find_by(point_id: @city_twin.id, campaign_type: "card_binding_promo")
  end
end
