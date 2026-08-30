# frozen_string_literal: true

require "test_helper"

# GREEN [TDD] Шаг 3: POST /shop/api/payments/sbp/init → { payment_url }.
class Shop::Api::SbpPaymentInitTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
    @customer = create_mobile_customer!(email: "sbp-init-#{SecureRandom.hex(4)}@example.com")

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  teardown do
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
  end

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def build_pending_order!
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "SBP API Guest",
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
      product_name: "Латте",
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

  def post_sbp_init!(order_id:, **params)
    result = nil
    open_session do |sess|
      order = Order.find(order_id)
      bind_shop_order_to_session!(sess, tenant_id: @tenant.id, order: order, email: @customer.email)
      sess.post "/shop/api/payments/sbp/init",
        headers: shop_headers,
        params: { order_id: order_id, **params },
        as: :json
      result = [ sess.response.status, JSON.parse(sess.response.body) ]
    end
    result
  end

  test "POST sbp/init returns payment_url for pending order" do
    order = build_pending_order!

    status, body = post_sbp_init!(order_id: order.id)
    assert_equal 200, status
    assert body["payment_url"].to_s.start_with?("https://qr.nspk.ru/"), body.inspect
  end

  test "POST sbp/init returns 404 when order missing" do
    post "/shop/api/payments/sbp/init",
      headers: shop_headers,
      params: { order_id: SecureRandom.uuid },
      as: :json

    assert_response :not_found
  end

  test "POST sbp/init returns 422 when order not pending_payment" do
    order = build_pending_order!
    order.update_columns(status: "accepted")

    status, _body = post_sbp_init!(order_id: order.id)
    assert_equal 422, status
  end

  test "routes declare POST payments/sbp/init" do
    assert_recognizes(
      { controller: "shop/api/payments", action: "sbp_init" },
      { path: "/shop/api/payments/sbp/init", method: :post }
    )
  end

  test "payments controller defines sbp_init action" do
    src = File.read(Rails.root.join("app/controllers/shop/api/payments_controller.rb"))
    assert_match(/\bdef sbp_init\b/, src)
  end

  test "POST sbp/init returns friendly message for bank code 3001" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    order = build_pending_order!

    klass = Shop::SbpPaymentInitiator.singleton_class
    klass.alias_method :__orig_new_for_sbp_test, :new
    klass.define_method(:new) do |*_args, **_kwargs|
      stub = Object.new
      stub.define_singleton_method(:call!) do |**_params|
        raise Shop::SbpPaymentInitiator::Error.new(
          "СБП сейчас недоступна для этой точки. Выберите оплату картой или попробуйте позже.",
          http_status: :unprocessable_entity,
          error_code: "3001"
        )
      end
      stub
    end

    begin
      status, body = post_sbp_init!(order_id: order.id)
    ensure
      klass.alias_method :new, :__orig_new_for_sbp_test
      klass.remove_method :__orig_new_for_sbp_test
    end

    assert_equal 422, status
    assert_equal "3001", body["error_code"]
    assert_match(/СБП сейчас недоступна.*оплату картой.*попробуйте позже/i, body["error"])
  end
end
