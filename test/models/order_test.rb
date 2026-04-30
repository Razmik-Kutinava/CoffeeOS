require "test_helper"

class OrderTest < ActiveSupport::TestCase
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
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def build_order(overrides = {})
    Order.new({
      tenant: @tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    }.merge(overrides))
  end

  def create_order!(overrides = {})
    build_order(overrides).tap(&:save!)
  end

  # ---------------------------------------------------------------------------
  # Validations — amounts
  # ---------------------------------------------------------------------------

  test "is valid with correct amounts" do
    order = build_order(total_amount: 200, discount_amount: 50, final_amount: 150)
    assert order.valid?
  end

  test "is valid when discount is zero and final equals total" do
    order = build_order(total_amount: 100, discount_amount: 0, final_amount: 100)
    assert order.valid?
  end

  test "is invalid when total_amount is zero" do
    order = build_order(total_amount: 0)
    assert_not order.valid?
    assert order.errors[:total_amount].any?
  end

  test "is invalid when total_amount is negative" do
    order = build_order(total_amount: -1, final_amount: -1)
    assert_not order.valid?
    assert order.errors[:total_amount].any?
  end

  test "is invalid when discount_amount is negative" do
    order = build_order(discount_amount: -1, final_amount: 101)
    assert_not order.valid?
    assert order.errors[:discount_amount].any?
  end

  test "is invalid when final_amount is negative" do
    order = build_order(final_amount: -1)
    assert_not order.valid?
    assert order.errors[:final_amount].any?
  end

  test "amounts_consistency fails when final_amount does not equal total minus discount" do
    order = build_order(total_amount: 100, discount_amount: 10, final_amount: 80)
    assert_not order.valid?
    assert order.errors[:final_amount].any?
  end

  test "amounts_consistency passes when final_amount equals total minus discount" do
    order = build_order(total_amount: 300, discount_amount: 75, final_amount: 225)
    assert order.valid?
  end

  # ---------------------------------------------------------------------------
  # Validations — other fields
  # ---------------------------------------------------------------------------

  test "is invalid without source" do
    order = build_order(source: nil)
    assert_not order.valid?
    assert order.errors[:source].any?
  end

  test "is invalid without status" do
    order = build_order
    order.status = nil
    assert_not order.valid?
    assert order.errors[:status].any?
  end

  # ---------------------------------------------------------------------------
  # VALID_TRANSITIONS content
  # ---------------------------------------------------------------------------

  test "VALID_TRANSITIONS defines accepted can go to preparing" do
    assert_includes Order::VALID_TRANSITIONS["accepted"], "preparing"
  end

  test "VALID_TRANSITIONS defines accepted can go to cancelled" do
    assert_includes Order::VALID_TRANSITIONS["accepted"], "cancelled"
  end

  test "VALID_TRANSITIONS defines preparing can go to ready" do
    assert_includes Order::VALID_TRANSITIONS["preparing"], "ready"
  end

  test "VALID_TRANSITIONS defines preparing can go to cancelled" do
    assert_includes Order::VALID_TRANSITIONS["preparing"], "cancelled"
  end

  test "VALID_TRANSITIONS defines ready can go to issued" do
    assert_includes Order::VALID_TRANSITIONS["ready"], "issued"
  end

  test "VALID_TRANSITIONS defines ready can go to cancelled" do
    assert_includes Order::VALID_TRANSITIONS["ready"], "cancelled"
  end

  # ---------------------------------------------------------------------------
  # can_transition_to? — valid transitions
  # ---------------------------------------------------------------------------

  test "can_transition_to? returns true for accepted -> preparing" do
    order = build_order(status: "accepted")
    assert order.can_transition_to?("preparing")
  end

  test "can_transition_to? returns true for accepted -> cancelled" do
    order = build_order(status: "accepted")
    assert order.can_transition_to?("cancelled")
  end

  test "can_transition_to? returns true for preparing -> ready" do
    order = build_order(status: "preparing")
    assert order.can_transition_to?("ready")
  end

  test "can_transition_to? returns true for preparing -> cancelled" do
    order = build_order(status: "preparing")
    assert order.can_transition_to?("cancelled")
  end

  test "can_transition_to? returns true for ready -> issued" do
    order = build_order(status: "ready")
    assert order.can_transition_to?("issued")
  end

  test "can_transition_to? returns true for ready -> cancelled" do
    order = build_order(status: "ready")
    assert order.can_transition_to?("cancelled")
  end

  # ---------------------------------------------------------------------------
  # can_transition_to? — invalid transitions
  # ---------------------------------------------------------------------------

  test "can_transition_to? returns false for pending_payment -> preparing" do
    order = build_order(status: "pending_payment")
    assert_not order.can_transition_to?("preparing")
  end

  test "can_transition_to? returns false for accepted -> issued" do
    order = build_order(status: "accepted")
    assert_not order.can_transition_to?("issued")
  end

  test "can_transition_to? returns false for ready -> accepted" do
    order = build_order(status: "ready")
    assert_not order.can_transition_to?("accepted")
  end

  test "can_transition_to? returns false for issued -> anything" do
    order = build_order(status: "issued")
    assert_not order.can_transition_to?("closed")
    assert_not order.can_transition_to?("cancelled")
    assert_not order.can_transition_to?("preparing")
  end

  test "can_transition_to? returns false for closed -> anything" do
    order = build_order(status: "closed")
    assert_not order.can_transition_to?("issued")
    assert_not order.can_transition_to?("accepted")
  end

  test "can_transition_to? returns false for cancelled -> anything" do
    order = build_order(status: "cancelled")
    assert_not order.can_transition_to?("accepted")
    assert_not order.can_transition_to?("preparing")
    assert_not order.can_transition_to?("ready")
  end

  # ---------------------------------------------------------------------------
  # can_be_cancelled?
  # ---------------------------------------------------------------------------

  test "can_be_cancelled? returns true for accepted" do
    order = build_order(status: "accepted")
    assert order.can_be_cancelled?
  end

  test "can_be_cancelled? returns true for preparing" do
    order = build_order(status: "preparing")
    assert order.can_be_cancelled?
  end

  test "can_be_cancelled? returns true for ready" do
    order = build_order(status: "ready")
    assert order.can_be_cancelled?
  end

  test "can_be_cancelled? returns false for issued" do
    order = build_order(status: "issued")
    assert_not order.can_be_cancelled?
  end

  test "can_be_cancelled? returns false for closed" do
    order = build_order(status: "closed")
    assert_not order.can_be_cancelled?
  end

  test "can_be_cancelled? returns false for cancelled" do
    order = build_order(status: "cancelled")
    assert_not order.can_be_cancelled?
  end

  test "can_be_cancelled? returns false for pending_payment" do
    order = build_order(status: "pending_payment")
    assert_not order.can_be_cancelled?
  end

  # ---------------------------------------------------------------------------
  # can_change_status?
  # ---------------------------------------------------------------------------

  test "can_change_status? returns true for accepted" do
    order = build_order(status: "accepted")
    assert order.can_change_status?
  end

  test "can_change_status? returns false for issued" do
    order = build_order(status: "issued")
    assert_not order.can_change_status?
  end

  test "can_change_status? returns false for pending_payment" do
    order = build_order(status: "pending_payment")
    assert_not order.can_change_status?
  end

  # ---------------------------------------------------------------------------
  # qr_expired? and qr_valid?
  # ---------------------------------------------------------------------------

  test "qr_expired? returns false when qr_expires_at is nil" do
    order = build_order(qr_expires_at: nil)
    assert_not order.qr_expired?
  end

  test "qr_expired? returns false when qr_expires_at is in the future" do
    order = build_order(qr_expires_at: 1.hour.from_now)
    assert_not order.qr_expired?
  end

  test "qr_expired? returns true when qr_expires_at is in the past" do
    order = build_order(qr_expires_at: 1.hour.ago)
    assert order.qr_expired?
  end

  test "qr_valid? returns false when qr_token is nil" do
    order = build_order(qr_token: nil, qr_expires_at: 1.hour.from_now)
    assert_not order.qr_valid?
  end

  test "qr_valid? returns false when token is present but expired" do
    order = build_order(qr_token: SecureRandom.uuid, qr_expires_at: 1.hour.ago)
    assert_not order.qr_valid?
  end

  test "qr_valid? returns true when token is present and not expired" do
    order = build_order(qr_token: SecureRandom.uuid, qr_expires_at: 1.hour.from_now)
    assert order.qr_valid?
  end
end
