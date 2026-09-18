# frozen_string_literal: true

require "test_helper"

class Subscriptions::ConfirmPaymentServiceTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "sub-confirm-#{SecureRandom.hex(3)}@ex.com")
    @plan = SubscriptionPlan.create!(
      code: "confirm_#{SecureRandom.hex(2)}",
      price: 499,
      currency: "RUB",
      period_days: 7,
      drink_limit: 5,
      discount_price_per_drink: 119,
      over_limit_discount_percent: 20,
      active: true
    )
    @pm = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-confirm-1",
      card_masked: "*4242",
      is_active: true,
      is_default: true
    )
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Sub",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 499,
      discount_amount: 0,
      final_amount: 499
    )
    @payment = Payment.create!(
      tenant_id: @tenant.id,
      order_id: @order.id,
      amount: 499,
      method: :card,
      status: :pending,
      provider: "tbank",
      provider_payment_id: "sub-confirm-unit",
      provider_data: {
        "subscription_intent" => true,
        "subscription_plan_id" => @plan.id,
        "subscription_payment_method_id" => @pm.id,
        "auto_renew" => true,
        "save_card" => false
      }
    )
  end

  teardown { Current.reset }

  test "GetState CONFIRMED activates subscription without barista accepted" do
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:get_payment_state) do |**|
      {
        "Success" => true,
        "ErrorCode" => "0",
        "Status" => "CONFIRMED",
        "PaymentId" => "sub-confirm-unit",
        "Amount" => 49_900
      }
    end

    sub = Subscriptions::ConfirmPaymentService.call(customer: @customer, adapter: adapter)
    assert_equal "active", sub.status
    assert_equal @plan.id, sub.plan_id
    assert @order.reload.closed?
    refute @order.accepted?
    assert @payment.reload.succeeded?
  end

  test "raises when no pending payment and no subscription" do
    @payment.destroy!
    @order.destroy!
    assert_raises(Subscriptions::ConfirmPaymentService::Error) do
      Subscriptions::ConfirmPaymentService.call(customer: @customer)
    end
  end
end
