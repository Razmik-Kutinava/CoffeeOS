# frozen_string_literal: true

require "test_helper"

# #76 [TDD][RED] GrowthPromo gate по point_campaign_settings + изоляция точек.
class Payments::GrowthPromoPointCampaignTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant_a = create_tenant!(slug: "camp-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(slug: "camp-b-#{SecureRandom.hex(3)}")
    Current.tenant_id = @tenant_a.id
    @phone = "+7902#{format('%07d', rand(10_000_000))}"
    @customer = create_mobile_customer!(phone: @phone, email: "camp-#{SecureRandom.hex(3)}@example.com")
  end

  teardown do
    Current.reset
  end

  test "not eligible when point has no card_binding_promo campaign" do
    refute Payments::GrowthPromo.eligible?(
      tenant: @tenant_a,
      customer: @customer,
      bind_requested: true
    )
  end

  test "not eligible when campaign disabled" do
    PointCampaignSetting.create!(
      point_id: @tenant_a.id,
      campaign_type: "card_binding_promo",
      enabled: false,
      threshold: 100,
      counter: 0,
      config: { "promo_amount_rub" => 11 }
    )

    refute Payments::GrowthPromo.eligible?(
      tenant: @tenant_a,
      customer: @customer,
      bind_requested: true
    )
  end

  test "eligible when campaign enabled and under threshold" do
    PointCampaignSetting.create!(
      point_id: @tenant_a.id,
      campaign_type: "card_binding_promo",
      enabled: true,
      threshold: 2,
      counter: 0,
      config: { "promo_amount_rub" => 11 }
    )

    assert Payments::GrowthPromo.eligible?(
      tenant: @tenant_a,
      customer: @customer,
      bind_requested: true
    )
  end

  test "stops promo when growth count reaches threshold for that point only" do
    PointCampaignSetting.create!(
      point_id: @tenant_a.id,
      campaign_type: "card_binding_promo",
      enabled: true,
      threshold: 2,
      counter: 0,
      config: { "promo_amount_rub" => 11 }
    )
    PointCampaignSetting.create!(
      point_id: @tenant_b.id,
      campaign_type: "card_binding_promo",
      enabled: true,
      threshold: 10,
      counter: 0,
      config: { "promo_amount_rub" => 11 }
    )

    2.times do |i|
      CardBindingAttempt.record!(
        method_type: i.even? ? "card" : "sbp",
        method_hash: "thr-#{i}-#{SecureRandom.hex(4)}",
        phone: "+7903#{format('%07d', i)}",
        point_id: @tenant_a.id,
        result: "ok",
        is_growth_event: true
      )
    end

    refute Payments::GrowthPromo.eligible?(
      tenant: @tenant_a,
      customer: @customer,
      bind_requested: true
    )

    Current.tenant_id = @tenant_b.id
    other = create_mobile_customer!(phone: "+7904#{format('%07d', rand(10_000_000))}", email: "b-#{SecureRandom.hex(3)}@example.com")
    assert Payments::GrowthPromo.eligible?(
      tenant: @tenant_b,
      customer: other,
      bind_requested: true
    )
  end
end
