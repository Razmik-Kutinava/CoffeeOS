require "test_helper"

# Unit-тесты Pundit политик для Order.
# Тестируем логику ролей в изоляции — без HTTP запросов.
class OrderPolicyTest < ActionDispatch::IntegrationTest
  setup do
    @tenant   = create_tenant!
    @order    = Order.new(tenant_id: @tenant.id)

    @barista        = create_user!(tenant: @tenant, role_codes: %w[barista],        email: "pol-barista@t.local",  name: "PB")
    @shift_manager  = create_user!(tenant: @tenant, role_codes: %w[shift_manager],  email: "pol-shift@t.local",   name: "PS")
    @office_manager = create_user!(tenant: @tenant, role_codes: %w[office_manager], email: "pol-office@t.local",  name: "PO")
    @stranger       = create_user!(tenant: @tenant, role_codes: %w[],               email: "pol-nobody@t.local",  name: "PN")
  end

  # create?
  test "barista can create order" do
    assert OrderPolicy.new(@barista, Order).create?
  end

  test "office_manager cannot create order via barista policy" do
    assert_not OrderPolicy.new(@office_manager, Order).create?
  end

  test "unauthenticated user raises NotAuthorizedError" do
    assert_raises(Pundit::NotAuthorizedError) { OrderPolicy.new(nil, @order) }
  end

  # show? / index?
  test "barista can show order" do
    assert OrderPolicy.new(@barista, @order).show?
  end

  test "office_manager can show order" do
    assert OrderPolicy.new(@office_manager, @order).show?
  end

  test "user with no role cannot show order" do
    assert_not OrderPolicy.new(@stranger, @order).show?
  end

  # update_status?
  test "barista can update_status" do
    assert OrderPolicy.new(@barista, @order).update_status?
  end

  test "office_manager cannot update_status via barista policy" do
    assert_not OrderPolicy.new(@office_manager, @order).update_status?
  end

  # cancel?
  test "barista can cancel" do
    assert OrderPolicy.new(@barista, @order).cancel?
  end

  test "office_manager can cancel" do
    assert OrderPolicy.new(@office_manager, @order).cancel?
  end

  test "stranger cannot cancel" do
    assert_not OrderPolicy.new(@stranger, @order).cancel?
  end
end
