# frozen_string_literal: true

require "test_helper"

class ManagerOrdersShowTest < ActionDispatch::IntegrationTest
  test "office manager can open order show without OrderItem product association" do
    tenant = create_tenant!(name: "TOrdShow", slug: "tordshow")
    office = create_user!(tenant: tenant, role_codes: %w[general_manager], email: "office-ord-show@test.com", name: "OfficeOrdShow")
    product, = create_product_fixture!(tenant: tenant)

    order = Order.create!(
      tenant: tenant,
      order_number: "ORD-SHOW-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 2,
      unit_price: 50,
      total_price: 100
    )

    login_as!(office)
    get "/manager/orders/#{order.id}"

    assert_response :success
    assert_includes response.body, product.name
    assert_includes response.body, "2×"
  end

  private

  def create_product_fixture!(tenant:)
    category = create_category!(name: "Кат-#{SecureRandom.hex(3)}")
    product = create_product!(category: category, name: "Пр-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: tenant, product: product, price: 100, is_sold_out: false, is_enabled: true)
    [ product, category ]
  end
end
