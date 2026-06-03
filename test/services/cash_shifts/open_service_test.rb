# frozen_string_literal: true

require "test_helper"

class CashShifts::OpenServiceTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @user = create_user!(tenant: @tenant, role_codes: %w[barista])
  end

  test "opens shift when none open" do
    shift = CashShifts::OpenService.call(tenant: @tenant, opened_by: @user, opening_cash: 100)
    assert shift.open?
    assert_equal 100, shift.opening_cash
    assert_equal @user.id, shift.opened_by_id
  end

  test "raises when shift already open" do
    open_cash_shift!(tenant: @tenant, opened_by: @user)
    assert_raises(CashShifts::OpenService::Error) do
      CashShifts::OpenService.call(tenant: @tenant, opened_by: @user)
    end
  end
end
