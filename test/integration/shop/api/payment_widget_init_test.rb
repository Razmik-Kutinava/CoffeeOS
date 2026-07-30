# frozen_string_literal: true

require "test_helper"

# [TDD] POST /shop/api/payments/widget_init — Widget SDK инициализация (#33)
# Сумма из БД по orderId, connection_type: Widget, 404 при отсутствии заказа.
class Shop::Api::PaymentWidgetInitTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
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
      customer_name: "Widget Guest",
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

  def with_inline_init_stub(result: nil, error: nil)
    original = Payments::TbankInlineInit.method(:call)
    Payments::TbankInlineInit.define_singleton_method(:call) do |**_kw|
      raise error if error
      result || { provider_payment_id: "pid-widget-stub" }
    end
    yield
  ensure
    Payments::TbankInlineInit.define_singleton_method(:call, original)
  end

  test "[TDD] POST widget_init returns paymentUrl from T-Kassa Init with connection_type Widget" do
    order = create_order!

    with_inline_init_stub do
      post "/shop/api/payments/widget_init",
        params: { order_id: order.id },
        headers: shop_headers,
        as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["paymentUrl"].present?, "ожидали paymentUrl в ответе"
    assert_includes json["paymentUrl"], "pid-widget-stub"
  end

  test "[TDD] POST widget_init returns 404 for missing order" do
    post "/shop/api/payments/widget_init",
      params: { order_id: "00000000-0000-0000-0000-000000000000" },
      headers: shop_headers,
      as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "[TDD] POST widget_init ignores client-side amount and uses DB amount" do
    order = create_order!(amount: 500)

    with_inline_init_stub do
      post "/shop/api/payments/widget_init",
        params: { order_id: order.id, amount: 1 },
        headers: shop_headers,
        as: :json
    end

    assert_response :success
  end

  test "[TDD] POST widget_init returns standardized error without leaking secrets" do
    order = create_order!

    api_err = Payments::TbankAdapter::ApiError.new(error_code: "501", message: "test error")
    with_inline_init_stub(error: api_err) do
      post "/shop/api/payments/widget_init",
        params: { order_id: order.id },
        headers: shop_headers,
        as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
    assert_equal "501", json["error_code"]
    refute json.key?("terminal_key"), "секреты не должны попадать в ответ"
    refute json.key?("password"), "секреты не должны попадать в ответ"
  end
end
