# frozen_string_literal: true

require "test_helper"

# TASK_93-B — Checkout identity phone-first (T-B4 / T-B5)
class Shop::Api::CheckoutIdentityTest < ActionDispatch::IntegrationTest
  include TestFactories

  module FakeTbankIdentity
    mattr_accessor :enabled, default: false
    mattr_accessor :last_charge, default: nil

    module Override
      def charge_recurrent(**kwargs)
        return super unless FakeTbankIdentity.enabled

        FakeTbankIdentity.last_charge = kwargs[:rebill_id]
        pid = "pay-id-#{SecureRandom.hex(3)}"
        {
          payment_url: nil,
          provider_payment_id: pid,
          charged: true,
          charge_response: {
            "Success" => true,
            "ErrorCode" => "0",
            "Status" => "CONFIRMED",
            "PaymentId" => pid
          },
          status: "CONFIRMED",
          three_ds: false
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
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
    FakeTbankIdentity.install!
    FakeTbankIdentity.enabled = false
    FakeTbankIdentity.last_charge = nil
  end

  def add_cart!(sess)
    sess.post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_equal 200, sess.response.status, sess.response.body
  end

  def phone_customer!(phone: nil)
    phone ||= "+7900#{rand(1000000..9999999)}"
    MobileCustomer.create!(
      phone: phone,
      email: nil,
      first_name: "Phone",
      is_active: true,
      phone_verified: true,
      phone_status: :verified
    )
  end

  # T-B5a
  test "phone verified POST orders succeeds without email confirm error" do
    customer = phone_customer!

    open_session do |sess|
      add_cart!(sess)
      sess.get "/shop/api/config", headers: shop_tenant_headers(@tenant.id), as: :json
      Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, customer.id)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: { name: "Phone Pay", email: "", payment_method: "card" },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      refute_match(/подтвердите email|укажите email/i, body["error"].to_s)
      assert body["id"].present? || body["order_id"].present? || body["status"].present?
      assert_equal customer.id, Order.find(body["id"] || body["order_id"]).customer_id
    end
  end

  # T-B5b
  test "email verified without phone POST orders succeeds" do
    email = "id-b5b-#{SecureRandom.hex(3)}@example.com"

    open_session do |sess|
      add_cart!(sess)
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: email, name: "Email Pay", payment_method: "card"),
        as: :json

      assert_equal 200, sess.response.status, sess.response.body
    end
  end

  # T-B5c
  test "no identity POST orders returns 422 about phone or email" do
    open_session do |sess|
      add_cart!(sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: { name: "Anon", email: "", payment_method: "card" },
        as: :json

      assert_equal 422, sess.response.status
      err = sess.response.parsed_body["error"].to_s
      assert_match(/телефон|email/i, err)
      refute_equal "Укажите email", err # phone-first: not email-only copy
    end
  end

  # T-B4a
  test "GET user/cards with phone session customer no email returns 200" do
    customer = phone_customer!

    open_session do |sess|
      sess.get "/shop/api/config", headers: shop_tenant_headers(@tenant.id), as: :json
      Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, customer.id)

      sess.get "/shop/api/user/cards",
        headers: shop_tenant_headers(@tenant.id),
        as: :json

      assert_equal 200, sess.response.status, sess.response.body
      json = JSON.parse(sess.response.body)
      assert json.key?("cards")
      assert json.key?("sbp_accounts")
      assert_kind_of Array, json["cards"]
      assert_kind_of Array, json["sbp_accounts"]
    end
  end

  # T-B5d
  test "phone verified one_click with foreign card returns ownership 422" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] ||= "TestTerminal"
    ENV["TBANK_PASSWORD"] ||= "TestPassword"
    FakeTbankIdentity.enabled = true

    owner = phone_customer!
    thief = phone_customer!
    foreign_card = MobilePaymentMethod.create!(
      customer_id: owner.id,
      payment_type: "card",
      card_token: "rebill-foreign-#{SecureRandom.hex(3)}",
      card_masked: "*9999",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )

    open_session do |sess|
      add_cart!(sess)
      sess.get "/shop/api/config", headers: shop_tenant_headers(@tenant.id), as: :json
      Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, thief.id)
      clear_shop_payment_step_up!(customer: thief, tenant_id: @tenant.id, session: sess)

      sess.post "/shop/api/payments/one_click",
        headers: shop_tenant_headers(@tenant.id),
        params: {
          name: "Thief",
          email: "",
          payment_method: "card",
          card_id: foreign_card.id,
          amount: 179
        },
        as: :json

      assert_equal 422, sess.response.status, sess.response.body
      err = sess.response.parsed_body["error"].to_s
      assert_match(/не принадлежит|карта/i, err)
      refute_match(/подтвердите email|укажите email/i, err)
    end
  ensure
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
    FakeTbankIdentity.enabled = false
  end

  # T-B5e
  test "phone verified one_click with own card is not identity 422" do
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] ||= "TestTerminal"
    ENV["TBANK_PASSWORD"] ||= "TestPassword"
    FakeTbankIdentity.enabled = true

    customer = phone_customer!
    card = MobilePaymentMethod.create!(
      customer_id: customer.id,
      payment_type: "card",
      card_token: "rebill-own-#{SecureRandom.hex(3)}",
      card_masked: "*1111",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )

    open_session do |sess|
      add_cart!(sess)
      sess.get "/shop/api/config", headers: shop_tenant_headers(@tenant.id), as: :json
      Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, customer.id)
      clear_shop_payment_step_up!(customer: customer, tenant_id: @tenant.id, session: sess)

      sess.post "/shop/api/payments/one_click",
        headers: shop_tenant_headers(@tenant.id),
        params: {
          name: "Owner",
          email: "",
          payment_method: "card",
          card_id: card.id,
          amount: 179
        },
        as: :json

      body = JSON.parse(sess.response.body)
      err = body["error"].to_s
      refute_match(/подтвердите email|укажите email/i, err)
      # 200 preferred; if gateway/other fails — must not be identity
      if sess.response.status == 422
        refute_match(/email/i, err)
      else
        assert_equal 200, sess.response.status, body.inspect
      end
    end
  ensure
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
    FakeTbankIdentity.enabled = false
  end
end
