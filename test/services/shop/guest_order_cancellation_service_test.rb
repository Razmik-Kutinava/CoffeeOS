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

  # A6 MCP FAIL: после cancel кэш frequent иначе has_active_order=true
  test "guest cancel refreshes frequent products cache (not only delete)" do
    order = mobile_order!(status: :accepted)
    key = Shop::CustomerFrequentProductsService.cache_key(
      tenant_id: @tenant.id,
      customer_id: @customer.id
    )
    Rails.cache.write(
      key,
      { has_active_order: true, frequent_items: [] },
      expires_in: 30.minutes
    )

    Shop::GuestOrderCancellationService.new(
      order: order,
      session: @session,
      tenant_id: @tenant.id
    ).call!

    cached = Rails.cache.read(key)
    assert_not_nil cached, "refresh_cache! пишет свежий payload"
    assert_equal false, cached[:has_active_order], "после cancel has_active_order=false"
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

  # ---------------------------------------------------------------------------
  # #40 Шаг 4 — блок preparing / ready / issued (обход фронта)
  # ---------------------------------------------------------------------------

  test "[TDD] guest cannot cancel ready order; payment and Cancel untouched" do
    order = mobile_order!(status: :ready)
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-ready-block",
      status: :succeeded,
      paid_at: Time.current
    )

    calls = []
    with_stubbed_cancel_payment(calls: calls) do
      error = assert_raises(Shop::GuestOrderCancellationService::Error) do
        Shop::GuestOrderCancellationService.new(
          order: order,
          session: @session,
          tenant_id: @tenant.id
        ).call!
      end

      assert_includes error.message, "уже готовится"
      assert_equal "ready", order.reload.status
      assert_equal "succeeded", payment.reload.status
      assert_empty calls
    end
  end

  test "[TDD] guest cannot cancel issued order; payment and Cancel untouched" do
    order = mobile_order!(status: :issued)
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-issued-block",
      status: :succeeded,
      paid_at: Time.current
    )

    calls = []
    with_stubbed_cancel_payment(calls: calls) do
      assert_raises(Shop::GuestOrderCancellationService::Error) do
        Shop::GuestOrderCancellationService.new(
          order: order,
          session: @session,
          tenant_id: @tenant.id
        ).call!
      end

      assert_equal "issued", order.reload.status
      assert_equal "succeeded", payment.reload.status
      assert_empty calls
    end
  end

  test "[TDD] preparing with succeeded payment rejects without Cancel" do
    order = mobile_order!(status: :preparing)
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-preparing-block",
      status: :succeeded,
      paid_at: Time.current
    )

    calls = []
    with_stubbed_cancel_payment(calls: calls) do
      assert_raises(Shop::GuestOrderCancellationService::Error) do
        Shop::GuestOrderCancellationService.new(
          order: order,
          session: @session,
          tenant_id: @tenant.id
        ).call!
      end

      assert_equal "preparing", order.reload.status
      assert_equal "succeeded", payment.reload.status
      assert_empty calls
    end
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

  # ---------------------------------------------------------------------------
  # #40 Шаг 3 RED — accepted + succeeded → /v2/Cancel → payment refunded
  # ---------------------------------------------------------------------------

  test "[TDD] accepted cancel with succeeded payment calls Cancel and marks refunded" do
    order = mobile_order!(status: :accepted)
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-accepted-ok",
      status: :succeeded,
      paid_at: Time.current
    )

    calls = []
    with_stubbed_cancel_payment(calls: calls, response: {
      "Success" => true,
      "ErrorCode" => "0",
      "Status" => "REFUNDED",
      "PaymentId" => "pay-accepted-ok"
    }) do
      result = Shop::GuestOrderCancellationService.new(
        order: order,
        session: @session,
        tenant_id: @tenant.id
      ).call!

      assert_equal "cancelled", result.status
      assert_equal "refunded", payment.reload.status
      assert_equal 1, calls.size
      assert_equal "pay-accepted-ok", calls.first[:payment_id].to_s
      assert_equal 1, Refund.where(payment_id: payment.id, status: :succeeded).count
    end
  end

  test "[TDD] accepted cancel rejects when payment is failed (no Cancel)" do
    order = mobile_order!(status: :accepted)
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-failed",
      status: :failed
    )

    calls = []
    with_stubbed_cancel_payment(calls: calls) do
      error = assert_raises(Shop::GuestOrderCancellationService::Error) do
        Shop::GuestOrderCancellationService.new(
          order: order,
          session: @session,
          tenant_id: @tenant.id
        ).call!
      end

      assert_match(/возврат|оплат|недоступ/i, error.message)
      assert_equal "accepted", order.reload.status
      assert_equal "failed", payment.reload.status
      assert_empty calls
    end
  end

  test "[TDD] accepted cancel rejects when payment is already refunded (no Cancel)" do
    order = mobile_order!(status: :accepted)
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-already-refunded",
      status: :refunded
    )

    calls = []
    with_stubbed_cancel_payment(calls: calls) do
      assert_raises(Shop::GuestOrderCancellationService::Error) do
        Shop::GuestOrderCancellationService.new(
          order: order,
          session: @session,
          tenant_id: @tenant.id
        ).call!
      end

      assert_equal "accepted", order.reload.status
      assert_equal "refunded", payment.reload.status
      assert_empty calls
    end
  end

  test "[TDD] accepted cancel leaves order and payment unchanged when Cancel ApiError" do
    order = mobile_order!(status: :accepted)
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: order.final_amount,
      method: :card,
      provider: "tbank",
      provider_payment_id: "pay-bank-fail",
      status: :succeeded,
      paid_at: Time.current
    )

    calls = []
    with_stubbed_cancel_payment(
      calls: calls,
      raise_error: Payments::TbankAdapter::ApiError.new(error_code: "504", message: "Timeout")
    ) do
      error = assert_raises(Shop::GuestOrderCancellationService::Error) do
        Shop::GuestOrderCancellationService.new(
          order: order,
          session: @session,
          tenant_id: @tenant.id
        ).call!
      end

      assert_equal Shop::GuestOrderCancellationService::REFUND_UNAVAILABLE, error.message
      assert_equal "accepted", order.reload.status
      assert_equal "succeeded", payment.reload.status
      assert_equal 1, calls.size
      assert_equal 0, Refund.where(payment_id: payment.id).count
    end
  end

  private

  def with_stubbed_cancel_payment(calls:, response: nil, raise_error: nil)
    adapter = Payments::TbankAdapter
    original = adapter.instance_method(:cancel_payment)
    adapter.define_method(:cancel_payment) do |**kwargs|
      calls << kwargs
      raise raise_error if raise_error
      response || {
        "Success" => true,
        "ErrorCode" => "0",
        "Status" => "REFUNDED",
        "PaymentId" => kwargs[:payment_id].to_s
      }
    end
    yield
  ensure
    adapter.define_method(:cancel_payment, original)
  end

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
