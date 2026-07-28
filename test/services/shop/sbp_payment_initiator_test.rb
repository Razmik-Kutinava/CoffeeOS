# frozen_string_literal: true

require "test_helper"

# GREEN [TDD] Шаг 3: SbpPaymentInitiator — Init+Receipt → GetQr → payment_url.
class Shop::SbpPaymentInitiatorTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_tax = ENV["TBANK_TAXATION"]
    @old_vat = ENV["TBANK_TAX"]
    ENV["TBANK_TAXATION"] = "usn_income"
    ENV["TBANK_TAX"] = "none"
    ENV["TBANK_TERMINAL_KEY"] ||= "TestTerminal"
    ENV["TBANK_PASSWORD"] ||= "TestPassword"
  end

  teardown do
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    restore_env("TBANK_TAXATION", @old_tax)
    restore_env("TBANK_TAX", @old_vat)
  end

  def restore_env(key, value)
    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end
  end

  def build_pending_order!
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_name: "SBP Guest",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    OrderItem.create!(
      order_id: order.id,
      product_id: @product.id,
      product_name: "Капучино",
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )
    Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 200,
      method: :sbp,
      provider: "tbank",
      status: :pending
    )
    order
  end

  test "call! in simulate mode returns fictional nspk payment_url without bank" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
    order = build_pending_order!

    result = Shop::SbpPaymentInitiator.new(tenant: @tenant).call!(order_id: order.id)

    assert result[:payment_url].start_with?("https://qr.nspk.ru/")
    assert_includes result[:payment_url], "SIMULATE"
    assert_equal order.id, result[:order_id]
  end

  test "call! live mode runs Init with Receipt then GetQr and returns nspk url" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    order = build_pending_order!
    order = Order.includes(:order_items, :payments).find(order.id)

    captured_init = nil
    captured_qr_payment_id = nil
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:init_payment) do |**kwargs|
      captured_init = kwargs
      { payment_url: "https://pay.tbank.ru/unused", provider_payment_id: "pay-sbp-1" }
    end

    qr = Object.new
    qr.define_singleton_method(:call!) do |payment_id:, adapter: nil|
      captured_qr_payment_id = payment_id
      { payment_url: "https://qr.nspk.ru/AS10000SBP", data: "https://qr.nspk.ru/AS10000SBP" }
    end

    result = Shop::SbpPaymentInitiator.new(
      tenant: @tenant,
      adapter: adapter,
      qr_fetcher: qr
    ).call!(
      order_id: order.id,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/callbacks/tbank"
    )

    assert_equal "https://qr.nspk.ru/AS10000SBP", result[:payment_url]
    assert_equal "pay-sbp-1", result[:provider_payment_id]
    assert_equal "pay-sbp-1", captured_qr_payment_id
    assert captured_init[:receipt].is_a?(Hash), "Init должен получить Receipt 54-ФЗ"
    assert_equal "usn_income", captured_init[:receipt]["Taxation"]
    assert order.payments.reload.first.provider_payment_id == "pay-sbp-1"
  end

  test "call! live puts customer email into Receipt for 54-ФЗ" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    customer = create_mobile_customer!(email: "aram-sbp@example.com")
    order = build_pending_order!
    order.update_columns(customer_id: customer.id)
    order = Order.includes(:order_items, :payments, :customer).find(order.id)

    captured_init = nil
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:init_payment) do |**kwargs|
      captured_init = kwargs
      { payment_url: "https://pay.tbank.ru/unused", provider_payment_id: "pay-sbp-mail" }
    end
    qr = Object.new
    qr.define_singleton_method(:call!) do |payment_id:, adapter: nil|
      { payment_url: "https://qr.nspk.ru/AS10000MAIL", data: "https://qr.nspk.ru/AS10000MAIL" }
    end

    Shop::SbpPaymentInitiator.new(tenant: @tenant, adapter: adapter, qr_fetcher: qr).call!(
      order_id: order.id,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/callbacks/tbank"
    )

    assert_equal "aram-sbp@example.com", captured_init[:receipt]["Email"]
  end

  test "call! raises Error when order is missing" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
    assert_raises(Shop::SbpPaymentInitiator::Error) do
      Shop::SbpPaymentInitiator.new(tenant: @tenant).call!(order_id: SecureRandom.uuid)
    end
  end

  test "call! raises Error when order is not pending_payment" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
    order = build_pending_order!
    order.update_columns(status: "accepted")

    assert_raises(Shop::SbpPaymentInitiator::Error) do
      Shop::SbpPaymentInitiator.new(tenant: @tenant).call!(order_id: order.id)
    end
  end

  test "call! raises on bank transport failure" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    order = build_pending_order!

    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:init_payment) do |**_kwargs|
      raise Payments::TbankAdapter::Error, "Таймаут запроса к Т-Банку"
    end

    assert_raises(Shop::SbpPaymentInitiator::Error) do
      Shop::SbpPaymentInitiator.new(tenant: @tenant, adapter: adapter).call!(
        order_id: order.id,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/callbacks/tbank"
      )
    end
  end

  test "call! maps bank 3001 into friendly sbp unavailable message" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    order = build_pending_order!

    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:init_payment) do |**_kwargs|
      raise Payments::TbankAdapter::ApiError.new(
        error_code: "3001",
        message: "Оплата через СБП недоступна"
      )
    end

    error = assert_raises(Shop::SbpPaymentInitiator::Error) do
      Shop::SbpPaymentInitiator.new(tenant: @tenant, adapter: adapter).call!(
        order_id: order.id,
        return_base_url: "https://example.com",
        notification_url: "https://example.com/callbacks/tbank"
      )
    end

    assert_equal "3001", error.error_code
    assert_equal :unprocessable_entity, error.http_status
    assert_match(/СБП сейчас недоступна.*оплату картой.*попробуйте позже/i, error.message)
  end
end
