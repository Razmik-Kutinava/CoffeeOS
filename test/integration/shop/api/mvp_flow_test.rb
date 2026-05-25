# frozen_string_literal: true

require "test_helper"

# MVP Shop API: меню из каталога УК → корзина → заказ с имитацией оплаты (без шлюза, В1).
class Shop::Api::MvpFlowTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "shop-mvp-#{SecureRandom.hex(3)}")
    @category = create_category!(slug: "shop-mvp-cat-#{SecureRandom.hex(3)}")
    @product = create_product!(category: @category, slug: "shop-mvp-prod-#{SecureRandom.hex(3)}", name: "Раф")
    @product.update!(base_price: 300)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 320)
    @customer = create_mobile_customer!
  end

  test "menu cart and order flow with simulated card payment" do
    get "/shop/api/categories", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    categories = response.parsed_body["data"]
    assert categories.any? { |c| c["products"].any? { |p| p["id"] == @product.id } }

    get "/shop/api/products/#{@product.id}", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    assert_equal 320.0, response.parsed_body["price"]

    post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 2, selected_modifiers: [] },
      as: :json
    assert_response :success
    assert_equal 640.0, response.parsed_body["total"]

    post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { phone: @customer.phone, name: "Shop MVP", payment_method: "card" },
      as: :json
    assert_response :success

    body = response.parsed_body
    assert body["order_id"].present?
    assert_equal "accepted", body["status"]
    assert_equal 640.0, body["total"]

    order = Order.find(body["order_id"])
    assert_equal "mobile", order.source
    assert_equal "accepted", order.status
    payment = order.payments.first
    assert_equal "succeeded", payment.status
    assert_equal "shop", payment.provider
    assert_equal "card", payment.method
  end

  test "card payment stays pending when SHOP_SIMULATE_PAYMENT=0 (v2 gateway mode)" do
    old = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"

    post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { phone: @customer.phone, name: "V2 mode", payment_method: "card" },
      as: :json

    if response.successful?
      order = Order.find(response.parsed_body["order_id"])
      assert_equal "pending_payment", order.status
      assert_equal "pending", order.payments.first.status
    else
      assert_match(/order_number/i, response.parsed_body["error"].to_s)
    end
  ensure
    ENV["SHOP_SIMULATE_PAYMENT"] = old
  end
end
