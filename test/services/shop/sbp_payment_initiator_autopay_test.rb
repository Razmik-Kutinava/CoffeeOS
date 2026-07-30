# frozen_string_literal: true

require "test_helper"

# RED [TDD] #34 Шаг 1: Setup — save_sbp_account → Init Recurrent=Y + DATA QR.
class Shop::SbpPaymentInitiatorAutopayTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] ||= "TestTerminal"
    ENV["TBANK_PASSWORD"] ||= "TestPassword"
    ENV["TBANK_TAXATION"] ||= "usn_income"
    ENV["TBANK_TAX"] ||= "none"
  end

  teardown do
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
  end

  def build_pending_order!
    customer = create_mobile_customer!(email: "bind-#{SecureRandom.hex(3)}@example.com")
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: customer.id,
      customer_name: "SBP Bind",
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
    Order.includes(:order_items, :payments, :customer).find(order.id)
  end

  test "call! with save_sbp_account true passes recurrent Y and DATA QR to Init" do
    order = build_pending_order!
    captured_init = nil

    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:init_payment) do |**kwargs|
      captured_init = kwargs
      { payment_url: "https://pay.tbank.ru/unused", provider_payment_id: "pay-bind-1" }
    end

    qr = Object.new
    qr.define_singleton_method(:call!) do |payment_id:, adapter: nil|
      { payment_url: "https://qr.nspk.ru/AS10000BIND", data: "https://qr.nspk.ru/AS10000BIND" }
    end

    Shop::SbpPaymentInitiator.new(
      tenant: @tenant,
      adapter: adapter,
      qr_fetcher: qr
    ).call!(
      order_id: order.id,
      save_sbp_account: true,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/callbacks/tbank"
    )

    assert_equal true, captured_init[:recurrent],
      "[TDD] save_sbp_account → Init Recurrent=Y"
    data = captured_init[:data]
    data = JSON.parse(data) if data.is_a?(String)
    assert data.is_a?(Hash), "[TDD] Init DATA должен быть Hash/JSON"
    assert_equal "true", data["QR"].to_s.downcase.presence || data[:QR].to_s.downcase,
      "[TDD] DATA должен содержать QR=true"
  end

  test "call! without save_sbp_account keeps recurrent false (manual SBP)" do
    order = build_pending_order!
    captured_init = nil

    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:init_payment) do |**kwargs|
      captured_init = kwargs
      { payment_url: "https://pay.tbank.ru/unused", provider_payment_id: "pay-manual-1" }
    end

    qr = Object.new
    qr.define_singleton_method(:call!) do |payment_id:, adapter: nil|
      { payment_url: "https://qr.nspk.ru/AS10000MAN", data: "https://qr.nspk.ru/AS10000MAN" }
    end

    Shop::SbpPaymentInitiator.new(
      tenant: @tenant,
      adapter: adapter,
      qr_fetcher: qr
    ).call!(
      order_id: order.id,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/callbacks/tbank"
    )

    assert_equal false, captured_init[:recurrent]
  end
end
