# frozen_string_literal: true

require "test_helper"

# TASK_93-K T-K3: adapter_payment_url — no fake tinkoff URL in production.
class Shop::Api::WidgetPaymentUrlTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "payurl-#{SecureRandom.hex(4)}@example.com")
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    @prev_env = Rails.env
  end

  teardown do
    Rails.env = @prev_env
    Current.reset
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def create_order!(amount: 350)
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "PayUrl Guest",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: amount,
      discount_amount: 0,
      final_amount: amount
    )
    Payment.create!(
      tenant_id: @tenant.id,
      order_id: order.id,
      amount: amount,
      method: :card,
      status: :pending,
      provider: "pending"
    )
    order
  end

  def with_inline_init_stub(result:)
    original = Payments::TbankInlineInit.method(:call)
    Payments::TbankInlineInit.define_singleton_method(:call) do |**_kw|
      result
    end
    yield
  ensure
    Payments::TbankInlineInit.define_singleton_method(:call, original)
  end

  def post_widget_init!(order_id:)
    result = nil
    open_session do |sess|
      order = Order.find(order_id)
      bind_shop_order_to_session!(sess, tenant_id: @tenant.id, order: order, email: @customer.email)
      clear_shop_payment_step_up!(customer: @customer, tenant_id: @tenant.id, session: sess)
      sess.post "/shop/api/payments/widget_init",
        params: { order_id: order_id },
        headers: shop_headers,
        as: :json
      result = [ sess.response.status, sess.response.parsed_body ]
    end
    result
  end

  def adapter_payment_url(result)
    Shop::Api::PaymentsController.new.send(:adapter_payment_url, result)
  end

  test "T-K3a production blank payment_url raises without fake tinkoff fallback" do
    Rails.env = ActiveSupport::StringInquirer.new("production")
    pid = "pid-no-url-#{SecureRandom.hex(3)}"

    err = assert_raises(Shop::WidgetPaymentInitiator::Error) do
      adapter_payment_url(provider_payment_id: pid)
    end
    assert_match(/PaymentURL|payment.?url/i, err.message)
    refute_match(%r{securepayments\.tinkoff\.ru/}i, err.message)
  end

  test "T-K3a production non-http payment_url raises without fake tinkoff fallback" do
    Rails.env = ActiveSupport::StringInquirer.new("production")

    err = assert_raises(Shop::WidgetPaymentInitiator::Error) do
      adapter_payment_url(provider_payment_id: "pid-rel", payment_url: "not-a-url")
    end
    assert_match(/PaymentURL|payment.?url/i, err.message)
    refute_match(%r{securepayments\.tinkoff\.ru/}i, err.message)
  end

  test "T-K3b valid https PaymentURL returned as-is via widget_init" do
    order = create_order!
    url = "https://securepay.tinkoff.ru/real-#{SecureRandom.hex(3)}"

    with_inline_init_stub(result: {
      provider_payment_id: "pid-ok",
      payment_url: url
    }) do
      status, json = post_widget_init!(order_id: order.id)
      assert_equal 200, status
      assert_equal url, json["paymentUrl"]
    end
  end

  test "T-K3b test env still allows fallback when PaymentURL blank" do
    order = create_order!
    pid = "pid-fallback-#{SecureRandom.hex(3)}"

    with_inline_init_stub(result: { provider_payment_id: pid }) do
      status, json = post_widget_init!(order_id: order.id)
      assert_equal 200, status
      assert_equal "https://securepayments.tinkoff.ru/#{pid}", json["paymentUrl"]
    end
  end
end
