require "test_helper"

class CashShiftTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "Test Cafe",
      slug: "test-cafe-#{SecureRandom.hex(4)}",
      type: "sales_point",
      status: "active",
      currency: "RUB",
      country: "RU",
      timezone: "Europe/Moscow"
    )

    @barista = User.new(
      tenant: @tenant,
      name: "Barista",
      email: "barista-#{SecureRandom.hex(4)}@test.local",
      status: "active"
    )
    @barista.password = "pass123"
    @barista.save!

    @shift = CashShift.create!(
      tenant: @tenant,
      status: "open",
      opened_by: @barista,
      opened_at: Time.current,
      opening_cash: 500
    )
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def create_tenant_with_barista!
    tenant = Tenant.create!(
      name: "Other Cafe",
      slug: "other-cafe-#{SecureRandom.hex(4)}",
      type: "sales_point",
      status: "active",
      currency: "RUB",
      country: "RU",
      timezone: "Europe/Moscow"
    )
    barista = User.new(
      tenant: tenant,
      name: "Other Barista",
      email: "other-#{SecureRandom.hex(4)}@test.local",
      status: "active"
    )
    barista.password = "pass123"
    barista.save!
    [tenant, barista]
  end

  def create_order_for_shift!(overrides = {})
    Order.create!({
      tenant: @tenant,
      cash_shift: @shift,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "issued",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    }.merge(overrides))
  end

  def create_cash_payment!(order:, amount: 100)
    Payment.create!(
      order: order,
      tenant: @tenant,
      amount: amount,
      method: "cash",
      provider: "manual",
      status: "succeeded",
      paid_at: Time.current
    )
  end

  def create_card_payment!(order:, amount: 100)
    Payment.create!(
      order: order,
      tenant: @tenant,
      amount: amount,
      method: "card",
      provider: "manual",
      status: "succeeded",
      paid_at: Time.current
    )
  end

  def create_succeeded_refund!(payment:, order:, amount: 50)
    Refund.create!(
      payment: payment,
      order: order,
      tenant: @tenant,
      amount: amount,
      reason: "Customer request",
      status: "succeeded"
    )
  end

  # ---------------------------------------------------------------------------
  # Basic validations
  # ---------------------------------------------------------------------------

  test "is valid with required attributes" do
    assert @shift.valid?
  end

  test "is invalid when opening_cash is negative" do
    shift = CashShift.new(
      tenant: @tenant,
      status: "open",
      opened_by: @barista,
      opened_at: Time.current,
      opening_cash: -1
    )
    assert_not shift.valid?
    assert shift.errors[:opening_cash].any?
  end

  test "is valid when opening_cash is zero" do
    # Already tested implicitly via setup, but explicit is clearer
    shift = CashShift.new(
      tenant: @tenant,
      status: "open",
      opened_by: @barista,
      opened_at: Time.current,
      opening_cash: 0
    )
    # Will fail only_one_open_shift because @shift is open for same tenant
    shift.valid?
    assert_not shift.errors[:opening_cash].any?
  end

  test "is invalid when closing_cash is negative" do
    @shift.closing_cash = -100
    assert_not @shift.valid?
    assert @shift.errors[:closing_cash].any?
  end

  test "is valid when closing_cash is zero" do
    @shift.closing_cash = 0
    assert @shift.valid?
  end

  test "is invalid without status" do
    shift = CashShift.new(
      tenant: @tenant,
      opened_by: @barista,
      opened_at: Time.current,
      opening_cash: 0
    )
    shift.status = nil
    assert_not shift.valid?
    assert shift.errors[:status].any?
  end

  # ---------------------------------------------------------------------------
  # only_one_open_shift validation
  # ---------------------------------------------------------------------------

  test "cannot create a second open shift for the same tenant" do
    duplicate = CashShift.new(
      tenant: @tenant,
      status: "open",
      opened_by: @barista,
      opened_at: Time.current,
      opening_cash: 0
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:status].any?
  end

  test "can create open shifts for different tenants" do
    other_tenant, other_barista = create_tenant_with_barista!
    shift = CashShift.new(
      tenant: other_tenant,
      status: "open",
      opened_by: other_barista,
      opened_at: Time.current,
      opening_cash: 0
    )
    assert shift.valid?
  end

  test "updating the existing open shift does not trigger only_one_open_shift on itself" do
    @shift.note = "updated note"
    assert @shift.valid?
  end

  test "can create a new open shift for a tenant after its previous shift is closed" do
    @shift.update!(
      status: "closed",
      closed_by: @barista,
      closed_at: Time.current,
      closing_cash: 500
    )
    new_shift = CashShift.new(
      tenant: @tenant,
      status: "open",
      opened_by: @barista,
      opened_at: Time.current,
      opening_cash: 0
    )
    assert new_shift.valid?
  end

  # ---------------------------------------------------------------------------
  # close! — status and timestamps
  # ---------------------------------------------------------------------------

  test "close! sets status to closed" do
    @shift.close!(@barista, 600)
    assert_equal "closed", @shift.status
  end

  test "close! sets closed_by to the given user" do
    @shift.close!(@barista, 600)
    assert_equal @barista, @shift.closed_by
  end

  test "close! sets closed_at to a recent timestamp" do
    before = Time.current
    @shift.close!(@barista, 600)
    assert @shift.closed_at >= before
  end

  test "close! sets closing_cash to the given amount" do
    @shift.close!(@barista, 750)
    assert_equal 750, @shift.closing_cash
  end

  # ---------------------------------------------------------------------------
  # close! — financial calculations
  # ---------------------------------------------------------------------------

  test "close! calculates total_sales as sum of all succeeded payment amounts" do
    order1 = create_order_for_shift!(total_amount: 200, final_amount: 200)
    create_cash_payment!(order: order1, amount: 200)

    order2 = create_order_for_shift!(total_amount: 300, final_amount: 300)
    create_card_payment!(order: order2, amount: 300)

    @shift.close!(@barista, 1000)
    assert_equal 500, @shift.total_sales
  end

  test "close! calculates total_refunds as sum of succeeded refund amounts" do
    order = create_order_for_shift!(total_amount: 200, final_amount: 200)
    payment = create_cash_payment!(order: order, amount: 200)
    create_succeeded_refund!(payment: payment, order: order, amount: 80)

    @shift.close!(@barista, 620)
    assert_equal 80, @shift.total_refunds
  end

  test "close! calculates expected_cash as opening_cash + cash_payments - total_refunds" do
    # opening_cash = 500 (from setup)
    order = create_order_for_shift!(total_amount: 300, final_amount: 300)
    payment = create_cash_payment!(order: order, amount: 300)
    create_succeeded_refund!(payment: payment, order: order, amount: 50)

    # expected: 500 + 300 - 50 = 750
    @shift.close!(@barista, 750)
    assert_equal 750, @shift.expected_cash
  end

  test "close! excludes non-cash payments from expected_cash" do
    # opening_cash = 500
    order = create_order_for_shift!(total_amount: 200, final_amount: 200)
    create_card_payment!(order: order, amount: 200)  # card — should NOT add to expected cash

    # expected: 500 + 0 - 0 = 500
    @shift.close!(@barista, 500)
    assert_equal 500, @shift.expected_cash
  end

  test "close! calculates cash_difference as closing_cash - expected_cash" do
    # opening_cash = 500, no orders => expected_cash = 500
    @shift.close!(@barista, 550)
    assert_equal 50, @shift.cash_difference
  end

  test "close! records negative cash_difference when drawer is short" do
    # opening_cash = 500, no orders => expected_cash = 500, closing = 450
    @shift.close!(@barista, 450)
    assert_equal(-50, @shift.cash_difference)
  end

  test "close! does not count failed refunds in total_refunds" do
    order = create_order_for_shift!(total_amount: 200, final_amount: 200)
    payment = create_cash_payment!(order: order, amount: 200)

    # failed refund — must not be counted
    Refund.create!(
      payment: payment,
      order: order,
      tenant: @tenant,
      amount: 100,
      reason: "Failed attempt",
      status: "failed"
    )

    @shift.close!(@barista, 700)
    assert_equal 0, @shift.total_refunds
  end

  test "close! with zero opening_cash and one cash order gives expected_cash equal to payment amount" do
    other_tenant, other_barista = create_tenant_with_barista!
    shift = CashShift.create!(
      tenant: other_tenant,
      status: "open",
      opened_by: other_barista,
      opened_at: Time.current,
      opening_cash: 0
    )
    order = Order.create!(
      tenant: other_tenant,
      cash_shift: shift,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "issued",
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )
    Payment.create!(
      order: order,
      tenant: other_tenant,
      amount: 150,
      method: "cash",
      provider: "manual",
      status: "succeeded",
      paid_at: Time.current
    )

    shift.close!(other_barista, 150)
    assert_equal 150, shift.expected_cash
    assert_equal 0, shift.cash_difference
  end
end
