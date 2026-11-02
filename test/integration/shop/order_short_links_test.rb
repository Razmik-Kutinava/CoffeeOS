# frozen_string_literal: true

require "test_helper"

# TASK_93-C — GET /o/:order_hash → bind + TTL + forge 404
class Shop::OrderShortLinksTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!(slug: "o-link-#{SecureRandom.hex(3)}")
    @customer = create_mobile_customer!(
      phone: "+79008200001",
      email: "olink-#{SecureRandom.hex(3)}@example.com"
    )
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Short",
      order_number: "202609-8202",
      source: :mobile,
      status: :ready,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100,
      ready_at: Time.current,
      ready_notified_at: Time.current
    )
  end

  test "TASK_118 /o/:hash binds and redirects to profile history with sms_entry (no reconnect_token)" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    get "/o/#{hash}", headers: { "HOST" => "www.example.com" }
    assert_response :redirect
    assert_match %r{/shop\?tenant_id=#{@tenant.id}}, response.redirect_url
    assert_match(/sms_entry=1/, response.redirect_url)
    refute_match(/reconnect_token=/, response.redirect_url)
    refute_match(/sms_transition=/, response.redirect_url)
    assert_match %r{#/profile\?order=#{@order.id}\z}, response.redirect_url
    assert_equal @customer.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id).to_s
  end

  test "TASK_118 S7 reopening valid link repeats bind + profile redirect" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    2.times do
      get "/o/#{hash}", headers: { "HOST" => "www.example.com" }
      assert_response :redirect
      assert_match %r{#/profile\?order=#{@order.id}\z}, response.redirect_url
      assert_match(/sms_entry=1/, response.redirect_url)
    end
    assert_equal @customer.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id).to_s
  end

  test "TASK_117 conflict: other customer in session → sms_transition, no bind" do
    other = create_mobile_customer!(
      phone: "+79008200999",
      email: "olink-other-#{SecureRandom.hex(3)}@example.com"
    )
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: other.email, session: sess)
      assert_equal other.id.to_s, Shop::CustomerSession.customer_id(sess.session, @tenant.id)

      hash = Shop::OrderReadySmsLink.hash_for(@order)
      sess.get "/o/#{hash}", headers: { "HOST" => "www.example.com" }
      assert_equal 302, sess.response.status, sess.response.body
      assert_match %r{/shop\?tenant_id=#{@tenant.id}}, sess.response.redirect_url
      assert_match(/sms_transition=/, sess.response.redirect_url)
      assert_match(/sms_entry=1/, sess.response.redirect_url)
      refute_match(/reconnect_token=/, sess.response.redirect_url)
      assert_equal other.id.to_s, Shop::CustomerSession.customer_id(sess.session, @tenant.id).to_s
    end
  end

  test "TASK_117 same customer: bind without confirm token" do
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @customer.email, session: sess)
      hash = Shop::OrderReadySmsLink.hash_for(@order)
      sess.get "/o/#{hash}", headers: { "HOST" => "www.example.com" }
      assert_equal 302, sess.response.status
      refute_match(/sms_transition=/, sess.response.redirect_url)
      assert_match %r{#/profile\?order=#{@order.id}\z}, sess.response.redirect_url
      assert_equal @customer.id.to_s, Shop::CustomerSession.customer_id(sess.session, @tenant.id).to_s
    end
  end

  test "T-C2c /o/ not blocked for allowed host" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    get "/o/#{hash}", headers: { "HOST" => "coffeeos.fly.dev" }
    assert_response :redirect
    refute_equal 403, response.status
  end

  test "TASK_118 invalid hash shows «Ссылка недействительна» without bind" do
    get "/o/zzzzzzzzzzzzzzzzzzzzzz"
    assert_response :ok
    assert_includes response.body, "Ссылка недействительна"
    refute_includes response.body, "Ссылка устарела"
    assert_nil Shop::CustomerSession.customer_id(session, @tenant.id)
  end

  test "TASK_118 forged MAC shows «Ссылка недействительна» without bind" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    raw = Base64.urlsafe_decode64(hash)
    forged_raw = raw.byteslice(0, 16) + raw.byteslice(16, 4).bytes.map { |b| b ^ 0xff }.pack("C*")
    forged = Base64.urlsafe_encode64(forged_raw, padding: false)
    get "/o/#{forged}"
    assert_response :ok
    assert_includes response.body, "Ссылка недействительна"
    assert_nil Shop::CustomerSession.customer_id(session, @tenant.id)
  end

  test "TASK_118 expired link shows «Ссылка устарела» with CTA, without bind" do
    @order.update!(
      ready_notified_at: 49.hours.ago,
      ready_at: 49.hours.ago,
      updated_at: 49.hours.ago
    )
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    get "/o/#{hash}"
    assert_response :ok
    assert_includes response.body, "Ссылка устарела"
    assert_includes response.body, "Открыть мои заказы"
    assert_includes response.body, "/shop#/profile"
    refute_includes response.body, @order.id.to_s
    assert_nil Shop::CustomerSession.customer_id(session, @tenant.id)
  end
end
