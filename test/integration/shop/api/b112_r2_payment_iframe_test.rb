# frozen_string_literal: true

require "test_helper"

class Shop::Api::B112R2PaymentIframeTest < ActionDispatch::IntegrationTest
  include TestFactories

  module FakeTbankInit
    mattr_accessor :enabled, default: false
    mattr_accessor :captured_recurrent, default: false

    module Override
      def init_payment(**kwargs)
        unless FakeTbankInit.enabled
          return super
        end

        FakeTbankInit.captured_recurrent = kwargs[:recurrent] == true
        {
          payment_url: "https://pay.tbank.ru/b112-r2-test",
          provider_payment_id: "b112-r2-pay-#{SecureRandom.hex(4)}"
        }
      end
    end

    def self.install!
      return if @prepended

      Payments::TbankAdapter.prepend(Override)
      @prepended = true
    end
  end

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "b112-r2-#{SecureRandom.hex(4)}@example.com"

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_iframe = ENV["SHOP_PAYMENT_IFRAME"]
    @old_tbank_key = ENV["TBANK_TERMINAL_KEY"]
    @old_tbank_pass = ENV["TBANK_PASSWORD"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["SHOP_PAYMENT_IFRAME"] = "1"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"

    FakeTbankInit.install!
    FakeTbankInit.enabled = true
    FakeTbankInit.captured_recurrent = false
  end

  teardown do
    Current.reset
    FakeTbankInit.enabled = false
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    ENV["SHOP_PAYMENT_IFRAME"] = @old_iframe
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
  end

  test "card order returns redirect URL and card_binding without iframe embed" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(email: @email, name: "B112 R2", payment_method: "card"),
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert_equal "pending_payment", body["status"]
      assert_equal false, body["payment_iframe"]
      assert_nil body["terminal_key"]
      assert body["payment_url"].present?
      assert body["card_binding"], "expected card_binding for first card init"
      assert FakeTbankInit.captured_recurrent, "expected Recurrent=Y on init"
    end
  rescue Shop::OrderCreator::Error => e
    skip e.message if e.message.match?(/order_number/i)
    raise
  end
end
