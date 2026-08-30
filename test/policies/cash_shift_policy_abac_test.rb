# frozen_string_literal: true

require "test_helper"

class CashShiftPolicyAbacTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "cs-bar@t.local")
    @gm = create_user!(tenant: @tenant, role_codes: %w[general_manager], email: "cs-gm@t.local")
    @open_shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
  end

  def ctx(user, shift: :auto)
    PolicyContext.build(user: user, tenant_id: @tenant.id, shift: shift, tenant: @tenant)
  end

  test "cannot open shift when one already open" do
    policy = CashShiftPolicy.new(ctx(@gm, shift: @open_shift), CashShift)
    assert_not policy.create?
  end

  test "can open shift when none open" do
    @open_shift.update!(status: "closed", closed_at: Time.current, closing_cash: 0, closed_by: @barista)
    policy = CashShiftPolicy.new(ctx(@gm, shift: nil), CashShift)
    assert policy.create?
  end

  test "close requires open shift" do
    policy = CashShiftPolicy.new(ctx(@gm, shift: @open_shift), @open_shift)
    assert policy.close?

    closed_ctx = CashShiftPolicy.new(ctx(@gm, shift: nil), @open_shift)
    assert_not closed_ctx.close?
  end
end
