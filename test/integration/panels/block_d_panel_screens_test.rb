# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок D: все экраны панелей открываются (smoke). Дублирует MCP-обход GET-маршрутов.
class BlockDPanelScreensTest < ActionDispatch::IntegrationTest
  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "bd-org-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "BD A", slug: "bd-a-#{SecureRandom.hex(4)}")
    @tenant_b = create_tenant!(organization: @org, name: "BD B", slug: "bd-b-#{SecureRandom.hex(4)}")
    @kitchen = create_tenant!(organization: @org, name: "BD Kitchen", slug: "bd-k-#{SecureRandom.hex(4)}")
    @kitchen.update!(type: "production_kitchen")

    @barista_user = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "bd-bar-#{SecureRandom.hex(3)}@test.local")
    @open_shift = open_cash_shift!(tenant: @tenant_a, opened_by: @barista_user)
    @order = Order.create!(
      tenant: @tenant_a,
      cash_shift: @open_shift,
      order_number: "BD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )

    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant_a, product: @product, price: 150)
    enable_product_for_tenant!(tenant: @tenant_b, product: @product, price: 160)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "platform uk screens open" do
    uk = create_uk_admin!(email: "bd-uk-#{SecureRandom.hex(3)}@test.local")
    login_as!(uk)

    assert_get_success platform_root_path
    assert_get_success platform_organizations_path
    assert_get_success new_platform_organization_path
    assert_get_success edit_platform_organization_path(@org)
    assert_get_success platform_tenants_path
    assert_get_success new_platform_tenant_path
    assert_get_success platform_tenant_path(@tenant_a)
    assert_get_success edit_platform_tenant_path(@tenant_a)
    assert_get_success new_platform_franchise_owner_path
    assert_get_success platform_menu_path
  end

  test "franchise_manager manager screens open" do
    owner = create_user!(
      tenant: @tenant_a,
      organization: @org,
      role_codes: %w[franchise_manager],
      email: "bd-fm-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(owner)

    franchise_manager_get_screens.each do |path|
      assert_get_success path
    end

    get manager_staff_members_path
    assert_redirected_to manager_dashboard_path
  end

  test "shift_manager operational screens open" do
    sm = create_user!(tenant: @tenant_a, role_codes: %w[shift_manager], email: "bd-sm-#{SecureRandom.hex(3)}@test.local")
    login_as!(sm)

    [
      manager_dashboard_path,
      manager_orders_path,
      manager_order_path(@order),
      manager_finance_payments_path,
      manager_finance_refunds_path,
      manager_finance_fiscal_receipts_path,
      manager_shifts_path,
      manager_shift_path(@open_shift),
      manager_close_shift_path(@open_shift),
      manager_reports_path,
      manager_incidents_path,
      manager_menu_path
    ].each { |path| assert_get_success path }
  end

  test "general_manager manager screens open" do
    gm = create_user!(tenant: @tenant_a, role_codes: %w[general_manager], email: "bd-gm-#{SecureRandom.hex(3)}@test.local")
    staff = create_user!(
      tenant: @tenant_a,
      role_codes: %w[barista],
      email: "bd-staff-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(gm)

    franchise_manager_get_screens.each { |path| assert_get_success path }
    assert_get_success new_manager_staff_member_path
    assert_get_success edit_manager_staff_member_path(staff)
    assert_get_success manager_tv_board_settings_path
  end

  test "barista pos screens open" do
    login_as!(@barista_user)

    [
      barista_dashboard_path,
      barista_menu_path,
      barista_new_order_path,
      barista_order_path(@order),
      barista_shift_path,
      barista_orders_history_path,
      barista_reports_path
    ].each { |path| assert_get_success path }
  end

  test "prep_kitchen_manager screens open" do
    manager = create_user!(
      tenant: @kitchen,
      role_codes: %w[prep_kitchen_manager],
      email: "bd-pkm-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(manager)

    prep_kitchen_get_screens(include_new_movement: true).each { |path| assert_get_success path }
  end

  test "prep_kitchen_worker read screens open" do
    worker = create_user!(
      tenant: @kitchen,
      role_codes: %w[prep_kitchen_worker],
      email: "bd-pkw-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(worker)

    prep_kitchen_worker_read_screens.each { |path| assert_get_success path }
    prep_kitchen_manager_only_screens.each do |path|
      get path
      assert_response :redirect, "worker не должен открывать #{path}"
    end
    get prep_kitchen_new_movement_path
    assert_response :redirect
  end

  private

  def assert_get_success(path)
    get path
    assert_response :success, "ожидался 200 для #{path}, получен #{response.status}"
  end

  def franchise_manager_get_screens
    [
      manager_dashboard_path,
      manager_orders_path,
      manager_order_path(@order),
      manager_finance_payments_path,
      manager_finance_refunds_path,
      manager_finance_fiscal_receipts_path,
      manager_shifts_path,
      manager_shift_path(@open_shift),
      manager_reports_path,
      manager_inventory_path,
      manager_menu_path,
      manager_devices_path,
      manager_incidents_path
    ]
  end

  def prep_kitchen_get_screens(include_new_movement:)
    paths = prep_kitchen_worker_read_screens + prep_kitchen_manager_only_screens
    paths << prep_kitchen_new_movement_path if include_new_movement
    paths
  end

  def prep_kitchen_worker_read_screens
    [
      prep_kitchen_dashboard_path,
      prep_kitchen_queue_path,
      prep_kitchen_inventory_path,
      prep_kitchen_movements_path,
      prep_kitchen_stop_list_path
    ]
  end

  def prep_kitchen_manager_only_screens
    [
      prep_kitchen_recipes_path,
      prep_kitchen_incidents_path,
      prep_kitchen_reports_path
    ]
  end
end
