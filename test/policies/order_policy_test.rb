require "test_helper"

# Unit-тесты Pundit политик для Order (RBAC baseline + PolicyContext для shift).
class OrderPolicyTest < ActionDispatch::IntegrationTest
  setup do
    @tenant   = create_tenant!
    @order    = Order.new(tenant_id: @tenant.id)
    @shift    = open_cash_shift!(tenant: @tenant, opened_by: create_user!(tenant: @tenant, role_codes: %w[barista], email: "pol-open@t.local"))

    @barista        = create_user!(tenant: @tenant, role_codes: %w[barista],        email: "pol-barista@t.local",  name: "PB")
    @shift_manager  = create_user!(tenant: @tenant, role_codes: %w[shift_manager],  email: "pol-shift@t.local",   name: "PS")
    @general_manager = create_user!(tenant: @tenant, role_codes: %w[general_manager], email: "pol-office@t.local",  name: "PO")
    @stranger       = create_user!(tenant: @tenant, role_codes: %w[],               email: "pol-nobody@t.local",  name: "PN")
  end

  def barista_ctx(user = @barista)
    PolicyContext.build(user: user, tenant_id: @tenant.id, role_code: "barista", shift: @shift, tenant: @tenant)
  end

  def manager_ctx(user, role_code)
    PolicyContext.build(user: user, tenant_id: @tenant.id, role_code: role_code, shift: @shift, tenant: @tenant)
  end

  test "barista can create order with open shift context" do
    assert OrderPolicy.new(barista_ctx, Order).create?
  end

  test "general_manager cannot create order via barista policy" do
    assert_not OrderPolicy.new(manager_ctx(@general_manager, "general_manager"), Order).create?
  end

  test "unauthenticated user raises NotAuthorizedError" do
    assert_raises(Pundit::NotAuthorizedError) { OrderPolicy.new(nil, @order) }
  end

  test "barista can show order with context (RBAC)" do
    order = Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "POL-1", source: "manual",
      status: "accepted", total_amount: 100, discount_amount: 0, final_amount: 100
    )
    assert OrderPolicy.new(barista_ctx, order).show?
  end

  test "general_manager can show order" do
    assert OrderPolicy.new(manager_ctx(@general_manager, "general_manager"), @order).show?
  end

  test "user with no role cannot show order" do
    assert_not OrderPolicy.new(@stranger, @order).show?
  end

  test "barista can update_status in shift scope" do
    order = Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "POL-2", source: "manual",
      status: "accepted", total_amount: 100, discount_amount: 0, final_amount: 100
    )
    assert OrderPolicy.new(barista_ctx, order).update_status?
  end

  test "general_manager cannot update_status via barista policy" do
    assert_not OrderPolicy.new(manager_ctx(@general_manager, "general_manager"), @order).update_status?
  end

  test "barista can cancel in shift scope" do
    order = Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "POL-3", source: "manual",
      status: "accepted", total_amount: 100, discount_amount: 0, final_amount: 100
    )
    assert OrderPolicy.new(barista_ctx, order).cancel?
  end

  test "general_manager can cancel" do
    assert OrderPolicy.new(manager_ctx(@general_manager, "general_manager"), @order).cancel?
  end

  test "stranger cannot cancel" do
    assert_not OrderPolicy.new(@stranger, @order).cancel?
  end
end
