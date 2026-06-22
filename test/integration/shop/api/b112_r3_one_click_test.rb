# frozen_string_literal: true

require "test_helper"

class Shop::Api::B112R3OneClickTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "b112-r3-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @card = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      card_token: "rebill-r3-test",
      card_masked: "430000******0777",
      card_brand: "Visa",
      payment_type: "card",
      is_active: true,
      is_default: true
    )
    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  test "GET saved_cards resolves customer by verified email param" do
    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.get "/shop/api/saved_cards",
        params: { email: @email },
        headers: { "X-Shop-Tenant" => @tenant.id.to_s }
      assert_equal 200, sess.response.status

      body = JSON.parse(sess.response.body)
      assert_equal @card.id, body.dig("primary", "id")
      assert_equal "Visa", body.dig("primary", "payment_system")
    end
  end

  test "POST orders with saved_card_id returns recurrent_charge" do
    klass = Payments::TbankAdapter
    orig_new = klass.method(:new)
    klass.define_singleton_method(:new) do
      inst = orig_new.call
      inst.define_singleton_method(:charge_recurrent) do |**_kwargs|
        { provider_payment_id: "charge-r3-1", charged: true }
      end
      inst.define_singleton_method(:get_payment_state) do |**|
        { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED", "PaymentId" => "charge-r3-1" }
      end
      inst
    end

    open_session do |sess|
      prepare_cart_and_email!(sess)

      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(
          email: @email,
          name: "R3 Guest",
          payment_method: "card",
          saved_card_id: @card.id
        ),
        as: :json

      assert_equal 200, sess.response.status
      body = JSON.parse(sess.response.body)
      assert body["recurrent_charge"], "expected recurrent_charge flag"
      assert_equal false, body["payment_iframe"]
      assert_nil body["payment_url"]
      assert_equal "charge-r3-1", body["provider_payment_id"]
      assert body["order_id"].present?
    end
  ensure
    klass.define_singleton_method(:new, orig_new)
  end

  test "POST orders saved_card charge error maps to 422 card message" do
    klass = Payments::TbankAdapter
    orig_new = klass.method(:new)
    klass.define_singleton_method(:new) do
      inst = orig_new.call
      inst.define_singleton_method(:charge_recurrent) do |**_kwargs|
        raise Payments::TbankAdapter::ApiError.new(error_code: "1051", message: "Insufficient funds on card")
      end
      inst
    end

    open_session do |sess|
      prepare_cart_and_email!(sess)

      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(
          email: @email,
          name: "R3 Guest",
          payment_method: "card",
          saved_card_id: @card.id
        ),
        as: :json

      assert_equal 422, sess.response.status
      body = JSON.parse(sess.response.body)
      assert_match(/недостаточно/i, body["error"].to_s)
    end
  ensure
    klass.define_singleton_method(:new, orig_new)
  end

  test "client_order_uuid idempotency on recurrent path" do
    klass = Payments::TbankAdapter
    orig_new = klass.method(:new)
    charge_calls = 0
    klass.define_singleton_method(:new) do
      inst = orig_new.call
      inst.define_singleton_method(:charge_recurrent) do |**_kwargs|
        charge_calls += 1
        { provider_payment_id: "charge-dup-#{charge_calls}", charged: true }
      end
      inst.define_singleton_method(:get_payment_state) do |**|
        { "Success" => true, "ErrorCode" => "0", "Status" => "AUTHORIZED", "PaymentId" => "charge-dup-1" }
      end
      inst
    end

    uuid = SecureRandom.uuid

    open_session do |sess|
      prepare_cart_and_email!(sess)

      2.times do
        sess.post "/shop/api/orders",
          headers: { "X-Shop-Tenant" => @tenant.id.to_s },
          params: shop_order_params(
            email: @email,
            name: "R3 Guest",
            payment_method: "card",
            saved_card_id: @card.id,
            client_order_uuid: uuid
          ),
          as: :json
        assert_equal 200, sess.response.status
      end

      assert_equal 1, charge_calls, "duplicate client_order_uuid must not charge twice"
    end
  ensure
    klass.define_singleton_method(:new, orig_new)
  end

  private

  def prepare_cart_and_email!(sess)
    sess.post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
  end
end
