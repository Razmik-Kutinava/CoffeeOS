# frozen_string_literal: true

require "test_helper"

# PDF §2.2 — платные модификаторы на витрине (демо Бразилия).
class QaSection22ModifiersTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "qa-22-#{SecureRandom.hex(3)}")
    cat = create_category!(slug: "qa-22-cat", name: "Черный")
    @product = create_product!(
      category: cat,
      slug: "qa-22-brazil",
      name: "Фильтр-кофе Бразилия"
    )
    @product.update!(base_price: 179)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)

    taste = ProductModifierGroup.create!(product: @product, name: "Вкус", is_required: true, sort_order: 0)
    @cordial = ProductModifierOption.create!(
      group: taste, name: "Пивной кордиал — сладкий", price_delta: 20, sort_order: 1
    )
    sweet = ProductModifierGroup.create!(product: @product, name: "Интенсивность", is_required: true, sort_order: 1)
    @honey = ProductModifierOption.create!(
      group: sweet, name: "Мёд — натуральная сладость", price_delta: 40, sort_order: 1
    )

    @headers = { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  test "§2.2 cart total includes modifier prices 179 + 20 + 40 = 239" do
    mods = [
      { id: @cordial.id, name: @cordial.name, price: 20.0 },
      { id: @honey.id, name: @honey.name, price: 40.0 }
    ]

    post "/shop/api/cart/add",
      headers: @headers,
      params: { product_id: @product.id, quantity: 1, selected_modifiers: mods },
      as: :json
    assert_response :success
    assert_equal 239.0, response.parsed_body["total"]

    get "/shop/api/cart", headers: @headers
    assert_response :success
    line = response.parsed_body["items"].first
    assert_equal 239.0, line["unit_total"]
    assert_equal 239.0, response.parsed_body["total"]
  end

  test "§2.2 order final_amount matches cart with priced modifiers" do
    mods = [ { id: @cordial.id, name: @cordial.name, price: 20.0 } ]

    post "/shop/api/cart/add",
      headers: @headers,
      params: { product_id: @product.id, quantity: 1, selected_modifiers: mods },
      as: :json
    assert_response :success
    assert_equal 199.0, response.parsed_body["total"]

    email = "qa22-#{SecureRandom.hex(4)}@test.local"
    verify_shop_email!(tenant_id: @tenant.id, email: email)

    post "/shop/api/orders",
      headers: @headers,
      params: shop_order_params(email: email, name: "QA 2.2", payment_method: "cash"),
      as: :json
    assert_response :success
    assert_equal 199.0, response.parsed_body["total"]
  end
end
