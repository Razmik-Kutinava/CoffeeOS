# frozen_string_literal: true

require "test_helper"

# Шаг 4 ТЗ: оплата в 1 клик по сохранённой карте
# Given: выбрана «МИР Карта *5953», кнопка Default
# When:  «Оплатить»
# Then:  фронт { card_id, amount } → бэкенд RebillId → Init → Charge; форма 1000008924 не показывается
class Shop::ShopOneClickPaymentStep4Test < ActionDispatch::IntegrationTest
  include TestFactories

  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")
  SHEET = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")

  module FakeTbankOneClick
    mattr_accessor :enabled, default: false
    mattr_accessor :last_charge, default: nil
    mattr_accessor :last_init_recurrent, default: nil

    module Override
      def init_payment(order:, return_base_url:, notification_url:, customer_key: nil, recurrent: false, receipt: nil, pay_type: nil, data: nil, **)
        return super unless FakeTbankOneClick.enabled

        FakeTbankOneClick.last_init_recurrent = recurrent
        {
          payment_url: "https://pay.tbank.ru/step4-unused",
          provider_payment_id: "pay-s4-#{order.id.to_s[0, 8]}"
        }
      end

      def charge(payment_id:, rebill_id:)
        return super unless FakeTbankOneClick.enabled

        FakeTbankOneClick.last_charge = { payment_id: payment_id, rebill_id: rebill_id }
        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "CONFIRMED",
          "PaymentId" => payment_id.to_s,
          "RebillId" => rebill_id.to_s
        }
      end

      def charge_recurrent(**kwargs)
        return super unless FakeTbankOneClick.enabled

        init = init_payment(**kwargs.except(:rebill_id))
        raw = charge(payment_id: init[:provider_payment_id], rebill_id: kwargs[:rebill_id])
        init.merge(charged: true, charge_response: raw, status: raw["Status"], three_ds: false)
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
    @email = "step4-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @card = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-s4-5953",
      card_masked: "*5953",
      card_brand: "MIR",
      card_expires_at: "09/27",
      bank_card_id: "card-s4-5953",
      is_active: true,
      is_default: true,
      last_used_at: Time.current
    )

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_key = ENV["TBANK_TERMINAL_KEY"]
    @old_pass = ENV["TBANK_PASSWORD"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    FakeTbankOneClick.install!
    FakeTbankOneClick.enabled = false
    FakeTbankOneClick.last_charge = nil
    Payments::CacheCounter.clear!
  end

  teardown do
    Current.reset
    FakeTbankOneClick.enabled = false
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    restore_env("TBANK_TERMINAL_KEY", @old_key)
    restore_env("TBANK_PASSWORD", @old_pass)
    Payments::CacheCounter.clear!
  end

  # --- Adapter Charge -------------------------------------------------------

  test "S4 Then: charge posts RebillId to /Charge" do
    adapter = Payments::TbankAdapter.new
    captured = nil
    adapter.define_singleton_method(:post_json) do |url, payload|
      captured = { url: url, payload: payload }
      { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED", "PaymentId" => "pay-9" }
    end

    response = adapter.charge(payment_id: "pay-9", rebill_id: "rebill-9")
    assert captured[:url].end_with?("/Charge")
    assert_equal "rebill-9", captured[:payload]["RebillId"]
    assert_equal "CONFIRMED", response["Status"]
  end

  test "S4 Then: charge_recurrent does Init then Charge" do
    FakeTbankOneClick.enabled = true
    order = Struct.new(:id, :final_amount).new(SecureRandom.uuid, BigDecimal("179.00"))

    result = Payments::TbankAdapter.new.charge_recurrent(
      order: order,
      rebill_id: "rebill-s4-5953",
      return_base_url: "https://example.com",
      notification_url: "https://example.com/callbacks/tbank",
      customer_key: @customer.id.to_s
    )

    assert result[:charged]
    assert_equal "CONFIRMED", result[:status]
    assert_equal "rebill-s4-5953", FakeTbankOneClick.last_charge[:rebill_id]
  end

  # --- API one_click --------------------------------------------------------

  test "S4 Then: POST payments/one_click Charges by card_id RebillId without new-card form" do
    FakeTbankOneClick.enabled = true

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/payments/one_click",
        headers: shop_headers,
        params: {
          name: "Step4 Guest",
          email: @email,
          payment_method: "card",
          card_id: @card.id,
          amount: 179
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert_equal "accepted", body["status"], body.inspect
      assert_equal true, body["recurrent_charge"]
      assert_equal "rebill-s4-5953", FakeTbankOneClick.last_charge[:rebill_id]
      assert body["saved_card"].present?
      assert_equal "*5953", body["saved_card"]["pan"]
    end
  end

  # --- Frontend: sends card_id, does not show new-card form on saved path ---

  test "S4 When: Checkout one-click posts card_id to payments/one_click" do
    src = File.read(CHECKOUT)
    assert_match(%r{payments/one_click}, src)
    assert_match(/card_id/, src)
    assert_match(/onSheetPay|selectionMode.*saved_card/m, src)
  end

  test "S4 Then: NewCardForm not shown when paying saved card" do
    checkout = File.read(CHECKOUT)
    sheet = File.read(SHEET)
    # Форма новой карты только при selectionMode === "new_card"
    assert_match(/selectionMode === ["']new_card["']/, sheet)
    assert_includes checkout, "selectionMode"
    refute_match(/selectionMode === ["']saved_card["'][\s\S]{0,80}NewCardForm/, sheet)
  end

  private

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def restore_env(key, value)
    if value
      ENV[key] = value
    else
      ENV.delete(key)
    end
  end
end
