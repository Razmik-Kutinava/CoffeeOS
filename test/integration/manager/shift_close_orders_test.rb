# frozen_string_literal: true

require "test_helper"

class Manager::ShiftCloseOrdersTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    Rack::Attack.enabled = false if defined?(Rack::Attack)
    @tenant = create_tenant!(slug: "mgr-close-#{SecureRandom.hex(3)}")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "mgr-close-b@test.local")
    @manager = create_user!(tenant: @tenant, role_codes: %w[shift_manager], email: "mgr-close-m@test.local")
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
  end

  test "manager can close shift with preparing order without blockers" do
    Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "INT-PREP",
      source: "manual", status: "preparing",
      total_amount: 200, discount_amount: 0, final_amount: 200
    )

    login_as!(@manager)
    post manager_close_shift_path(@shift), params: { closing_cash: 0 }

    assert_redirected_to manager_shift_path(@shift)
    assert_equal "closed", @shift.reload.status
    follow_redirect!
    assert_match(/Смена закрыта/i, response.body)
  end

  test "carryover preparing visible on barista board after new shift opened" do
    carryover = Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: "CARRY-1",
      source: "manual", status: "preparing",
      total_amount: 200, discount_amount: 0, final_amount: 200
    )

    login_as!(@manager)
    post manager_close_shift_path(@shift), params: { closing_cash: 0 }
    assert_equal "closed", @shift.reload.status

    login_as!(@barista)
    post barista_open_shift_path, params: { opening_cash: 0 }
    assert_redirected_to barista_dashboard_path

    get barista_dashboard_path
    assert_response :success
    assert_includes response.body, carryover.id.to_s
    assert_includes response.body, "barista-carryover-banner"
  end
end
