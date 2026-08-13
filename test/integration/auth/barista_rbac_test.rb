# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок C: barista — только POS и своя смена; чужие панели закрыты.
class Auth::BaristaRbacTest < ActionDispatch::IntegrationTest
  MANAGER_FORBIDDEN_PATHS = [
    [ :manager_dashboard, :manager_dashboard_path ],
    [ :manager_menu, :manager_menu_path ],
    [ :manager_staff, :manager_staff_members_path ],
    [ :manager_reports, :manager_reports_path ],
    [ :manager_inventory, :manager_inventory_path ],
    [ :manager_shifts, :manager_shifts_path ],
    [ :manager_devices, :manager_devices_path ],
    [ :manager_tv_settings, :manager_tv_board_settings_path ]
  ].freeze

  OTHER_PANEL_PATHS = [
    [ :prep_kitchen, :prep_kitchen_dashboard_path ],
    [ :prep_kitchen_movements, :prep_kitchen_movements_path ],
    [ :platform_root, :platform_root_path ],
    [ :platform_menu, :platform_menu_path ],
    [ :platform_tenants, :platform_tenants_path ]
  ].freeze

  BARISTA_ALLOWED_PATHS = [
    [ :dashboard, :barista_dashboard_path ],
    [ :pos_menu, :barista_menu_path ],
    [ :shift, :barista_shift_path ],
    [ :orders_history, :barista_orders_history_path ],
    [ :new_order, :barista_new_order_path ]
  ].freeze

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @tenant = create_tenant!(name: "Barista RBAC", slug: "bar-rbac-#{SecureRandom.hex(4)}")
    @other_tenant = create_tenant!(name: "Other Point", slug: "other-#{SecureRandom.hex(4)}")
    @barista = create_user!(
      tenant: @tenant,
      role_codes: %w[barista],
      email: "bar-rbac-#{SecureRandom.hex(3)}@test.local",
      name: "Barista RBAC"
    )
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    login_as!(@barista)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "barista can access pos and own shift pages" do
    BARISTA_ALLOWED_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :success, "barista должен открывать #{path_helper}"
    end
  end

  test "barista is redirected from manager menu staff reports and settings" do
    MANAGER_FORBIDDEN_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :redirect, "barista не должен видеть #{path_helper}"
      assert_not_equal 200, response.status
    end
  end

  test "barista is redirected from prep kitchen and platform admin" do
    OTHER_PANEL_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :redirect, "barista не должен видеть #{path_helper}"
    end
  end

  test "barista cannot patch manager menu price" do
    category = create_category!
    product = create_product!(category: category)
    pts = enable_product_for_tenant!(tenant: @tenant, product: product, price: 100)

    patch manager_menu_setting_price_path(pts), params: { price: 999 }

    assert_response :redirect
    assert_equal 100.to_d, pts.reload.price.to_d
  end

  test "barista cannot create manager staff member" do
    assert_no_difference "User.count" do
      post manager_staff_members_path, params: {
        user: {
          name: "Hacker Staff",
          email: "hack-#{SecureRandom.hex(3)}@test.local",
          phone: "+7900#{rand(10**7)}",
          role_code: "barista"
        }
      }
    end
    assert_response :redirect
  end

  test "barista cannot open order from another tenant by id" do
    other_barista = create_user!(
      tenant: @other_tenant,
      role_codes: %w[barista],
      email: "other-bar-#{SecureRandom.hex(3)}@test.local"
    )
    other_shift = open_cash_shift!(tenant: @other_tenant, opened_by: other_barista)
    foreign_order = Order.create!(
      tenant: @other_tenant,
      cash_shift: other_shift,
      order_number: "FOREIGN-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 50,
      discount_amount: 0,
      final_amount: 50
    )

    get barista_order_path(foreign_order)
    assert_response :redirect
    assert_not_equal 200, response.status
  end

  test "barista order history excludes other tenant orders" do
    foreign_order = Order.create!(
      tenant: @other_tenant,
      order_number: "HIST-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "closed",
      total_amount: 50,
      discount_amount: 0,
      final_amount: 50,
      created_at: Time.current,
      updated_at: Time.current
    )

    get barista_orders_history_path
    assert_response :success
    assert_not_includes response.body, foreign_order.order_number
  end
end
