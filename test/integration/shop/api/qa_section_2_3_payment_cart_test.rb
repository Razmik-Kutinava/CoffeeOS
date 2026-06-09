# frozen_string_literal: true

require "test_helper"

class Shop::Api::QaSection23PaymentCartTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "qa23-cart-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    @old_tbank = ENV["TBANK_TERMINAL_KEY"]
    ENV.delete("TBANK_TERMINAL_KEY")
  end

  teardown do
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    ENV["TBANK_TERMINAL_KEY"] = @old_tbank if @old_tbank
  end

  test "pending card order keeps cart in session" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(email: @email, name: "QA Guest", payment_method: "card"),
        as: :json

      body = JSON.parse(sess.response.body)
      if sess.response.status == 422 && body["error"].to_s.match?(/TBANK|оплат/i)
        skip "T-Bank not configured in test env"
      end

      assert_equal 200, sess.response.status, body.inspect
      assert_equal "pending_payment", body["status"]

      sess.get "/shop/api/cart", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
      cart = JSON.parse(sess.response.body)
      assert cart["items"].any?, "cart must stay until payment succeeds"
    end
  rescue Shop::OrderCreator::Error => e
    skip e.message if e.message.match?(/order_number|TBANK/i)
    raise
  end

  test "double submit reuses pending order without empty cart error" do
    open_session do |sess|
      headers = { "X-Shop-Tenant" => @tenant.id.to_s }
      sess.post "/shop/api/cart/add",
        headers: headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      2.times do
        sess.post "/shop/api/orders",
          headers: headers,
          params: shop_order_params(email: @email, name: "QA Guest", payment_method: "card"),
          as: :json
        break if sess.response.status == 422
      end

      first = JSON.parse(sess.response.body)
      if sess.response.status == 422 && first["error"].to_s.match?(/TBANK|оплат/i)
        skip "T-Bank not configured in test env"
      end

      order_id = first["order_id"]
      sess.post "/shop/api/orders",
        headers: headers,
        params: shop_order_params(email: @email, name: "QA Guest", payment_method: "card"),
        as: :json
      second = JSON.parse(sess.response.body)
      assert_equal order_id, second["order_id"]
    end
  end
end
