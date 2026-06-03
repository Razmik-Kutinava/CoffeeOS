# frozen_string_literal: true

require "test_helper"

# PDF «Прогонка сценариев» §1.2 — две кофейни не смешиваются (gm-a / gm-b).
class Demo::QaSection12GmIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "demo-qa-12-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "Demo Coffee Point A", slug: "demo-point-a-#{SecureRandom.hex(4)}")
    @tenant_b = create_tenant!(organization: @org, name: "Demo Coffee Point B", slug: "demo-point-b-#{SecureRandom.hex(4)}")

    category = create_category!
    @product = create_product!(category: category, name: "Фильтр-кофе Бразилия")
    @pts_a = enable_product_for_tenant!(tenant: @tenant_a, product: @product, price: 179)
    @pts_b = enable_product_for_tenant!(tenant: @tenant_b, product: @product, price: 189)

    @gm_a = create_user!(
      tenant: @tenant_a,
      role_codes: %w[general_manager],
      email: "gm-a-#{SecureRandom.hex(3)}@demo.coffeeos.local",
      name: "GM Point A"
    )
    @gm_b = create_user!(
      tenant: @tenant_b,
      role_codes: %w[general_manager],
      email: "gm-b-#{SecureRandom.hex(3)}@demo.coffeeos.local",
      name: "GM Point B"
    )

    barista_b = create_user!(tenant: @tenant_b, role_codes: %w[barista], email: "bar-b-#{SecureRandom.hex(3)}@test.local")
    shift_b = open_cash_shift!(tenant: @tenant_b, opened_by: barista_b)
    @order_b = Order.create!(
      tenant: @tenant_b,
      cash_shift: shift_b,
      order_number: "QA12-B-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 189,
      discount_amount: 0,
      final_amount: 189
    )
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "1.2 step 1 gm-a menu shows point A price and role label" do
    login_as!(@gm_a)
    get manager_menu_path
    assert_response :success
    assert_includes response.body, "Управляющий точки"
    assert_includes response.body, @tenant_a.name
    assert_includes response.body, "179.0"
    assert_not_includes response.body, "189.0"
  end

  test "1.2 step 2 gm-b menu shows point B price (+10 vs A)" do
    login_as!(@gm_b)
    get manager_menu_path
    assert_response :success
    assert_includes response.body, @tenant_b.name
    assert_includes response.body, "189.0"
    assert_not_includes response.body, "179.0"
  end

  test "1.2 step 3 gm-a does not see point B orders on dashboard and orders" do
    login_as!(@gm_a)
    get manager_dashboard_path
    assert_response :success
    assert_includes response.body, @tenant_a.name
    assert_not_includes response.body, @order_b.order_number

    get manager_orders_path
    assert_response :success
    assert_not_includes response.body, @order_b.order_number

    get manager_order_path(@order_b)
    assert_response :redirect
  end
end
