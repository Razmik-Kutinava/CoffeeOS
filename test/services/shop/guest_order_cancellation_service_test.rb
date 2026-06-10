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
