# frozen_string_literal: true

require "test_helper"

# TASK_117 — confirm/decline SMS session transition API [TDD]
class Shop::Api::SmsSessionTransitionTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!(slug: "sms-api-#{SecureRandom.hex(3)}")
    @owner = create_mobile_customer!(phone: "+79001170101", email: "api-owner-#{SecureRandom.hex(3)}@example.com")
    @other = create_mobile_customer!(phone: "+79001170102", email: "api-other-#{SecureRandom.hex(3)}@example.com")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @owner.id,
      customer_name: "Owner",
      order_number: "SMS-API-1",
      source: :mobile,
      status: :ready,
      total_amount: 120,
      discount_amount: 0,
      final_amount: 120,
      ready_at: Time.current,
      ready_notified_at: Time.current
    )
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 120)
  end

  test "POST sms_transition confirms: binds owner and clears cart" do
    open_session do |sess|
      headers = shop_tenant_headers(@tenant.id)
      Shop::CustomerSession.set_customer_id!(sess.request.session, @tenant.id, @other.id)

      sess.post "/shop/api/cart/add",
        headers: headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      token = Shop::SmsSessionTransition.pending_token_for(@order)
      sess.post "/shop/api/session/sms_transition",
        headers: headers,
        params: { token: token },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal true, body["ok"]
      assert_equal @order.id, body["order_id"]

      assert_equal @owner.id.to_s, Shop::CustomerSession.customer_id(sess.request.session, @tenant.id)

      sess.get "/shop/api/cart", headers: headers, as: :json
      assert_equal 200, sess.response.status
      cart = sess.response.parsed_body
      items = cart["items"] || cart["cart"] || []
      assert_empty items
    end
  end

  test "DELETE sms_transition declines without changing session or cart" do
    open_session do |sess|
      headers = shop_tenant_headers(@tenant.id)
      Shop::CustomerSession.set_customer_id!(sess.request.session, @tenant.id, @other.id)

      sess.post "/shop/api/cart/add",
        headers: headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      token = Shop::SmsSessionTransition.pending_token_for(@order)
      sess.delete "/shop/api/session/sms_transition",
        headers: headers,
        params: { token: token },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      assert_equal @other.id.to_s, Shop::CustomerSession.customer_id(sess.request.session, @tenant.id)
      sess.get "/shop/api/cart", headers: headers, as: :json
      items = sess.response.parsed_body["items"] || sess.response.parsed_body["cart"] || []
      assert_equal 1, items.size
    end
  end

  test "second pending confirm while first unfinished: only one bind (last issued token wins)" do
    open_session do |sess|
      headers = shop_tenant_headers(@tenant.id)
      Shop::CustomerSession.set_customer_id!(sess.request.session, @tenant.id, @other.id)

      order_b = Order.create!(
        tenant_id: @tenant.id,
        customer_id: @owner.id,
        customer_name: "Owner",
        order_number: "SMS-API-2",
        source: :mobile,
        status: :ready,
        total_amount: 99,
        discount_amount: 0,
        final_amount: 99,
        ready_at: Time.current,
        ready_notified_at: Time.current
      )

      t1 = Shop::SmsSessionTransition.pending_token_for(@order)
      t2 = Shop::SmsSessionTransition.pending_token_for(order_b)

      sess.post "/shop/api/session/sms_transition",
        headers: headers, params: { token: t2 }, as: :json
      assert_equal 200, sess.response.status
      assert_equal order_b.id, sess.response.parsed_body["order_id"]

      # Первая (устаревшая) ссылка после успешного confirm второй — отклоняется или no-op без отката.
      sess.post "/shop/api/session/sms_transition",
        headers: headers, params: { token: t1 }, as: :json
      assert_includes [200, 422], sess.response.status
      assert_equal @owner.id.to_s, Shop::CustomerSession.customer_id(sess.request.session, @tenant.id)
    end
  end
end
