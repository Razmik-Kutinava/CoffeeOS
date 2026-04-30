require "test_helper"

class RefundTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "Refund Test Cafe",
      slug: "refund-cafe-#{SecureRandom.hex(4)}",
      type: "sales_point",
      status: "active",
      currency: "RUB",
      country: "RU",
      timezone: "Europe/Moscow"
    )
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def create_payment_for_refund!(amount: 200)
    order = Order.create!(
      tenant: @tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "issued",
      total_amount: amount,
      discount_amount: 0,
      final_amount: amount
    )
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

  def build_refund(payment:, amount: 50, status: "pending", reason: "Customer request")
    Refund.new(
      payment: payment,
      order: payment.order,
      tenant: @tenant,
      amount: amount,
      reason: reason,
      status: status
    )
  end

  # ---------------------------------------------------------------------------
  # Validations — amount
  # ---------------------------------------------------------------------------

  test "is valid with a positive amount and a reason" do
    payment = create_payment_for_refund!(amount: 200)
    refund = build_refund(payment: payment, amount: 50)
    assert refund.valid?
  end

  test "is invalid when amount is zero" do
    payment = create_payment_for_refund!(amount: 200)
    refund = build_refund(payment: payment, amount: 0)
    assert_not refund.valid?
    assert refund.errors[:amount].any?
  end

  test "is invalid when amount is negative" do
    payment = create_payment_for_refund!(amount: 200)
    refund = build_refund(payment: payment, amount: -10)
    assert_not refund.valid?
    assert refund.errors[:amount].any?
  end

  # ---------------------------------------------------------------------------
  # Validations — reason
  # ---------------------------------------------------------------------------

  test "is invalid without a reason" do
    payment = create_payment_for_refund!(amount: 200)
    refund = build_refund(payment: payment, reason: nil)
    assert_not refund.valid?
    assert refund.errors[:reason].any?
  end

  test "is invalid when reason is blank" do
    payment = create_payment_for_refund!(amount: 200)
    refund = build_refund(payment: payment, reason: "")
    assert_not refund.valid?
    assert refund.errors[:reason].any?
  end

  # ---------------------------------------------------------------------------
  # amount_does_not_exceed_refundable — single refund
  # ---------------------------------------------------------------------------

  test "amount equal to payment amount is valid (full refund)" do
    payment = create_payment_for_refund!(amount: 200)
    refund = build_refund(payment: payment, amount: 200)
    assert refund.valid?
  end

  test "amount less than payment amount is valid (partial refund)" do
    payment = create_payment_for_refund!(amount: 200)
    refund = build_refund(payment: payment, amount: 99)
    assert refund.valid?
  end

  test "amount exceeding payment amount is invalid" do
    payment = create_payment_for_refund!(amount: 200)
    refund = build_refund(payment: payment, amount: 201)
    assert_not refund.valid?
    assert refund.errors[:amount].any?
  end

  # ---------------------------------------------------------------------------
  # amount_does_not_exceed_refundable — multiple partial refunds
  # ---------------------------------------------------------------------------

  test "sum of pending and succeeded refunds cannot exceed payment amount" do
    payment = create_payment_for_refund!(amount: 200)

    # First refund of 150 — succeeded
    Refund.create!(
      payment: payment,
      order: payment.order,
      tenant: @tenant,
      amount: 150,
      reason: "Partial refund",
      status: "succeeded"
    )

    # Second refund of 60 — would push total to 210
    second = build_refund(payment: payment, amount: 60)
    assert_not second.valid?
    assert second.errors[:amount].any?
  end

  test "partial refund is valid when remaining amount is sufficient" do
    payment = create_payment_for_refund!(amount: 200)

    Refund.create!(
      payment: payment,
      order: payment.order,
      tenant: @tenant,
      amount: 100,
      reason: "First partial",
      status: "succeeded"
    )

    second = build_refund(payment: payment, amount: 100)
    assert second.valid?
  end

  test "pending refund counts toward already refunded sum" do
    payment = create_payment_for_refund!(amount: 200)

    Refund.create!(
      payment: payment,
      order: payment.order,
      tenant: @tenant,
      amount: 180,
      reason: "Pending refund",
      status: "pending"
    )

    # Only 20 left; requesting 30 should fail
    second = build_refund(payment: payment, amount: 30)
    assert_not second.valid?
    assert second.errors[:amount].any?
  end

  test "failed refund does not count toward already refunded sum" do
    payment = create_payment_for_refund!(amount: 200)

    # This failed, so it must not consume any refundable amount
    Refund.create!(
      payment: payment,
      order: payment.order,
      tenant: @tenant,
      amount: 150,
      reason: "Failed attempt",
      status: "failed"
    )

    # Full amount should still be available
    refund = build_refund(payment: payment, amount: 200)
    assert refund.valid?
  end

  # ---------------------------------------------------------------------------
  # Editing an existing refund (where.not(id: id) exclusion)
  # ---------------------------------------------------------------------------

  test "editing an existing refund does not count its own amount against itself" do
    payment = create_payment_for_refund!(amount: 200)

    existing = Refund.create!(
      payment: payment,
      order: payment.order,
      tenant: @tenant,
      amount: 150,
      reason: "Original reason",
      status: "pending"
    )

    # Re-save without changing amount — the existing record must not block itself
    existing.reason = "Updated reason"
    assert existing.valid?
  end

  test "increasing an existing refund amount beyond refundable is invalid" do
    payment = create_payment_for_refund!(amount: 200)

    existing = Refund.create!(
      payment: payment,
      order: payment.order,
      tenant: @tenant,
      amount: 100,
      reason: "Original",
      status: "pending"
    )

    # Add a second refund consuming the remaining 100
    Refund.create!(
      payment: payment,
      order: payment.order,
      tenant: @tenant,
      amount: 100,
      reason: "Second refund",
      status: "succeeded"
    )

    # Try to increase first refund to 150 — only 0 remains outside of itself
    existing.amount = 150
    assert_not existing.valid?
    assert existing.errors[:amount].any?
  end
end
