# frozen_string_literal: true

require "test_helper"

# TASK_101: «Итого» в шторке способов оплаты = серверный total корзины = Amount Т-Банка / 100.
# node --test test/javascript/payment_methods_order_total_test.mjs — UI-часть.
class Shop::Api::CartTotalAmountTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "t101-#{SecureRandom.hex(3)}")
    category = create_category!(slug: "t101-cat-#{SecureRandom.hex(3)}")
    @coffee = create_product!(category: category, slug: "t101-coffee-#{SecureRandom.hex(3)}", name: "Капучино")
    enable_product_for_tenant!(tenant: @tenant, product: @coffee, price: 250)
    group = ProductModifierGroup.create!(product: @coffee, name: "Размер", is_required: true, sort_order: 1)
    @size_l = ProductModifierOption.create!(group: group, name: "L", price_delta: 40, sort_order: 1)

    @cake = create_product!(category: category, slug: "t101-cake-#{SecureRandom.hex(3)}", name: "Чизкейк")
    enable_product_for_tenant!(tenant: @tenant, product: @cake, price: 179)

    @headers = shop_tenant_headers(@tenant.id)
    @email = "t101-#{SecureRandom.hex(4)}@example.com"
    @prev_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  teardown do
    ENV["SHOP_SIMULATE_PAYMENT"] = @prev_simulate
  end

  def fill_cart!
    post "/shop/api/cart/add",
      headers: @headers,
      params: { product_id: @coffee.id, quantity: 2, selected_modifiers: [ { id: @size_l.id, name: "L", price: 40.0 } ] },
      as: :json
    assert_response :success
    post "/shop/api/cart/add",
      headers: @headers,
      params: { product_id: @cake.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success
  end

  def cart_total
    get "/shop/api/cart", headers: @headers, as: :json
    assert_response :success
    response.parsed_body["total"]
  end

  test "Subtask 1–2, 9: GET /shop/api/cart total учитывает количество и доплату модификатора" do
    fill_cart!
    # (250 + 40) × 2 + 179 × 1
    assert_in_delta 759.0, cart_total.to_f, 0.001
  end

  test "Subtask 2: total обновляется после + / − / удаления строки" do
    fill_cart!
    patch "/shop/api/cart/items/1", headers: @headers, params: { delta: 1 }, as: :json
    assert_in_delta 938.0, response.parsed_body["total"].to_f, 0.001

    patch "/shop/api/cart/items/0", headers: @headers, params: { delta: -1 }, as: :json
    assert_in_delta 648.0, response.parsed_body["total"].to_f, 0.001

    delete "/shop/api/cart/items/0", headers: @headers, as: :json
    assert_in_delta 358.0, response.parsed_body["total"].to_f, 0.001
  end

  test "Subtask 3, 9: total корзины = order.final_amount = Amount Т-Банка в копейках (без акции привязки)" do
    fill_cart!
    total = cart_total
    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: @headers,
      params: shop_order_params(email: @email, payment_method: "card"),
      as: :json
    assert_response :success, response.body
    order = Order.find(response.parsed_body["order_id"])
    assert_equal BigDecimal(total.to_s), order.final_amount

    prev_key = ENV["TBANK_TERMINAL_KEY"]
    prev_password = ENV["TBANK_PASSWORD"]
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    adapter = Payments::TbankAdapter.new
    captured = nil
    adapter.define_singleton_method(:post_json) do |_url, payload|
      captured = payload
      { "Success" => true, "PaymentId" => "t101-1", "PaymentURL" => "https://securepay.tinkoff.ru/t101" }
    end
    adapter.init_payment(order: order, return_base_url: "https://shop.example", notification_url: "https://shop.example/cb")

    assert_equal 75_900, captured["Amount"]
    assert_equal (BigDecimal(total.to_s) * 100).to_i, captured["Amount"]
  ensure
    ENV["TBANK_TERMINAL_KEY"] = prev_key
    ENV["TBANK_PASSWORD"] = prev_password
  end
end
