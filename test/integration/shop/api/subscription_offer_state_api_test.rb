# frozen_string_literal: true

require "test_helper"

# TASK_95 [TDD][RED] Subtask 18–22: profile flags + shown/dismiss/viewed endpoints
class Shop::Api::SubscriptionOfferStateApiTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    @email = "sosapi-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    SubscriptionOfferSetting.create!(
      point_id: @tenant.id,
      enabled: true,
      second_cta_mode: "subscription",
      min_completed_orders: 1,
      required_signals_count: 1
    )
    Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "95-api-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: :issued,
      total_amount: 50,
      discount_amount: 0,
      final_amount: 50
    )
    @customer.update!(pwa_installed_at: Time.current)
  end

  def headers
    shop_tenant_headers(@tenant.id)
  end

  def login!(sess)
    verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
  end

  def state
    SubscriptionOfferState.find_by(customer_id: @customer.id)
  end

  test "profile exposes should_show_banner and has_unread_offer_in_lk" do
    open_session do |sess|
      login!(sess)
      sess.get "/shop/api/profile", headers: headers, as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal true, body["should_show_banner"]
      assert_equal false, body["has_unread_offer_in_lk"]
      assert_equal true, body["eligible_for_subscription_offer"]
      assert_equal 1, body["orders_count"]
    end
  end

  test "shown → profile banner off, unread on" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
      assert_equal 200, sess.response.status, sess.response.body
      assert_equal "shown", state.status

      sess.get "/shop/api/profile", headers: headers, as: :json
      body = sess.response.parsed_body
      assert_equal false, body["should_show_banner"]
      assert_equal true, body["has_unread_offer_in_lk"]
    end
  end

  test "dismiss marks dismissed; repeat dismiss keeps the same cycle" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
      sess.post "/shop/api/subscription_offer/dismiss", headers: headers, as: :json
      assert_equal 200, sess.response.status, sess.response.body
      assert_equal "dismissed", state.status
      dismissed_at = state.last_dismissed_at

      travel 1.hour do
        sess.post "/shop/api/subscription_offer/dismiss", headers: headers, as: :json
        assert_equal 200, sess.response.status
        assert_equal "dismissed", state.status
        assert_equal dismissed_at.to_i, state.last_dismissed_at.to_i
      end
    end
  end

  test "viewed clears unread and is idempotent" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
      sess.post "/shop/api/subscription_offer/viewed", headers: headers, as: :json
      assert_equal 200, sess.response.status, sess.response.body
      assert_equal false, sess.response.parsed_body["has_unread_offer_in_lk"]

      sess.post "/shop/api/subscription_offer/viewed", headers: headers, as: :json
      assert_equal 200, sess.response.status
      assert_equal "viewed_in_lk", state.status
      assert_nil state.unread_since
    end
  end

  test "customer_id from body is ignored — only session customer changes" do
    other = create_mobile_customer!(email: "other-#{SecureRandom.hex(4)}@example.com")
    SubscriptionOfferState.create!(customer_id: other.id, status: "shown", unread_since: Time.current)

    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/viewed",
        headers: headers, params: { customer_id: other.id }, as: :json
      assert_equal 200, sess.response.status
    end

    other_state = SubscriptionOfferState.find_by(customer_id: other.id)
    assert_equal "shown", other_state.status
    assert other_state.unread_since.present?
  end

  %w[shown dismiss viewed].each do |action|
    test "#{action} without session → 401 and state unchanged" do
      SubscriptionOfferState.create!(customer_id: @customer.id, status: "shown", unread_since: Time.current)
      before = state.attributes

      post "/shop/api/subscription_offer/#{action}", headers: headers, as: :json
      assert_response :unauthorized
      assert_equal before, state.attributes
    end
  end
end
