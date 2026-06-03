# frozen_string_literal: true

require "test_helper"

# PDF §1.3 — витрина без смены; касса бариста только с открытой сменой.
class Demo::QaSection13ShiftFlowTest < ActionDispatch::IntegrationTest
  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "demo-qa-13-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "Demo Coffee Point A", slug: "demo-a-#{SecureRandom.hex(4)}")
    @tenant_b = create_tenant!(organization: @org, name: "Demo Coffee Point B", slug: "demo-b-#{SecureRandom.hex(4)}")

    category = create_category!
    @product = create_product!(category: category, name: "Фильтр-кофе Бразилия")
    enable_product_for_tenant!(tenant: @tenant_a, product: @product, price: 179)
    enable_product_for_tenant!(tenant: @tenant_b, product: @product, price: 189)
    @customer = create_mobile_customer!

    @barista_a = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "bar-a-#{SecureRandom.hex(3)}@test.local")
    @barista_b = create_user!(tenant: @tenant_b, role_codes: %w[barista], email: "bar-b-#{SecureRandom.hex(3)}@test.local")
    @shift_mgr = create_user!(tenant: @tenant_a, role_codes: %w[shift_manager], email: "shift-#{SecureRandom.hex(3)}@test.local")
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "1.3 shop order without shift then barista open shift sees board order" do
    order_a = shop_place_order!(tenant: @tenant_a)
    order_b = shop_place_order!(tenant: @tenant_b)

    login_as!(@barista_a)
    get barista_dashboard_path
    assert_response :success
    assert_includes response.body, order_a.id
    assert_not_includes response.body, order_b.id

    post barista_open_shift_path, params: { opening_cash: 0 }
    assert_redirected_to barista_dashboard_path
    follow_redirect!
    assert_includes response.body, "Смена открыта"
    assert_includes response.body, order_a.id
  end

  test "1.3 barista cannot create pos order without open shift" do
    login_as!(@barista_a)
    post "/barista/orders", params: { cart_items: [{ product_id: @product.id, quantity: 1 }], payment_method: "cash" }
    assert_response :redirect
    follow_redirect!
    assert_match(/Смена не открыта|Смена закрыта/, response.body)
  end

  test "1.3 close shift blocks barista new order shop still works" do
    login_as!(@barista_a)
    post barista_open_shift_path, params: { opening_cash: 0 }
    assert_redirected_to barista_dashboard_path

    login_as!(@shift_mgr)
    shift = CashShift.find_by!(tenant_id: @tenant_a.id, status: "open")
    post manager_close_shift_path(shift), params: { closing_cash: 0 }, headers: { "ACCEPT" => "text/html" }
    assert_redirected_to manager_shift_path(shift)
    assert_equal "closed", shift.reload.status

    login_as!(@barista_a)
    post "/barista/orders", params: { cart_items: [{ product_id: @product.id, quantity: 1 }], payment_method: "cash" }
    assert_response :redirect

    order = shop_place_order!(tenant: @tenant_a)
    assert order.persisted?
    assert_equal "accepted", order.status
  end

  test "1.3 manager shifts index shows open and close actions" do
    login_as!(@shift_mgr)
    get manager_shifts_path
    assert_response :success
    assert_includes response.body, "Смена закрыта"
    assert_includes response.body, "Открыть смену"

    post manager_open_shift_path, params: { opening_cash: 0 }
    assert_redirected_to manager_shifts_path

    get manager_shifts_path
    assert_includes response.body, "Смена открыта"
    assert_includes response.body, "Закрыть смену"
  end

  private

  def shop_place_order!(tenant:)
    post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    post "/shop/api/orders",
      headers: { "X-Shop-Tenant" => tenant.id.to_s },
      params: { phone: @customer.phone, name: "Guest", payment_method: "cash" },
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    Order.find(json["order_id"])
  end
end
