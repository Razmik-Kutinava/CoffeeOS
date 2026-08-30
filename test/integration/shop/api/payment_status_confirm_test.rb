# frozen_string_literal: true

require "test_helper"

# Шаг 2 ТЗ: GET payments/status → GetState → если AUTHORIZED — auto Confirm → CONFIRMED
#
# Stub через flag-gated prepend (как shop_usercards_phase1) — НЕ define_method/remove_method
# на TbankAdapter: remove_method стирает настоящий #get_payment_state и ломает параллельные
# тесты с Override#get_payment_state → super (CI flake).
class Shop::Api::PaymentStatusConfirmTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  module FakeAuthorizedThenConfirm
    mattr_accessor :enabled, default: false
    mattr_accessor :confirm_called, default: false

    module Override
      def get_payment_state(payment_id:)
        return super unless FakeAuthorizedThenConfirm.enabled

        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "AUTHORIZED",
          "PaymentId" => payment_id.to_s
        }
      end

      def confirm_payment(payment_id:)
        return super unless FakeAuthorizedThenConfirm.enabled

        FakeAuthorizedThenConfirm.confirm_called = true
        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "CONFIRMED",
          "PaymentId" => payment_id.to_s
        }
      end
    end

    def self.install!
      return if @done

      Payments::TbankAdapter.prepend(Override)
      @done = true
    end
  end

  setup do
    FakeAuthorizedThenConfirm.install!
    FakeAuthorizedThenConfirm.enabled = true
    FakeAuthorizedThenConfirm.confirm_called = false

    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "confirm-#{SecureRandom.hex(4)}@example.com")
  end

  teardown do
    FakeAuthorizedThenConfirm.enabled = false
    FakeAuthorizedThenConfirm.confirm_called = false
    Current.reset
  end

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  test "GET payments/status triggers GetState+Confirm for AUTHORIZED and returns CONFIRMED [TDD]" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Status Confirm Guest",
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
      status: :processing,
      provider_payment_id: "pay-auth-1"
    )

    open_session do |sess|
      bind_shop_order_to_session!(sess, tenant_id: @tenant.id, order: order, email: @customer.email)
      sess.get "/shop/api/payments/status/#{order.id}", headers: shop_headers, as: :json
      assert_equal 200, sess.response.status
      body = JSON.parse(sess.response.body)
      assert_equal "CONFIRMED", body["status"]
      assert FakeAuthorizedThenConfirm.confirm_called, "ожидали auto Confirm при AUTHORIZED"
    end
  end
end
