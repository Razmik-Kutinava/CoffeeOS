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

  def with_inline_stub(result: nil, capture: nil)
    original = Payments::TbankInlineInit.method(:call)
    Payments::TbankInlineInit.define_singleton_method(:call) do |**kw|
      capture&.call(kw)
      result || { provider_payment_id: "pid-stub" }
    end
    yield
  ensure
    Payments::TbankInlineInit.define_singleton_method(:call, original)
  end

  test "skips Init when provider_payment_id already set" do
    @payment.update_columns(provider_payment_id: "existing-pid")
    called = false
    with_inline_stub(capture: ->(_) { called = true }) do
      result = Shop::WidgetPaymentInitiator.call(
        order: @order,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/cb"
      )
      assert_equal "existing-pid", result[:provider_payment_id]
      refute called
    end
  end

  test "passes rebill_id from primary saved card and updates payment" do
    MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-99",
      card_masked: "*1234",
      is_active: true,
      is_default: true
    )

    captured = nil
    sync_called = false
    original_sync = Payments::TbankPaymentSync.method(:sync_order!)
    Payments::TbankPaymentSync.define_singleton_method(:sync_order!) do |**_|
      sync_called = true
      true
    end

    begin
      with_inline_stub(
        result: { provider_payment_id: "pid-new" },
        capture: ->(kw) { captured = kw }
      ) do
        result = Shop::WidgetPaymentInitiator.call(
          order: @order,
          return_base_url: "https://example.com",
          notification_url: "https://example.com/cb"
        )
        assert_equal "pid-new", result[:provider_payment_id]
      end
    ensure
      Payments::TbankPaymentSync.define_singleton_method(:sync_order!, original_sync)
    end

    assert_equal "rebill-99", captured[:rebill_id]
    assert_equal "Widget", captured[:connection_type]
    assert_equal "pid-new", @payment.reload.provider_payment_id
    assert sync_called
  end

  test "resolves rebill from extra_customer_ids when order customer has no cards" do
    other = create_mobile_customer!(email: "other-#{SecureRandom.hex(3)}@ex.com")
    MobilePaymentMethod.create!(
      customer_id: other.id,
      payment_type: "card",
      card_token: "rebill-session",
      card_masked: "*9999",
      is_active: true,
      is_default: true
    )

    captured = nil
    original_sync = Payments::TbankPaymentSync.method(:sync_order!)
    Payments::TbankPaymentSync.define_singleton_method(:sync_order!) { |**_| true }

    begin
      with_inline_stub(
        result: { provider_payment_id: "pid-x" },
        capture: ->(kw) { captured = kw }
      ) do
        Shop::WidgetPaymentInitiator.call(
          order: @order,
          return_base_url: "https://example.com",
          notification_url: "https://example.com/cb",
          extra_customer_ids: [ other.id ]
        )
      end
    ensure
      Payments::TbankPaymentSync.define_singleton_method(:sync_order!, original_sync)
    end

    assert_equal "rebill-session", captured[:rebill_id]
  end
end
