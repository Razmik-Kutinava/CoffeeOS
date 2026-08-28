# frozen_string_literal: true

require "test_helper"

# #69 PWA ЛК — runtime API (не grep)
class Shop::Api::PwaLkApiTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!(slug: "pwa-lk-#{SecureRandom.hex(3)}")
    @category = create_category!
    @product = create_product!(category: @category, name: "Капучино LK")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 250)
    @email = "pwa-lk-#{SecureRandom.hex(4)}@example.com"
  end

  test "GET orders history returns order_number and title for LK list" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "LK Guest", payment_method: "card"),
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      sess.get "/shop/api/orders/history",
        headers: shop_tenant_headers(@tenant.id),
        params: { today: 1 }
      assert_equal 200, sess.response.status, sess.response.body

      rows = sess.response.parsed_body
      assert rows.length >= 1
      row = rows.first
      assert row["order_number"].present?, "history must include order_number for LK"
      assert_equal @product.name, row["title"], "history title must be first product name"
      assert row["created_at"].present?
      assert row["items_count"].to_i >= 1
    end
  end

  test "DELETE session clears customer and profile returns 401" do
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      refresh_token = sess.response.parsed_body["refresh_token"]
      assert refresh_token.present?

      sess.get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 200, sess.response.status

      sess.delete "/shop/api/session",
        headers: shop_tenant_headers(@tenant.id),
        params: { refresh_token: refresh_token },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal true, body["ok"]
      assert_equal true, body["logged_out"], "logout contract must expose logged_out for LK"

      sess.get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 401, sess.response.status

      sess.get "/shop/api/orders/history",
        headers: shop_tenant_headers(@tenant.id),
        params: { today: 1 }
      assert_equal 200, sess.response.status
      assert_empty sess.response.parsed_body

      ms = MobileSession.find_by(refresh_token: refresh_token)
      assert ms, "MobileSession expected"
      assert_equal false, ms.is_active
    end
  end

  test "DELETE session clears pending order so show does not re-bind customer" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "LK Guest", payment_method: "card"),
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      order_id = sess.response.parsed_body["order_id"]

      refresh_token = sess.response.parsed_body["refresh_token"] ||
        MobileSession.where(customer_id: MobileCustomer.find_by!(email: @email).id).order(created_at: :desc).first&.refresh_token
      refresh_token ||= begin
        verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
        sess.response.parsed_body["refresh_token"]
      end

      sess.delete "/shop/api/session",
        headers: shop_tenant_headers(@tenant.id),
        params: { refresh_token: refresh_token },
        as: :json
      assert_equal 200, sess.response.status

      sess.get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 401, sess.response.status

      sess.get "/shop/api/orders/#{order_id}", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 404, sess.response.status

      sess.get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 401, sess.response.status
    end
  end
end
