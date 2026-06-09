# frozen_string_literal: true

require "test_helper"

class Shop::Api::GuestOrderReconnectFlowTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "reconnect-#{SecureRandom.hex(4)}@example.com"
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

  test "reconnect restores guest session and history shows pending order" do
    open_session do |sess|
      headers = { "X-Shop-Tenant" => @tenant.id.to_s }

      sess.post "/shop/api/cart/add",
        headers: headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: headers,
        params: shop_order_params(email: @email, name: "Reconnect QA", payment_method: "card"),
        as: :json

      body = JSON.parse(sess.response.body)
      if sess.response.status == 422 && body["error"].to_s.match?(/TBANK|оплат/i)
        skip "T-Bank not configured in test env"
      end

      assert_equal 200, sess.response.status, body.inspect
      assert body["reconnect_token"].present?

      # Имитация «потерянной» сессии гостя после банка
      sess.reset!

      sess.post "/shop/api/session/reconnect",
        headers: headers,
        params: { order_id: body["order_id"], reconnect_token: body["reconnect_token"] },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      sess.get "/shop/api/orders/history",
        headers: headers,
        params: { today: 1 },
        as: :json
      history = JSON.parse(sess.response.body)
      assert history.any? { |row| row["id"] == body["order_id"] }
      assert_equal "pending_payment", history.find { |row| row["id"] == body["order_id"] }["status"]
    end
  end
end
