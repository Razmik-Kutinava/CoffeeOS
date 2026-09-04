# frozen_string_literal: true

require "test_helper"

# #77 [TDD][RED] point-scoped subscription_offer_settings
class SubscriptionOfferSettingTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @other = create_tenant!(slug: "other-#{SecureRandom.hex(3)}")
  end

  test "creates one setting per point with defaults" do
    setting = SubscriptionOfferSetting.create!(
      point_id: @tenant.id,
      enabled: true,
      second_cta_mode: "subscription",
      min_completed_orders: 1,
      required_signals_count: 1
    )

    assert setting.persisted?
    assert setting.enabled?
    assert_equal "subscription", setting.second_cta_mode
    assert_equal 1, setting.min_completed_orders
    assert_equal 1, setting.required_signals_count
  end

  test "unique point_id" do
    SubscriptionOfferSetting.create!(
      point_id: @tenant.id,
      enabled: false,
      second_cta_mode: "tips",
      min_completed_orders: 1,
      required_signals_count: 1
    )

    assert_raises(ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid) do
      SubscriptionOfferSetting.create!(
        point_id: @tenant.id,
        enabled: true,
        second_cta_mode: "subscription",
        min_completed_orders: 2,
        required_signals_count: 2
      )
    end
  end

  test "isolates settings by point_id" do
    a = SubscriptionOfferSetting.create!(
      point_id: @tenant.id, enabled: true, second_cta_mode: "subscription",
      min_completed_orders: 1, required_signals_count: 1
    )
    b = SubscriptionOfferSetting.create!(
      point_id: @other.id, enabled: false, second_cta_mode: "tips",
      min_completed_orders: 3, required_signals_count: 2
    )

    assert_equal true, a.enabled?
    assert_equal false, b.enabled?
    assert_equal 1, a.required_signals_count
    assert_equal 2, b.required_signals_count
  end

  test "rejects required_signals_count outside 1..3" do
    setting = SubscriptionOfferSetting.new(
      point_id: @tenant.id,
      enabled: true,
      second_cta_mode: "tips",
      min_completed_orders: 1,
      required_signals_count: 0
    )
    assert_not setting.valid?
    assert setting.errors[:required_signals_count].any?

    setting.required_signals_count = 4
    assert_not setting.valid?

    setting.required_signals_count = 2
    assert setting.valid?
  end

  test "rejects invalid second_cta_mode" do
    setting = SubscriptionOfferSetting.new(
      point_id: @tenant.id,
      enabled: true,
      second_cta_mode: "unknown",
      min_completed_orders: 1,
      required_signals_count: 1
    )
    assert_not setting.valid?
    assert setting.errors[:second_cta_mode].any?
  end
end
