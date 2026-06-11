# frozen_string_literal: true

require "test_helper"

class Shop::Api::RemovedModifiersCheckoutTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category, name: "Латте")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
    @group = ProductModifierGroup.create!(
      product: @product,
      name: "Добавки",
      is_required: false,
      sort_order: 1
    )
    @sugar = ProductModifierOption.create!(
      group: @group,
      name: "Сахар",
      price_delta: 0,
      sort_order: 1
    )
    @syrup = ProductModifierOption.create!(
      group: @group,
      name: "Сироп",
      price_delta: 30,
      sort_order: 2
    )
    @email = "mods-#{SecureRandom.hex(4)}@example.com"
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  test "cart and order persist removed_modifiers for barista board" do
    selected = [{ id: @sugar.id, name: "Сахар", price: 0 }]

    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: selected },
      as: :json
    assert_response :success

    cart = response.parsed_body["cart"]
    assert_equal 1, cart.size
    assert_equal "Сахар", cart.first["selected_modifiers"].first["name"]
    assert_equal "Сироп", cart.first["removed_modifiers"].first["name"]

    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: shop_order_params(email: @email, name: "Mods Guest", payment_method: "cash"),
      as: :json
    assert_response :success, response.body

    order = Order.find(response.parsed_body["order_id"])
    item = order.order_items.first
    assert_equal "Сахар", item.modifier_options["selected_modifiers"].first["name"]
    assert_equal "Сироп", item.modifier_options["removed_modifiers"].first["name"]
  end
end
