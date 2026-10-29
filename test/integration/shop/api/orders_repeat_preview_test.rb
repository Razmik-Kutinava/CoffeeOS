# frozen_string_literal: true

require "test_helper"

# TASK_121 Subtask 1, 10: GET /shop/api/orders/:id/repeat_preview — только владелец,
# корзина и cookie-сессия гостя не меняются, общий лимит shop API.
class Shop::Api::OrdersRepeatPreviewTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper
  include RackAttackTestHelper

  SESSION_COOKIE = "_coffeeos_session"

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category, name: "Латте")
    @setting = enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
    @email = "repeat-preview-#{SecureRandom.hex(4)}@example.com"
  end

  def headers(tenant = @tenant)
    shop_tenant_headers(tenant.id)
  end

  def place_order!(sess, email: @email, tenant: @tenant)
    sess.post "/shop/api/cart/add", headers: headers(tenant),
      params: { product_id: @product.id, quantity: 2, selected_modifiers: [] }, as: :json
    assert_equal 200, sess.response.status, sess.response.body
    verify_shop_email!(tenant_id: tenant.id, email: email, session: sess)
    sess.post "/shop/api/orders", headers: headers(tenant),
      params: shop_order_params(email: email, name: "Guest", payment_method: "card"), as: :json
    assert_equal 200, sess.response.status, sess.response.body
    sess.response.parsed_body
  end

  def session_cookie_written?(sess)
    Array(sess.response.headers["set-cookie"]).join("\n").include?("#{SESSION_COOKIE}=")
  end

  test "owner gets current prices of the order lines in this point" do
    open_session do |sess|
      order_id = place_order!(sess)["order_id"]
      @setting.update!(price: 230)

      sess.get "/shop/api/orders/#{order_id}/repeat_preview", headers: headers
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body

      assert_equal order_id, body["order_id"]
      assert_equal 1, body["items"].size
      line = body["items"].first
      assert_equal @product.id, line["product_id"]
      assert_equal 2, line["quantity"]
      assert_equal 200.0, line["price"]
      assert_equal 230.0, line["unit_total"]
      assert_equal 460.0, line["line_total"]
      assert_equal false, line["unavailable"]
      assert_equal 460.0, body["total"]
      assert_equal 400.0, body["previous_total"]
      assert_equal 0.0, body["previous_discount"]
    end
  end

  test "preview does not touch guest cart and does not rewrite session cookie" do
    open_session do |sess|
      order_id = place_order!(sess)["order_id"]
      sess.post "/shop/api/cart/add", headers: headers,
        params: { product_id: @product.id, quantity: 3, selected_modifiers: [] }, as: :json
      sess.get "/shop/api/cart", headers: headers
      cart_before = sess.response.parsed_body

      sess.get "/shop/api/orders/#{order_id}/repeat_preview", headers: headers
      assert_equal 200, sess.response.status
      refute session_cookie_written?(sess), "превью не пишет cookie-сессию"

      sess.get "/shop/api/cart", headers: headers
      assert_equal cart_before["items"].map { |i| [ i["product_id"], i["quantity"] ] },
                   sess.response.parsed_body["items"].map { |i| [ i["product_id"], i["quantity"] ] }
    end
  end

  test "without customer session → 401 without order data" do
    order_id = nil
    open_session { |sess| order_id = place_order!(sess)["order_id"] }

    open_session do |other|
      other.get "/shop/api/orders/#{order_id}/repeat_preview", headers: headers
      assert_equal 401, other.response.status
      refute_includes other.response.body, "unit_total"
    end
  end

  test "reconnect_token does not open preview and does not bind session" do
    created = nil
    open_session { |sess| created = place_order!(sess) }

    open_session do |lost|
      lost.get "/shop/api/orders/#{created['order_id']}/repeat_preview", headers: headers,
        params: { reconnect_token: created["reconnect_token"] }
      assert_equal 401, lost.response.status
      refute session_cookie_written?(lost)
    end
  end

  test "another guest of the same point → 404 without order data" do
    order_id = nil
    open_session { |sess| order_id = place_order!(sess)["order_id"] }

    open_session do |other|
      verify_shop_email!(tenant_id: @tenant.id, email: "other-#{SecureRandom.hex(4)}@example.com", session: other)
      other.get "/shop/api/orders/#{order_id}/repeat_preview", headers: headers
      assert_equal 404, other.response.status
      refute_includes other.response.body, "unit_total"
      refute_includes other.response.body, @product.name
    end
  end

  test "order of another point is not visible from this point → 404" do
    tenant_b = create_tenant!(name: "Shop B", slug: "shop-b-#{SecureRandom.hex(4)}")
    enable_product_for_tenant!(tenant: tenant_b, product: @product, price: 210)

    open_session do |sess|
      order_id = place_order!(sess)["order_id"]
      verify_shop_email!(tenant_id: tenant_b.id, email: @email, session: sess)

      sess.get "/shop/api/orders/#{order_id}/repeat_preview", headers: headers(tenant_b)
      assert_equal 404, sess.response.status
      refute_includes sess.response.body, "unit_total"
    end
  end

  test "preview path is under the same shop API rate limit as the cart" do
    throttle = Rack::Attack.throttles.fetch("shop/api")
    preview_req = Rack::Attack::Request.new(
      Rack::MockRequest.env_for("/shop/api/orders/#{SecureRandom.uuid}/repeat_preview", "REMOTE_ADDR" => "203.0.113.121")
    )
    cart_req = Rack::Attack::Request.new(
      Rack::MockRequest.env_for("/shop/api/cart", "REMOTE_ADDR" => "203.0.113.121")
    )

    assert_equal "203.0.113.121", throttle.block.call(preview_req)
    assert_equal throttle.block.call(cart_req), throttle.block.call(preview_req)
  end
end
