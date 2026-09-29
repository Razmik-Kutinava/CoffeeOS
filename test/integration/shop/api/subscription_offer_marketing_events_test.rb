# frozen_string_literal: true

require "test_helper"

# TASK_96 [TDD][RED] Subtask 23–26, 30: события воронки из Shop API оффера
class Shop::Api::SubscriptionOfferMarketingEventsTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    @email = "somev-#{SecureRandom.hex(4)}@example.com"
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
      order_number: "96-ev-#{SecureRandom.hex(2)}",
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

  def events(type)
    MarketingEvent.where(customer_id: @customer.id, event_type: type)
  end

  def with_stub(klass, method_name, impl)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, &impl)
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end

  test "shown → one banner_shown with current point_id; repeat shown adds nothing" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
      assert_equal 200, sess.response.status, sess.response.body
      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
    end

    assert_equal 1, events("banner_shown").count
    event = events("banner_shown").first
    assert_equal @tenant.id, event.point_id
    assert_equal "banner", event.channel
  end

  test "dismiss → banner_dismissed" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
      sess.post "/shop/api/subscription_offer/dismiss", headers: headers, as: :json
      assert_equal 200, sess.response.status
    end

    event = events("banner_dismissed").first
    assert event
    assert_equal @tenant.id, event.point_id
    assert_equal "banner", event.channel
  end

  test "viewed → lk_viewed" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json
      sess.post "/shop/api/subscription_offer/viewed", headers: headers, as: :json
      assert_equal 200, sess.response.status
    end

    event = events("lk_viewed").first
    assert event
    assert_equal "lk", event.channel
  end

  %w[banner lk].each do |channel|
    test "opened from #{channel} → offer_opened with channel and utm" do
      open_session do |sess|
        login!(sess)
        sess.post "/shop/api/subscription_offer/opened",
          headers: headers,
          params: { channel: channel, utm_campaign: "subscription_offer", utm_content: "#{channel}_v1" },
          as: :json
        assert_equal 204, sess.response.status, sess.response.body
      end

      event = events("offer_opened").first
      assert event
      assert_equal channel, event.channel
      assert_equal "subscription_offer", event.utm_campaign
      assert_equal "#{channel}_v1", event.utm_content
      assert_equal @tenant.id, event.point_id
    end
  end

  test "opened from push → push_opened with push_notification_id in metadata" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/opened",
        headers: headers,
        params: { channel: "push", utm_campaign: "subscription_offer", utm_content: "push_v1",
                  push_notification_id: "pn-123" },
        as: :json
      assert_equal 204, sess.response.status
    end

    event = events("push_opened").first
    assert event
    assert_equal "push", event.channel
    assert_equal "pn-123", event.metadata["push_notification_id"]
    assert_equal 0, events("offer_opened").count
  end

  test "opened with sendBeacon-style text/plain JSON body is accepted" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/opened?tenant_id=#{@tenant.id}",
        headers: headers.merge("CONTENT_TYPE" => "text/plain;charset=UTF-8"),
        params: { channel: "banner", utm_campaign: "subscription_offer", utm_content: "banner_v1" }.to_json
      assert_equal 204, sess.response.status, sess.response.body
    end

    assert_equal 1, events("offer_opened").count
  end

  test "opened with unknown channel → 422, no event" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/opened", headers: headers, params: { channel: "email" }, as: :json
      assert_equal 422, sess.response.status
    end
    assert_equal 0, MarketingEvent.where(customer_id: @customer.id).count
  end

  test "opened without session → 401, no event" do
    post "/shop/api/subscription_offer/opened", headers: headers, params: { channel: "banner" }, as: :json
    assert_response :unauthorized
    assert_equal 0, MarketingEvent.count
  end

  test "event logging failure does not break dismiss" do
    open_session do |sess|
      login!(sess)
      sess.post "/shop/api/subscription_offer/shown", headers: headers, as: :json

      with_stub(MarketingEvent, :create!, ->(*_a, **_k) { raise ActiveRecord::StatementInvalid, "boom" }) do
        sess.post "/shop/api/subscription_offer/dismiss", headers: headers, as: :json
      end
      assert_equal 200, sess.response.status
    end

    assert_equal "dismissed", SubscriptionOfferState.find_by(customer_id: @customer.id).status
  end
end
