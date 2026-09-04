# frozen_string_literal: true

require "test_helper"

# #77 [TDD][RED] SubscriptionOfferEligibility.check(customer, point)
class Shop::SubscriptionOfferEligibilityTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(email: "elig-#{SecureRandom.hex(4)}@example.com")
    @settings = SubscriptionOfferSetting.create!(
      point_id: @tenant.id,
      enabled: true,
      second_cta_mode: "subscription",
      min_completed_orders: 1,
      required_signals_count: 1
    )
  end

  def create_order!(status:)
    Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "77-#{SecureRandom.hex(3)}",
      source: :mobile,
      status: status,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
  end

  test "false when settings missing or disabled" do
    @settings.destroy!
    assert_equal false, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)

    @settings = SubscriptionOfferSetting.create!(
      point_id: @tenant.id, enabled: false, second_cta_mode: "subscription",
      min_completed_orders: 1, required_signals_count: 1
    )
    create_order!(status: :issued)
    @customer.update!(pwa_installed_at: Time.current)
    assert_equal false, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)
  end

  test "true with one completed order and any one engagement signal" do
    create_order!(status: :issued)
    create_order!(status: :pending_payment)
    create_order!(status: :cancelled)

    @customer.update!(pwa_installed_at: Time.current)
    assert_equal true, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)

    @customer.update!(pwa_installed_at: nil, push_enabled_at: Time.current)
    assert_equal true, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)

    @customer.update!(push_enabled_at: nil, email_collected_at: Time.current)
    assert_equal true, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)
  end

  test "false when required_signals_count is 2 and only one signal" do
    @settings.update!(required_signals_count: 2)
    create_order!(status: :closed)
    @customer.update!(pwa_installed_at: Time.current)

    assert_equal false, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)

    @customer.update!(push_enabled_at: Time.current)
    assert_equal true, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)
  end

  test "false when min_completed_orders not met" do
    @settings.update!(min_completed_orders: 2)
    create_order!(status: :issued)
    @customer.update!(email_collected_at: Time.current)

    assert_equal false, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)

    create_order!(status: :closed)
    assert_equal true, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)
  end

  test "completed_orders_count ignores non-terminal statuses" do
    create_order!(status: :accepted)
    create_order!(status: :preparing)
    create_order!(status: :ready)
    create_order!(status: :pending_payment)
    @customer.update!(pwa_installed_at: Time.current)

    assert_equal false, Shop::SubscriptionOfferEligibility.check(@customer, @tenant)
  end
end
