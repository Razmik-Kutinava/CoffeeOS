# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок C: shift_manager — оперативка текущей смены; без «глубокой» истории и привилегий GM.
class Auth::ShiftManagerRbacTest < ActionDispatch::IntegrationTest
  OPERATIONAL_PATHS = [
    [:dashboard, :manager_dashboard_path],
    [:orders, :manager_orders_path],
    [:payments, :manager_finance_payments_path],
    [:refunds, :manager_finance_refunds_path],
    [:fiscal, :manager_finance_fiscal_receipts_path],
    [:shifts, :manager_shifts_path],
    [:reports, :manager_reports_path],
    [:incidents, :manager_incidents_path],
    [:menu_read, :manager_menu_path]
  ].freeze

  FORBIDDEN_PATHS = [
    [:inventory, :manager_inventory_path],
    [:staff, :manager_staff_members_path],
    [:devices, :manager_devices_path],
    [:tv_settings, :manager_tv_board_settings_path],
    [:barista, :barista_dashboard_path],
    [:prep_kitchen, :prep_kitchen_dashboard_path],
    [:platform, :platform_root_path]
  ].freeze

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @tenant = create_tenant!(name: "SM RBAC", slug: "sm-rbac-#{SecureRandom.hex(4)}")
    @barista = create_user!(
      tenant: @tenant,
      role_codes: %w[barista],
      email: "sm-bar-#{SecureRandom.hex(3)}@test.local"
    )
    @shift_manager = create_user!(
      tenant: @tenant,
      role_codes: %w[shift_manager],
      email: "sm-mgr-#{SecureRandom.hex(3)}@test.local"
    )
    @open_shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    @closed_shift = CashShift.create!(
      tenant: @tenant,
      status: "closed",
      opened_by: @barista,
      opened_at: 2.days.ago,
      opening_cash: 0,
      closed_at: 1.day.ago,
      closing_cash: 0,
      closed_by: @barista
    )

    @open_order = Order.create!(
      tenant: @tenant,
      cash_shift: @open_shift,
      order_number: "SM-OPEN-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    @closed_order = Order.create!(
      tenant: @tenant,
      cash_shift: @closed_shift,
      order_number: "SM-OLD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )

    login_as!(@shift_manager)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "shift_manager can access operational manager pages for current shift" do
    OPERATIONAL_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :success, "shift_manager должен открывать #{path_helper}"
    end
  end

  test "shift_manager is redirected from inventory staff devices tv and other panels" do
    FORBIDDEN_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :redirect, "shift_manager не должен видеть #{path_helper}"
    end
  end

  test "shift_manager cannot patch menu price" do
    category = create_category!
    product = create_product!(category: category)
    pts = enable_product_for_tenant!(tenant: @tenant, product: product, price: 150)

    patch manager_menu_setting_price_path(pts), params: { product_tenant_setting: { price: 999 } }

    assert_response :redirect
    assert_equal 150.to_d, pts.reload.price.to_d
  end

  test "shift_manager orders list excludes closed shift history" do
    get manager_orders_path
    assert_response :success
    assert_includes response.body, @open_order.order_number
    assert_not_includes response.body, @closed_order.order_number
  end

  test "shift_manager cannot open order from closed shift by id" do
    get manager_order_path(@closed_order)
    assert_response :redirect
  end

  test "shift_manager shifts list shows only current open shift not deep history" do
    get manager_shifts_path
    assert_response :success
    assert_includes response.body, @open_shift.id.to_s
    assert_not_includes response.body, @closed_shift.id.to_s
  end

  test "shift_manager cannot open closed shift detail" do
    get manager_shift_path(@closed_shift)
    assert_response :redirect
  end

  test "shift_manager reports ignore wide date range for closed shift revenue" do
    from = Time.zone.now - 2.days
    to = Time.zone.now + 2.days
    @open_order.update!(created_at: from + 1.day)
    @closed_order.update!(created_at: from + 1.day + 1.hour)

    open_payment = Payment.create!(
      tenant: @tenant,
      order: @open_order,
      amount: 100,
      method: "cash",
      provider: "manual",
      status: "succeeded",
      paid_at: from + 1.day
    )
    open_payment.update!(created_at: from + 1.day)

    closed_payment = Payment.create!(
      tenant: @tenant,
      order: @closed_order,
      amount: 200,
      method: "cash",
      provider: "manual",
      status: "succeeded",
      paid_at: from + 1.day + 1.hour
    )
    closed_payment.update!(created_at: from + 1.day + 1.hour)

    get manager_reports_path, params: { from: from.iso8601, to: to.iso8601 }
    assert_response :success
    assert_includes response.body, "100.0 ₽"
    assert_not_includes response.body, "200.0 ₽"
  end
end
