# frozen_string_literal: true

require "test_helper"

# ABAC-тесты OrderPolicy: shift_open + in_shift поверх RBAC.
class OrderPolicyAbacTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "abac-bar@t.local")
    @shift_manager = create_user!(tenant: @tenant, role_codes: %w[shift_manager], email: "abac-sm@t.local")
    @gm = create_user!(tenant: @tenant, role_codes: %w[general_manager], email: "abac-gm@t.local")
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
    @order_in_shift = Order.create!(
      tenant: @tenant,
      cash_shift: @open_shift,
      order_number: "ABAC-IN-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    @order_other_shift = Order.create!(
      tenant: @tenant,
      cash_shift: @closed_shift,
      order_number: "ABAC-OLD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "ready",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    @vitrina_order = Order.create!(
      tenant: @tenant,
      cash_shift: nil,
      order_number: "ABAC-MOB-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "accepted",
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150,
      created_at: @open_shift.opened_at + 1.minute
    )
  end

  def ctx(user, shift: :auto, tenant: @tenant)
    PolicyContext.build(user: user, tenant_id: tenant.id, role_code: role_for(user), shift: shift, tenant: tenant)
  end

  def role_for(user)
    return "barista" if user.has_role_in_context?("barista", tenant_id: @tenant.id)
    return "shift_manager" if user.has_role_in_context?("shift_manager", tenant_id: @tenant.id)
    return "general_manager" if user.has_role_in_context?("general_manager", tenant_id: @tenant.id)

    nil
  end

  # --- shift_open on create ---

  test "barista cannot create order when shift closed" do
    policy = OrderPolicy.new(ctx(@barista, shift: nil), Order)
    assert_not policy.create?
  end

  test "barista can create order when shift open" do
    policy = OrderPolicy.new(ctx(@barista, shift: @open_shift), Order)
    assert policy.create?
  end

  # --- in_shift on show / cancel / update_status ---

  test "barista can show order in current shift scope" do
    policy = OrderPolicy.new(ctx(@barista, shift: @open_shift), @order_in_shift)
    assert policy.show?
  end

  test "barista can show vitrina mobile order from open shift window" do
    policy = OrderPolicy.new(ctx(@barista, shift: @open_shift), @vitrina_order)
    assert policy.show?
  end

  test "barista cannot show order from closed other shift" do
    policy = OrderPolicy.new(ctx(@barista, shift: @open_shift), @order_other_shift)
    assert_not policy.show?
  end

  test "barista can cancel order in shift scope" do
    policy = OrderPolicy.new(ctx(@barista, shift: @open_shift), @order_in_shift)
    assert policy.cancel?
  end

  test "barista cannot cancel order outside shift scope" do
    policy = OrderPolicy.new(ctx(@barista, shift: @open_shift), @order_other_shift)
    assert_not policy.cancel?
  end

  test "barista cannot cancel when shift closed even if order in scope" do
    policy = OrderPolicy.new(ctx(@barista, shift: nil), @order_in_shift)
    assert_not policy.cancel?
  end

  test "barista can update_status in shift scope" do
    policy = OrderPolicy.new(ctx(@barista, shift: @open_shift), @order_in_shift)
    assert policy.update_status?
  end

  test "barista cannot update_status when shift closed" do
    policy = OrderPolicy.new(ctx(@barista, shift: nil), @order_in_shift)
    assert_not policy.update_status?
  end

  test "barista cannot update_status on order outside shift" do
    policy = OrderPolicy.new(ctx(@barista, shift: @open_shift), @order_other_shift)
    assert_not policy.update_status?
  end

  # --- manager cancel matrix ---

  test "shift_manager can cancel during open shift" do
    policy = OrderPolicy.new(ctx(@shift_manager, shift: @open_shift), @order_other_shift)
    assert policy.cancel?
  end

  test "shift_manager cannot cancel when shift closed" do
    policy = OrderPolicy.new(ctx(@shift_manager, shift: nil), @order_in_shift)
    assert_not policy.cancel?
  end

  test "general_manager can cancel regardless of shift" do
    policy = OrderPolicy.new(ctx(@gm, shift: nil), @order_other_shift)
    assert policy.cancel?
  end

  test "general_manager can show order outside barista shift scope" do
    policy = OrderPolicy.new(ctx(@gm, shift: nil), @order_other_shift)
    assert policy.show?
  end
end
