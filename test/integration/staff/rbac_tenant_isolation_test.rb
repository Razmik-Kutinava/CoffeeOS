# frozen_string_literal: true

require "test_helper"

# IB Phase 2: staff RBAC tenant isolation + Pundit critical paths.
class StaffRbacTenantIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "ib2-org-#{SecureRandom.hex(3)}")
    @other_org = create_organization!(slug: "ib2-other-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "Point A", slug: "ib2-a-#{SecureRandom.hex(4)}")
    @tenant_b = create_tenant!(organization: @org, name: "Point B", slug: "ib2-b-#{SecureRandom.hex(4)}")
    @foreign_tenant = create_tenant!(organization: @other_org, name: "Foreign", slug: "ib2-x-#{SecureRandom.hex(4)}")
    @kitchen_a = create_prep_kitchen_tenant!(name: "Kitchen A", slug: "ib2-k-a-#{SecureRandom.hex(4)}")
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "barista tenant A sees own order and cannot open foreign tenant order by id" do
    barista_a = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "ib2-bar-a-#{SecureRandom.hex(3)}@test.local")
    barista_b = create_user!(tenant: @tenant_b, role_codes: %w[barista], email: "ib2-bar-b-#{SecureRandom.hex(3)}@test.local")
    shift_a = open_cash_shift!(tenant: @tenant_a, opened_by: barista_a)
    shift_b = open_cash_shift!(tenant: @tenant_b, opened_by: barista_b)

    own_order = Order.create!(
      tenant: @tenant_a,
      cash_shift: shift_a,
      order_number: "OWN-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    foreign_order = Order.create!(
      tenant: @tenant_b,
      cash_shift: shift_b,
      order_number: "FOREIGN-#{SecureRandom.hex(3)}",
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

  test "general_manager tenant A orders list shows only tenant A orders" do
    gm = create_user!(tenant: @tenant_a, role_codes: %w[general_manager], email: "ib2-gm-#{SecureRandom.hex(3)}@test.local")
    barista_b = create_user!(tenant: @tenant_b, role_codes: %w[barista], email: "ib2-gm-bar-b-#{SecureRandom.hex(3)}@test.local")
    shift_b = open_cash_shift!(tenant: @tenant_b, opened_by: barista_b)

    order_a = Order.create!(
      tenant: @tenant_a,
      order_number: "GM-A-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    order_b = Order.create!(
      tenant: @tenant_b,
      cash_shift: shift_b,
      order_number: "GM-B-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )

    login_as!(gm)

    get manager_orders_path
    assert_response :success
    assert_includes response.body, order_a.order_number
    assert_not_includes response.body, order_b.order_number
  end

  test "shift_manager cannot access staff management" do
    barista = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "ib2-sm-bar-#{SecureRandom.hex(3)}@test.local")
    shift_manager = create_user!(tenant: @tenant_a, role_codes: %w[shift_manager], email: "ib2-sm-#{SecureRandom.hex(3)}@test.local")
    open_cash_shift!(tenant: @tenant_a, opened_by: barista)

    login_as!(shift_manager)

    get manager_staff_members_path
    assert_response :redirect
    assert_not_equal 200, response.status
  end

  test "general_manager can access staff management" do
    gm = create_user!(tenant: @tenant_a, role_codes: %w[general_manager], email: "ib2-gm-staff-#{SecureRandom.hex(3)}@test.local")

    login_as!(gm)

    get manager_staff_members_path
    assert_response :success
  end

  test "shift_manager cannot access devices" do
    barista = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "ib2-sm-dev-bar-#{SecureRandom.hex(3)}@test.local")
    shift_manager = create_user!(tenant: @tenant_a, role_codes: %w[shift_manager], email: "ib2-sm-dev-#{SecureRandom.hex(3)}@test.local")
    open_cash_shift!(tenant: @tenant_a, opened_by: barista)

    login_as!(shift_manager)

    get manager_devices_path
    assert_response :redirect
    assert_not_equal 200, response.status
  end

  test "franchise_manager can switch own org tenant and cannot switch foreign org tenant" do
    franchise = create_user!(
      tenant: @tenant_a,
      organization: @org,
      role_codes: %w[franchise_manager],
      email: "ib2-fm-#{SecureRandom.hex(3)}@test.local"
    )

    login_as!(franchise)

    get manager_dashboard_path
    assert_response :success

    post manager_switch_tenant_path, params: { tenant_id: @tenant_b.id }
    follow_redirect!
    assert_response :success
    assert_includes response.body, @tenant_b.name

    post manager_switch_tenant_path, params: { tenant_id: @foreign_tenant.id }
    assert_redirected_to manager_dashboard_path
    follow_redirect!
    assert_match /нет доступа/i, flash[:alert].to_s
  end

  test "prep_kitchen manager can access movements for own tenant" do
    pk_manager = create_user!(
      tenant: @kitchen_a,
      role_codes: %w[prep_kitchen_manager],
      email: "ib2-pk-#{SecureRandom.hex(3)}@test.local"
    )

    login_as!(pk_manager)

    get prep_kitchen_movements_path
    assert_response :success
  end

  test "barista role only on tenant B denies barista panel when user tenant is A" do
    user = User.create!(
      tenant: @tenant_a,
      name: "Wrong Tenant Role",
      email: "ib2-wrong-#{SecureRandom.hex(3)}@test.local",
      status: "active",
      password: "pass123"
    )
    barista_role = create_role!(code: "barista")
    UserRole.create!(user: user, role: barista_role, tenant: @tenant_b)

    login_as!(user)

    get barista_dashboard_path
    assert_response :redirect
    assert_not_equal 200, response.status
  end
end
