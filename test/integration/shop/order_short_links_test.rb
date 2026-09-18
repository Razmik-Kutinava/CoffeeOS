# frozen_string_literal: true

require "test_helper"

# TASK_93-C — GET /o/:order_hash → bind + TTL + forge 404
class Shop::OrderShortLinksTest < ActionDispatch::IntegrationTest
  include TestFactories

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

  test "T-C3a T-C3b T-C5c /o/:hash redirects with reconnect_token and binds guest session" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    get "/o/#{hash}", headers: { "HOST" => "www.example.com" }
    assert_response :redirect
    assert_match %r{/shop\?tenant_id=#{@tenant.id}&reconnect_token=}, response.redirect_url
    assert_match %r{#/order/#{@order.id}\z}, response.redirect_url
    assert_equal @customer.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id).to_s
  end

  test "T-C2c /o/ not blocked for allowed host" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    get "/o/#{hash}", headers: { "HOST" => "coffeeos.fly.dev" }
    assert_response :redirect
    refute_equal 403, response.status
  end

  test "T-C3c unknown hash returns 404 without bind" do
    get "/o/zzzzzzzzzzzzzzzzzzzzzz"
    assert_response :not_found
    assert_nil Shop::CustomerSession.customer_id(session, @tenant.id)
  end

  test "T-C3d forged MAC returns 404 without bind" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    raw = Base64.urlsafe_decode64(hash)
    forged_raw = raw.byteslice(0, 16) + raw.byteslice(16, 4).bytes.map { |b| b ^ 0xff }.pack("C*")
    forged = Base64.urlsafe_encode64(forged_raw, padding: false)
    get "/o/#{forged}"
    assert_response :not_found
    assert_nil Shop::CustomerSession.customer_id(session, @tenant.id)
  end

  test "T-C5a expired token returns 404 without bind" do
    @order.update!(
      ready_notified_at: 49.hours.ago,
      ready_at: 49.hours.ago,
      updated_at: 49.hours.ago
    )
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    get "/o/#{hash}"
    assert_response :not_found
    assert_nil Shop::CustomerSession.customer_id(session, @tenant.id)
  end
end
