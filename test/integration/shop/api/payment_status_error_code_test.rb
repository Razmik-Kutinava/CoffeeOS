# frozen_string_literal: true

require "test_helper"

# GET /shop/api/payments/status/:order_id — enriched error_code for inline inline-tbank button UX (Шаг 4).
class Shop::Api::PaymentStatusErrorCodeTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "errcode-#{SecureRandom.hex(4)}@example.com")
  end

  teardown do
    Current.reset
  end

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  test "GET payments/status returns error_code for REJECTED payment (ErrorCode=1051)" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "ErrCode Guest",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )

    Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 200,
      method: :sbp,
      provider: "tbank",
      status: :failed,
      provider_data: {
        "ErrorCode" => "1051",
        "Message" => "Недостаточно средств"
      }
    )

    open_session do |sess|
      bind_shop_order_to_session!(sess, tenant_id: @tenant.id, order: order, email: @customer.email)
      sess.get "/shop/api/payments/status/#{order.id}", headers: shop_headers, as: :json
      assert_equal 200, sess.response.status
      body = JSON.parse(sess.response.body)
      assert_equal "REJECTED", body["status"]
      assert_equal "1051", body["error_code"]
    end
  end
end
