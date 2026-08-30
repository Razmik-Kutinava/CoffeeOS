# frozen_string_literal: true

require "test_helper"

class Manager::ShiftCloseServiceTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!(slug: "shift-close-#{SecureRandom.hex(3)}")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "sc-barista@test.local")
    @manager = create_user!(tenant: @tenant, role_codes: %w[shift_manager], email: "sc-mgr@test.local")
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
  end

  test "closes shift and leaves preparing orders untouched" do
    preparing = shift_order!(status: "preparing", number: "PREP-1")

    result = call_service!

    assert_equal "closed", result.status
    assert_equal "preparing", preparing.reload.status
  end

  test "ready order with tbank payment is cancelled and refunded on close" do
    ready = shift_order!(status: "ready", number: "RDY-1")
    payment = Payment.create!(
      order_id: ready.id,
      tenant_id: @tenant.id,
      amount: ready.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-ready-close",
      status: :succeeded,
      paid_at: Time.current
    )

    calls = []
    with_stubbed_cancel_payment(calls: calls) do
      call_service!
    end

    assert_equal "cancelled", ready.reload.status
    assert_equal "Смена закрыта, заказ не забран", ready.cancel_reason
    assert_equal "refunded", payment.reload.status
    assert_equal 1, Refund.where(payment_id: payment.id, status: :succeeded).count
    assert_equal 1, calls.size
    log = OrderStatusLog.find_by(order_id: ready.id, status_to: "cancelled")
    assert_equal "system", log.source
  end

  test "ready cash order is cancelled locally without tbank call" do
    ready = shift_order!(status: "ready", number: "RDY-CASH")
    Payment.create!(
      order_id: ready.id,
      tenant_id: @tenant.id,
      amount: ready.final_amount,
      method: :cash,
      provider: "shop",
      status: :succeeded,
      paid_at: Time.current
    )

    calls = []
    with_stubbed_cancel_payment(calls: calls) do
      call_service!
    end

    assert_equal "cancelled", ready.reload.status
    assert_empty calls
    assert_equal 0, Refund.where(order_id: ready.id).count
  end

  test "tbank failure on ready order aborts close and rolls back prior ready cancels" do
    first = shift_order!(status: "ready", number: "RDY-A")
    second = shift_order!(status: "ready", number: "RDY-B")
    pay_a = Payment.create!(
      order_id: first.id, tenant_id: @tenant.id, amount: first.final_amount,
      method: :card, provider: "tbank", provider_payment_id: "pay-a",
      status: :succeeded, paid_at: Time.current
    )
    pay_b = Payment.create!(
      order_id: second.id, tenant_id: @tenant.id, amount: second.final_amount,
      method: :card, provider: "tbank", provider_payment_id: "pay-b",
      status: :succeeded, paid_at: Time.current
    )

    calls = []
    with_stubbed_cancel_payment(
      calls: calls,
      on_call: ->(kwargs) {
        raise Payments::TbankAdapter::ApiError.new(error_code: "504", message: "Timeout") if kwargs[:payment_id] == "pay-b"
        { "Success" => true, "PaymentId" => kwargs[:payment_id] }
      }
    ) do
      error = assert_raises(Manager::ShiftCloseService::Error) { call_service! }
      assert_includes error.message, "RDY-B"
    end

    assert_equal "open", @shift.reload.status
    assert_equal "ready", first.reload.status
    assert_equal "ready", second.reload.status
    assert_equal "succeeded", pay_a.reload.status
    assert_equal "succeeded", pay_b.reload.status
    assert_equal 1, calls.size
  end

  test "enqueues telegram alert when preparing orders remain" do
    shift_order!(status: "preparing", number: "PREP-TG")

    assert_enqueued_with(job: TelegramAlertJob) do
      call_service!
    end
  end

  private

  def shift_order!(status:, number:)
    Order.create!(
      tenant: @tenant, cash_shift: @shift, order_number: number,
      source: "manual", status: status,
      total_amount: 200, discount_amount: 0, final_amount: 200
    )
  end

  def call_service!
    Manager::ShiftCloseService.call!(
      shift: @shift,
      closed_by: @manager,
      closing_cash: 0
    )
  end

  def with_stubbed_cancel_payment(calls:, response: nil, on_call: nil, raise_error: nil)
    adapter = Payments::TbankAdapter
    original = adapter.instance_method(:cancel_payment)
    adapter.define_method(:cancel_payment) do |**kwargs|
      calls << kwargs
      raise raise_error if raise_error
      return on_call.call(kwargs) if on_call

      response || { "Success" => true, "PaymentId" => kwargs[:payment_id].to_s }
    end
    yield
  ensure
    adapter.define_method(:cancel_payment, original)
  end
end
