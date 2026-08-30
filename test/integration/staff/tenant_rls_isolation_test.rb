# frozen_string_literal: true

require "test_helper"

# IB Phase 3: franchise / UK tenant switch + RLS isolation regression.
class StaffTenantRlsIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "ib3-org-#{SecureRandom.hex(3)}")
    @other_org = create_organization!(slug: "ib3-other-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "IB3 Point A", slug: "ib3-a-#{SecureRandom.hex(4)}")
    @tenant_b = create_tenant!(organization: @org, name: "IB3 Point B", slug: "ib3-b-#{SecureRandom.hex(4)}")
    @foreign_tenant = create_tenant!(organization: @other_org, name: "Foreign", slug: "ib3-x-#{SecureRandom.hex(4)}")
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  # Scenario 1: franchise user, tenant другой org → POST switch_tenant → deny
  test "franchise_manager cannot switch to tenant outside organization" do
    franchise = create_user!(
      tenant: @tenant_a,
      organization: @org,
      role_codes: %w[franchise_manager],
      email: "ib3-fm-deny-#{SecureRandom.hex(3)}@test.local"
    )

    login_as!(franchise)

    post manager_switch_tenant_path, params: { tenant_id: @foreign_tenant.id }
    assert_redirected_to manager_dashboard_path
    follow_redirect!
    assert_match /нет доступа/i, flash[:alert].to_s
  end

  # Scenario 2: franchise user, tenant своей org → switch OK, dashboard 200
  test "franchise_manager can switch between own organization tenants" do
    franchise = create_user!(
      tenant: @tenant_a,
      organization: @org,
      role_codes: %w[franchise_manager],
      email: "ib3-fm-ok-#{SecureRandom.hex(3)}@test.local"
    )

    login_as!(franchise)

    post manager_switch_tenant_path, params: { tenant_id: @tenant_b.id }
    follow_redirect!
    assert_response :success
    assert_includes response.body, @tenant_b.name

    get manager_dashboard_path
    assert_response :success
  end

  # Scenario 3: UK без manager_tenant_id → manager redirect platform
  test "uk_global_admin without manager_tenant_id is redirected to platform" do
    uk = create_uk_admin!(email: "ib3-uk-notenant-#{SecureRandom.hex(3)}@test.local")
    login_as!(uk)

    get manager_dashboard_path
    assert_redirected_to platform_root_path
    assert_match /выберите точку/i, flash[:alert].to_s
  end

  # Scenario 4: UK с tenant A, order tenant B not visible → 404/redirect
  test "uk_global_admin in tenant A context cannot show order from tenant B" do
    uk = create_uk_admin!(email: "ib3-uk-order-#{SecureRandom.hex(3)}@test.local")
    barista_b = create_user!(
      tenant: @tenant_b,
      role_codes: %w[barista],
      email: "ib3-uk-bar-b-#{SecureRandom.hex(3)}@test.local"
    )
    shift_b = open_cash_shift!(tenant: @tenant_b, opened_by: barista_b)
    order_b = Order.create!(
      tenant: @tenant_b,
      cash_shift: shift_b,
      order_number: "IB3-B-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )

    login_as!(uk)
    post open_as_manager_platform_tenant_path(@tenant_a)
    follow_redirect!
    assert_response :success

    get manager_order_path(order_b)
    assert_response :redirect
    assert_not_equal 200, response.status
  end

  # Scenario 5: barista tenant A session — не видит данные B
  test "barista tenant A cannot access tenant B order" do
    barista_a = create_user!(
      tenant: @tenant_a,
      role_codes: %w[barista],
      email: "ib3-bar-a-#{SecureRandom.hex(3)}@test.local"
    )
    barista_b = create_user!(
      tenant: @tenant_b,
      role_codes: %w[barista],
      email: "ib3-bar-b-#{SecureRandom.hex(3)}@test.local"
    )
    shift_a = open_cash_shift!(tenant: @tenant_a, opened_by: barista_a)
    shift_b = open_cash_shift!(tenant: @tenant_b, opened_by: barista_b)

    own_order = Order.create!(
      tenant: @tenant_a,
      cash_shift: shift_a,
      order_number: "IB3-OWN-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    foreign_order = Order.create!(
      tenant: @tenant_b,
      cash_shift: shift_b,
      order_number: "IB3-FOR-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 50,
      discount_amount: 0,
      final_amount: 50
    )

    login_as!(barista_a)

    get barista_order_path(own_order)
    assert_response :success

    get barista_order_path(foreign_order)
    assert_response :redirect
    assert_not_equal 200, response.status
  end

  test "shift_manager cannot POST create device" do
    barista = create_user!(
      tenant: @tenant_a,
      role_codes: %w[barista],
      email: "ib3-sm-bar-#{SecureRandom.hex(3)}@test.local"
    )
    shift_manager = create_user!(
      tenant: @tenant_a,
      role_codes: %w[shift_manager],
      email: "ib3-sm-dev-#{SecureRandom.hex(3)}@test.local"
    )
    open_cash_shift!(tenant: @tenant_a, opened_by: barista)

    login_as!(shift_manager)

    assert_no_difference -> { Device.count } do
      post manager_devices_path, params: { device: { name: "Blocked TV" } }
    end
    assert_response :redirect
    assert_not_equal 200, response.status
  end
end
