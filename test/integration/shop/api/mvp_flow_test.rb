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
    @email = "mvp-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
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

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: shop_order_params(email: @email, name: "Shop MVP", payment_method: "card"),
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

  # В2: при SHOP_SIMULATE_PAYMENT=0 и не настроенном шлюзе (тест-среда без TBANK_TERMINAL_KEY)
  # OrderCreator завершается ошибкой с понятным сообщением.
  # Когда ключи настроены — заказ создаётся в pending_payment и API отдаёт payment_url.
  test "card payment returns error when SHOP_SIMULATE_PAYMENT=0 and gateway not configured" do
    old_simulate  = ENV["SHOP_SIMULATE_PAYMENT"]
    old_tbank_key = ENV.delete("TBANK_TERMINAL_KEY")
    old_tbank_pass = ENV.delete("TBANK_PASSWORD")

    ENV["SHOP_SIMULATE_PAYMENT"] = "0"

    post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: shop_order_params(email: @email, name: "V2 mode", payment_method: "card"),
      as: :json

    assert_response :unprocessable_entity
    assert_match(/TBANK_TERMINAL_KEY/i, response.parsed_body["error"].to_s)
  ensure
    ENV["SHOP_SIMULATE_PAYMENT"] = old_simulate
    ENV["TBANK_TERMINAL_KEY"]    = old_tbank_key if old_tbank_key
    ENV["TBANK_PASSWORD"]        = old_tbank_pass if old_tbank_pass
  end
end
