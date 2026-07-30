# frozen_string_literal: true

require "test_helper"

class Shop::WidgetPaymentInitiatorTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "wpi-#{SecureRandom.hex(3)}")
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "W",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    @payment = Payment.create!(
      tenant_id: @tenant.id,
      order_id: @order.id,
      amount: 100,
      method: :card,
      status: :pending,
      provider: "pending"
    )
  end

  teardown { Current.reset }

  def confirmed_adapter(rebill_expect: nil)
    fake = Object.new
    fake.define_singleton_method(:charge_recurrent) do |**kw|
      raise "unexpected rebill #{kw[:rebill_id]}" if rebill_expect && kw[:rebill_id] != rebill_expect

      {
        provider_payment_id: "pid-charged",
        charge_response: {
          "Success" => true,
          "Status" => "CONFIRMED",
          "PaymentId" => "pid-charged",
          "ErrorCode" => "0"
        }
      }
    end
    fake
  end

  test "skips gateway when provider_payment_id already set and no rebill" do
    @payment.update_columns(provider_payment_id: "existing-pid")
    result = Shop::WidgetPaymentInitiator.call(
      order: @order,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/cb"
    )
    assert_equal "existing-pid", result[:provider_payment_id]
  end

  test "with rebill uses charge_recurrent and settles CONFIRMED" do
    MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-99",
      card_masked: "*1234",
      is_active: true,
      is_default: true
    )

    result = Shop::WidgetPaymentInitiator.call(
      order: @order,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/cb",
      adapter: confirmed_adapter(rebill_expect: "rebill-99")
    )

    assert_equal "pid-charged", result[:provider_payment_id]
    assert_equal "pid-charged", @payment.reload.provider_payment_id
    assert_predicate @payment, :succeeded?
    assert_predicate @order.reload, :accepted?
  end

  test "without rebill uses TbankInlineInit Widget path" do
    called = false
    captured_type = nil
    original = Payments::TbankInlineInit.method(:call)
    Payments::TbankInlineInit.define_singleton_method(:call) do |**kw|
      called = true
      captured_type = kw[:connection_type]
      { provider_payment_id: "pid-widget" }
    end

    begin
      result = Shop::WidgetPaymentInitiator.call(
        order: @order,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/cb"
      )
      assert_equal "pid-widget", result[:provider_payment_id]
      assert called
      assert_equal "Widget", captured_type
    ensure
      Payments::TbankInlineInit.define_singleton_method(:call, original)
    end
  end

  test "resolves rebill from extra_customer_ids" do
    other = create_mobile_customer!(email: "other-#{SecureRandom.hex(3)}@ex.com")
    MobilePaymentMethod.create!(
      customer_id: other.id,
      payment_type: "card",
      card_token: "rebill-session",
      card_masked: "*9999",
      is_active: true,
      is_default: true
    )

    Shop::WidgetPaymentInitiator.call(
      order: @order,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/cb",
      extra_customer_ids: [ other.id ],
      adapter: confirmed_adapter(rebill_expect: "rebill-session")
    )

    assert_equal "pid-charged", @payment.reload.provider_payment_id
  end
end
