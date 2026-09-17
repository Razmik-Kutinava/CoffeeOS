# frozen_string_literal: true

require "test_helper"

# #82 Патч_1 — GET /o/:order_hash → shop order deep link + guest session bind
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
      final_amount: 100
    )
  end

  test "#82 P1 /o/:hash redirects with reconnect_token and binds guest session" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    get "/o/#{hash}"
    assert_response :redirect
    assert_match %r{/shop\?tenant_id=#{@tenant.id}&reconnect_token=}, response.redirect_url
    assert_match %r{#/order/#{@order.id}\z}, response.redirect_url
    assert_equal @customer.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id).to_s
  end

  test "#82 P1 unknown hash returns 404" do
    get "/o/zzzzzzzzzzzzzzzzzzzzzz"
    assert_response :not_found
  end
end
