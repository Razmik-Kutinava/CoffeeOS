# frozen_string_literal: true

require "test_helper"

class Shop::Api::QaSection23Stage5E2eTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ActiveJob::TestHelper

  module FakeTbankInit
    mattr_accessor :provider_payment_id, default: nil

    module Override
      def init_payment(**)
        {
          payment_url: "https://pay.tbank.ru/stage5-test",
          provider_payment_id: FakeTbankInit.provider_payment_id
        }
      end
    end

    def self.install!
      return if @installed

      Payments::TbankAdapter.prepend(Override)
      @installed = true
    end
  end

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @customer = create_mobile_customer!(phone: "+79005556677")

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_tbank_key = ENV["TBANK_TERMINAL_KEY"]
    @old_tbank_pass = ENV["TBANK_PASSWORD"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"

    @provider_payment_id = "stage5-pay-#{SecureRandom.hex(4)}"
    FakeTbankInit.install!
    FakeTbankInit.provider_payment_id = @provider_payment_id

    Payments::CacheCounter.clear!
  end

  teardown do
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    if @old_tbank_key
      ENV["TBANK_TERMINAL_KEY"] = @old_tbank_key
    else
      ENV.delete("TBANK_TERMINAL_KEY")
    end
    if @old_tbank_pass
      ENV["TBANK_PASSWORD"] = @old_tbank_pass
    else
      ENV.delete("TBANK_PASSWORD")
    end
    Payments::CacheCounter.clear!
  end

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def tbank_payload(order_id:, status: "CONFIRMED")
    p = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => order_id.to_s,
      "PaymentId" => @provider_payment_id,
      "Status" => status,
      "Amount" => 17_900
    }
    p["Token"] = Payments::TbankAdapter.new.build_token(p)
    p
  end

  test "§2.3 stage 5.1: cart card order webhook CONFIRMED finalize accepted" do
    order_id = nil

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      sess.post "/shop/api/orders",
        headers: shop_headers,
        params: { phone: @customer.phone, name: "Stage5 QA", payment_method: "card" },
        as: :json
      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert_equal "pending_payment", body["status"]
      assert body["payment_url"].present?
      order_id = body["order_id"]

      sess.get "/shop/api/cart", headers: shop_headers
      cart = JSON.parse(sess.response.body)
      assert cart["items"].any?, "cart stays until payment succeeds"

      perform_enqueued_jobs do
        sess.post "/callbacks/tbank",
          params: tbank_payload(order_id: order_id).to_json,
          headers: { "Content-Type" => "application/json" }
      end
      assert_equal 200, sess.response.status

      sess.post "/shop/api/orders/#{order_id}/finalize",
        headers: shop_headers,
        as: :json
      finalize = JSON.parse(sess.response.body)
      assert_equal true, finalize["payment_settled"]
      assert_equal "accepted", finalize["status"]

      sess.get "/shop/api/cart", headers: shop_headers
      cart_after = JSON.parse(sess.response.body)
      assert cart_after["items"].empty?, "cart cleared after accepted finalize"
    end

    order = Order.find(order_id)
    assert_equal "accepted", order.status
    payment = order.payments.order(created_at: :desc).first
    assert_equal "succeeded", payment.status
    assert_equal @provider_payment_id, payment.provider_payment_id
  end
end
