require "test_helper"

class BaristaToManagersFullFlowTest < ActionDispatch::IntegrationTest
  def create_product_fixture!(tenant:, price: 100)
    category = create_category!(name: "CatFF-#{SecureRandom.hex(2)}")
    product = create_product!(category: category, name: "ProdFF-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: tenant, product: product, price: price, is_sold_out: false, is_enabled: true)
    product
  end

  test "barista creates order with promo_code; both managers see it in /manager/orders" do
    tenant = create_tenant!(name: "TFF", slug: "tff")

    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "ff-bar@test.com", name: "FFBar")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "ff-office@test.com", name: "FFOffice")
    shift_manager = create_user!(tenant: tenant, role_codes: %w[shift_manager], email: "ff-mgr@test.com", name: "FFMgr")

    cash_shift = open_cash_shift!(tenant: tenant, opened_by: barista)

    product = create_product_fixture!(tenant: tenant, price: 100)

    before_orders_count = Order.where(tenant: tenant).count
    login_as!(barista)
    post "/barista/orders",
      params: {
        cart_items: [{ "product_id" => product.id, "quantity" => 1 }],
        payment_method: "cash",
        promo_code: "PROMO10"
      }

    assert_response :redirect
    follow_redirect!

    after_orders_count = Order.where(tenant: tenant).count
    assert_equal before_orders_count + 1, after_orders_count, "Order should be created by barista"

    order = Order.where(tenant: tenant).order(created_at: :desc).first
    assert order, "Expected created order"
    assert_equal cash_shift.id, order.cash_shift_id, "Order should be linked to current open cash shift"

    assert_equal "accepted", order.status
    assert_in_delta 0.0, order.discount_amount.to_f, 0.001
    assert_in_delta 100.0, order.final_amount.to_f, 0.001

    # Office manager sees order
    login_as!(office)
    get "/manager/orders"
    assert_response :success
    assert_includes response.body, order.order_number
    assert_includes response.body, order.status
    assert_includes response.body, order.source
    assert_includes response.body, "#{order.final_amount} ₽"

    # Shift manager sees order too (current open cash shift)
    login_as!(shift_manager)
    get "/manager/orders"
    assert_response :success
    assert_includes response.body, order.order_number
  end
end

