# frozen_string_literal: true

require "test_helper"

class Shop::GuestOrderCancellationServiceTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(phone: "+79005556677")
    @session = {}
    Shop::CustomerSession.set_customer_id!(@session, @tenant.id, @customer.id)
  end

  test "guest can cancel accepted mobile order" do
    order = mobile_order!(status: :accepted)

    result = Shop::GuestOrderCancellationService.new(
      order: order,
      session: @session,
      tenant_id: @tenant.id
    ).call!

    assert_equal "cancelled", result.status
    assert_equal "guest", Shop::OrderCancellationPresenter.cancelled_by(result)
  end

  test "guest cannot cancel preparing order" do
    order = mobile_order!(status: :preparing)

    error = assert_raises(Shop::GuestOrderCancellationService::Error) do
      Shop::GuestOrderCancellationService.new(
        order: order,
        session: @session,
        tenant_id: @tenant.id
      ).call!
    end

    assert_includes error.message, "уже готовится"
  end

  test "guest can cancel pending_payment via payment journal" do
    order = mobile_order!(status: :pending_payment)
    Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "shop",
      status: :pending
    )

    result = Shop::GuestOrderCancellationService.new(
      order: order,
      session: @session,
      tenant_id: @tenant.id
    ).call!

    assert_equal "cancelled", result.status
    assert OrderStatusLog.exists?(order_id: order.id, status_to: "cancelled", source: "customer")
  end

  # ---------------------------------------------------------------------------
  # #40 Шаг 2 — pending_payment: локальная отмена без /v2/Cancel
  # ---------------------------------------------------------------------------

  test "[TDD] pending_payment cancel does not call TbankAdapter#cancel_payment" do
    order = mobile_order!(status: :pending_payment)
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-pending-local-1",
      status: :pending
    )

    calls = []
    adapter = Payments::TbankAdapter
    original = adapter.instance_method(:cancel_payment)
    adapter.define_method(:cancel_payment) do |**kwargs|
      calls << kwargs
      raise "unexpected TbankAdapter#cancel_payment for pending_payment"
    end

    begin
      result = Shop::GuestOrderCancellationService.new(
        order: order,
        session: @session,
        tenant_id: @tenant.id
      ).call!

      assert_equal "cancelled", result.status
      assert_equal "failed", payment.reload.status
      assert_empty calls
      assert_equal 0, Refund.where(payment_id: payment.id).count
    ensure
      adapter.define_method(:cancel_payment, original)
    end
  end

  test "[TDD] pending_payment cancel leaves succeeded payments untouched and still skips Cancel" do
    order = mobile_order!(status: :pending_payment)
    pending = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-pending-2",
      status: :pending
    )
    # Исторический succeeded на том же заказе не должен уходить в Cancel при guest cancel unpaid.
    other = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 50,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-old-succeeded",
      status: :succeeded
    )

    calls = []
    adapter = Payments::TbankAdapter
    original = adapter.instance_method(:cancel_payment)
    adapter.define_method(:cancel_payment) do |**kwargs|
      calls << kwargs
      raise "unexpected cancel_payment"
    end

    begin
      Shop::GuestOrderCancellationService.new(
        order: order,
        session: @session,
        tenant_id: @tenant.id
      ).call!

      assert_equal "cancelled", order.reload.status
      assert_equal "failed", pending.reload.status
      assert_equal "succeeded", other.reload.status
      assert_empty calls
    ensure
      adapter.define_method(:cancel_payment, original)
    end
  end

  private

  def mobile_order!(status:)
    Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202606-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: status,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
  end
end
