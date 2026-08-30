# frozen_string_literal: true

require "test_helper"

# RED [TDD] #34 Шаг 1: API sbp/init принимает save_sbp_account.
class Shop::Api::SbpInitSaveAccountTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
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
    customer = create_mobile_customer!(email: "api-bind-#{SecureRandom.hex(3)}@example.com")
    @order_customer_email = customer.email
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: customer.id,
      customer_name: "API Bind",
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

  test "POST sbp/init with save_sbp_account true returns payment_url and marks payment" do
    order = build_pending_order!

    open_session do |sess|
      bind_shop_order_to_session!(sess, tenant_id: @tenant.id, order: order, email: @order_customer_email)
      sess.post "/shop/api/payments/sbp/init",
        headers: shop_headers,
        params: { order_id: order.id, save_sbp_account: true },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = JSON.parse(sess.response.body)
      assert body["payment_url"].to_s.start_with?("https://qr.nspk.ru/"), body.inspect

      payment = order.payments.reload.first
      data = payment.provider_data.is_a?(Hash) ? payment.provider_data : {}
      assert ActiveModel::Type::Boolean.new.cast(data["save_sbp_account"]),
        "[TDD] provider_data[save_sbp_account] должен быть true для webhook ветки"
    end
  end
end
