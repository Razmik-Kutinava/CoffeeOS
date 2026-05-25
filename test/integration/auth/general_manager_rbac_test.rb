# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок C: general_manager — меню, цены, staff, склад своей точки; чужие панели закрыты.
class Auth::GeneralManagerRbacTest < ActionDispatch::IntegrationTest
  PRIVILEGED_PATHS = [
    [:menu, :manager_menu_path],
    [:inventory, :manager_inventory_path],
    [:staff, :manager_staff_members_path],
    [:devices, :manager_devices_path],
    [:reports, :manager_reports_path]
  ].freeze

  OTHER_PANEL_PATHS = [
    [:barista, :barista_dashboard_path],
    [:prep_kitchen, :prep_kitchen_dashboard_path],
    [:platform, :platform_root_path]
  ].freeze

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "gm-org-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "GM Point A", slug: "gm-a-#{SecureRandom.hex(4)}")
    @tenant_b = create_tenant!(organization: @org, name: "GM Point B", slug: "gm-b-#{SecureRandom.hex(4)}")
    @general_manager = create_user!(
      tenant: @tenant_a,
      role_codes: %w[general_manager],
      email: "gm-#{SecureRandom.hex(3)}@test.local",
      name: "GM A"
    )

    category = create_category!
    @product = create_product!(category: category, name: "GM Product")
    @pts_a = enable_product_for_tenant!(tenant: @tenant_a, product: @product, price: 120)
    @pts_b = enable_product_for_tenant!(tenant: @tenant_b, product: @product, price: 220)

    @ingredient_a = Ingredient.create!(name: "Ing-A-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    @stock_a = IngredientTenantStock.create!(tenant: @tenant_a, ingredient: @ingredient_a, qty: 12, min_qty: 2)
    @ingredient_b = Ingredient.create!(name: "Ing-B-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    @stock_b = IngredientTenantStock.create!(tenant: @tenant_b, ingredient: @ingredient_b, qty: 99, min_qty: 1)

    @staff_a = create_user!(
      tenant: @tenant_a,
      role_codes: %w[barista],
      email: "gm-staff-a-#{SecureRandom.hex(3)}@test.local",
      name: "Staff A"
    )
    @staff_b = create_user!(
      tenant: @tenant_b,
      role_codes: %w[barista],
      email: "gm-staff-b-#{SecureRandom.hex(3)}@test.local",
      name: "Staff B"
    )

    login_as!(@general_manager)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "general_manager can access menu inventory staff devices and reports" do
    PRIVILEGED_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :success, "general_manager должен открывать #{path_helper}"
    end
  end

  test "general_manager is redirected from barista prep kitchen and platform" do
    OTHER_PANEL_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :redirect, "general_manager не должен видеть #{path_helper}"
    end
  end

  test "general_manager can patch menu price for own tenant" do
    patch manager_menu_setting_price_path(@pts_a), params: { product_tenant_setting: { price: 155 } }

    assert_redirected_to manager_menu_path
    assert_equal 155.to_d, @pts_a.reload.price.to_d
  end

  test "general_manager cannot patch menu price for another tenant" do
    patch manager_menu_setting_price_path(@pts_b), params: { product_tenant_setting: { price: 999 } }

    assert_response :redirect
    assert_equal 220.to_d, @pts_b.reload.price.to_d
  end

  test "general_manager inventory shows only own tenant stock" do
    get manager_inventory_path
    assert_response :success
    assert_includes response.body, @ingredient_a.name
    assert_not_includes response.body, @ingredient_b.name
  end

  test "general_manager staff list shows own tenant users not other point" do
    get manager_staff_members_path
    assert_response :success
    assert_includes response.body, @staff_a.name
    assert_not_includes response.body, @staff_b.name
  end

  test "general_manager can create staff for own tenant" do
    email = "new-bar-#{SecureRandom.hex(3)}@test.local"

    assert_difference -> { User.where(tenant_id: @tenant_a.id).count }, +1 do
      post manager_staff_members_path, params: {
        user: { name: "New Barista", email: email, password: "pass123" },
        role_codes: %w[barista]
      }
    end

    assert_redirected_to manager_staff_members_path
    assert User.find_by!(email: email).has_role?("barista")
  end

  test "general_manager cannot edit staff from another tenant" do
    get edit_manager_staff_member_path(@staff_b)
    assert_response :redirect
  end

  test "general_manager orders exclude other tenant even in same organization" do
    barista_b = create_user!(tenant: @tenant_b, role_codes: %w[barista], email: "gm-bar-b-#{SecureRandom.hex(3)}@test.local")
    shift_b = open_cash_shift!(tenant: @tenant_b, opened_by: barista_b)
    order_b = Order.create!(
      tenant: @tenant_b,
      cash_shift: shift_b,
      order_number: "GM-OTHER-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 50,
      discount_amount: 0,
      final_amount: 50
    )

    get manager_orders_path
    assert_response :success
    assert_not_includes response.body, order_b.order_number

    get manager_order_path(order_b)
    assert_response :redirect
  end
end
