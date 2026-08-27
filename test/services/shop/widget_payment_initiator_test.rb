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
    fake.define_singleton_method(:init_payment) do |**_kw|
      { provider_payment_id: "pid-charged", payment_url: "https://pay.example/pid-charged" }
    end
    fake.define_singleton_method(:charge) do |payment_id:, rebill_id:|
      raise "unexpected rebill #{rebill_id}" if rebill_expect && rebill_id != rebill_expect
      raise "unexpected pid #{payment_id}" if payment_id != "pid-charged"

      {
        "Success" => true,
        "Status" => "CONFIRMED",
        "PaymentId" => "pid-charged",
        "ErrorCode" => "0"
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

  test "with rebill uses Init+Charge and settles CONFIRMED" do
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

  test "#72 Init+Charge passes Receipt with customer contact" do
    category = create_category!
    product = create_product!(category: category)
    OrderItem.create!(
      order_id: @order.id,
      product_id: product.id,
      product_name: "Латте",
      quantity: 1,
      unit_price: 100,
      total_price: 100
    )
    MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-receipt",
      card_masked: "*9999",
      is_active: true,
      is_default: true
    )

    captured = nil
    fake = Object.new
    fake.define_singleton_method(:init_payment) do |**kw|
      captured = kw
      { provider_payment_id: "pid-receipt", payment_url: "https://pay.example/pid-receipt" }
    end
    fake.define_singleton_method(:charge) do |payment_id:, rebill_id:|
      {
        "Success" => true,
        "Status" => "CONFIRMED",
        "PaymentId" => payment_id,
        "ErrorCode" => "0"
      }
    end

    Shop::WidgetPaymentInitiator.call(
      order: @order.reload,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/cb",
      adapter: fake
    )

    assert captured[:receipt].is_a?(Hash), "Init должен получить Receipt"
    assert_equal @customer.phone, captured[:receipt]["Phone"]
  end

  # #46: после REJECTED Charge нельзя оставлять pid — иначе retry бьёт charge_existing! → Error 119.
  test "clears provider_payment_id when Charge fails [TDD #46]" do
    MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-fail",
      card_masked: "*0000",
      is_active: true,
      is_default: true
    )

    fake = Object.new
    fake.define_singleton_method(:init_payment) do |**_kw|
      { provider_payment_id: "pid-init-only" }
    end
    fake.define_singleton_method(:charge) do |**_kw|
      {
        "Success" => false,
        "Status" => "REJECTED",
        "ErrorCode" => "1051",
        "Message" => "Insufficient funds",
        "PaymentId" => "pid-init-only"
      }
    end

    assert_raises(Payments::TbankAdapter::ApiError) do
      Shop::WidgetPaymentInitiator.call(
        order: @order,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/cb",
        adapter: fake
      )
    end

    @payment.reload
    assert_nil @payment.provider_payment_id,
               "после fail Charge pid должен быть сброшен — иначе retry Charge same PaymentId (119)"
  end

  test "retry after Charge fail does fresh Init not charge_existing [TDD #46]" do
    MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-retry",
      card_masked: "*1111",
      is_active: true,
      is_default: true
    )

    init_pids = []
    charge_pids = []
    fake = Object.new
    fake.define_singleton_method(:init_payment) do |**_kw|
      pid = "pid-#{init_pids.size + 1}"
      init_pids << pid
      { provider_payment_id: pid }
    end
    fake.define_singleton_method(:charge) do |payment_id:, rebill_id:|
      charge_pids << payment_id
      if payment_id == "pid-1"
        {
          "Success" => false,
          "Status" => "REJECTED",
          "ErrorCode" => "119",
          "Message" => "Превышено допустимое количество запросов авторизации операции",
          "PaymentId" => payment_id
        }
      else
        {
          "Success" => true,
          "Status" => "CONFIRMED",
          "PaymentId" => payment_id,
          "ErrorCode" => "0"
        }
      end
    end

    assert_raises(Payments::TbankAdapter::ApiError) do
      Shop::WidgetPaymentInitiator.call(
        order: @order,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/cb",
        adapter: fake
      )
    end

    result = Shop::WidgetPaymentInitiator.call(
      order: @order,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/cb",
      adapter: fake
    )

    assert_equal [ "pid-1", "pid-2" ], init_pids, "retry должен Init заново"
    assert_equal [ "pid-1", "pid-2" ], charge_pids, "не Charge на тот же pid-1"
    assert_equal "pid-2", result[:provider_payment_id]
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
