# frozen_string_literal: true

require "test_helper"

# TASK_95 [TDD][RED] Subtask 23–24: полный lifecycle оффера + приоритет промо 11₽
class Shop::SubscriptionOfferLifecycleTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    @email = "soslc-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    SubscriptionOfferSetting.create!(
      point_id: @tenant.id,
      enabled: true,
      second_cta_mode: "subscription",
      min_completed_orders: 1,
      required_signals_count: 1
    )
    create_order!(status: :issued)
    @customer.update!(pwa_installed_at: Time.current)
  end

  teardown { Current.reset }

  def headers
    shop_tenant_headers(@tenant.id)
  end

  def create_order!(status:)
    Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "95-lc-#{SecureRandom.hex(3)}",
      source: :mobile,
      status: status,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
  end

  def profile(sess)
    sess.get "/shop/api/profile", headers: headers, as: :json
    assert_equal 200, sess.response.status, sess.response.body
    sess.response.parsed_body
  end

  def state_status
    SubscriptionOfferState.find_by(customer_id: @customer.id)&.status || "not_shown"
  end

  def assert_step(sess, status:, banner:, unread:)
    body = profile(sess)
    assert_equal status, state_status, "status"
    assert_equal banner, body["should_show_banner"], "should_show_banner at #{status}"
    assert_equal unread, body["has_unread_offer_in_lk"], "has_unread_offer_in_lk at #{status}"
  end

  def fulfill_subscription_purchase!
    Current.tenant_id = @tenant.id
    plan = SubscriptionPlan.create!(
      code: "lc_weekly_#{SecureRandom.hex(2)}", price: 99, currency: "RUB", period_days: 7,
      drink_limit: 5, discount_price_per_drink: 119, over_limit_discount_percent: 20, active: true
    )
    order = create_order!(status: :closed)
    payment = Payment.create!(
      tenant_id: @tenant.id,
      order_id: order.id,
      amount: 99,
      method: :card,
      status: :succeeded,
      provider: "tbank",
      provider_payment_id: "pid-95-lc-#{SecureRandom.hex(2)}",
      provider_data: { "subscription_intent" => true, "subscription_plan_id" => plan.id }
    )
    Subscriptions::PaymentFulfillment.call(payment: payment)
  end

  test "full lifecycle: show → dismiss → 3 orders → re-show → viewed → purchased" do
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      assert_step(sess, status: "not_shown", banner: true, unread: false)

      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
      assert_step(sess, status: "shown", banner: false, unread: true)

      sess.post "/shop/api/subscription_offer/dismiss", headers: headers, as: :json
      assert_step(sess, status: "dismissed", banner: false, unread: true)

      2.times { create_order!(status: :issued) }
      assert_step(sess, status: "dismissed", banner: false, unread: true)

      create_order!(status: :issued)
      assert_step(sess, status: "dismissed", banner: true, unread: true)

      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
      assert_step(sess, status: "shown", banner: false, unread: true)

      sess.post "/shop/api/subscription_offer/viewed", headers: headers, as: :json
      assert_step(sess, status: "viewed_in_lk", banner: false, unread: false)

      subscription = fulfill_subscription_purchase!
      assert subscription.persisted?
      assert_step(sess, status: "purchased", banner: false, unread: false)

      # webhook replay — идемпотентно, статус остаётся purchased
      Subscriptions::PaymentFulfillment.call(payment: Payment.find(subscription.payment_id))
      assert_step(sess, status: "purchased", banner: false, unread: false)
    end
  end

  test "promo 11₽ priority: no banner and no shown while promo available" do
    PointCampaignSetting.create!(
      point_id: @tenant.id,
      campaign_type: PointCampaignSetting::CAMPAIGN_CARD_BINDING_PROMO,
      enabled: true,
      threshold: 1000,
      counter: 0,
      config: { "promo_amount_rub" => 11 }
    )

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      3.times do
        create_order!(status: :issued)
        assert_step(sess, status: "not_shown", banner: false, unread: false)
        sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
        assert_equal "not_shown", state_status
      end

      Payments::GrowthPromo.mark_used!(
        phone: @customer.phone, method_hash: "hash-95-lc", method_type: "card",
        customer_id: @customer.id, tenant_id: @tenant.id
      )
      assert_step(sess, status: "not_shown", banner: true, unread: false)
    end
  end
end
