# frozen_string_literal: true

require "test_helper"
require "json"
require "open3"

# Экстремумы ТЗ UserCards (error & edge states)
class Shop::ShopUserCardsExtremesTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ActiveJob::TestHelper

  SHEET = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")
  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "ext-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_key = ENV["TBANK_TERMINAL_KEY"]
    @old_pass = ENV["TBANK_PASSWORD"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    Payments::CacheCounter.clear!
  end

  teardown do
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    restore_env("TBANK_TERMINAL_KEY", @old_key)
    restore_env("TBANK_PASSWORD", @old_pass)
    Payments::CacheCounter.clear!
  end

  # --- E1: webhook upsert + idempotency ------------------------------------

  test "E1 webhook CONFIRMED+RebillId upserts UserCards idempotently" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Ext",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 179,
      discount_amount: 0,
      final_amount: 179
    )
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 179,
      method: :card,
      provider: "tbank",
      status: :pending,
      provider_payment_id: "pay-ext-wh-1"
    )

    payload = webhook_payload(
      order_id: order.id,
      payment_id: "pay-ext-wh-1",
      rebill: "rebill-ext-5953",
      pan: "430000******5953"
    )

    perform_enqueued_jobs do
      post "/callbacks/tbank",
        params: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      assert_response :ok
    end

    card = MobilePaymentMethod.find_by(customer_id: @customer.id, card_token: "rebill-ext-5953")
    assert card, "webhook должен создать UserCards"
    assert_equal "*5953", card.pan_display

    # повторная доставка (кэш idem HTTP сброшен; upsert UserCards без дубля)
    Payments::CacheCounter.clear!
    perform_enqueued_jobs do
      post "/callbacks/tbank",
        params: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      assert_response :ok
    end
    assert_equal 1, MobilePaymentMethod.where(customer_id: @customer.id, card_masked: "*5953").count
  end

  # --- E1b: DB fail на persist не ломает Success ----------------------------

  test "E1b settle survives SavedCardStore failure with Success" do
    FakeSoftFail.install!
    FakeSoftFail.enabled = true

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/payments/new_card",
        headers: shop_headers,
        params: {
          name: "Ext Guest",
          email: @email,
          payment_method: "card",
          CardData: "encrypted",
          save_card: true
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert_equal "accepted", body["status"]
      assert_nil body["saved_card"]
      assert_equal 0, MobilePaymentMethod.where(customer_id: @customer.id).count
    end
  ensure
    FakeSoftFail.enabled = false
  end

  # --- E2: no RebillId ------------------------------------------------------

  test "E2 CONFIRMED without RebillId does not create UserCards" do
    FakeNoRebill.install!
    FakeNoRebill.enabled = true

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/payments/new_card",
        headers: shop_headers,
        params: {
          name: "NoRebill",
          email: @email,
          payment_method: "card",
          CardData: "x",
          save_card: true
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert_equal "accepted", body["status"]
      assert_equal 0, MobilePaymentMethod.where(customer_id: @customer.id).count
    end
  ensure
    FakeNoRebill.enabled = false
  end

  test "E2 Checkout resets save_card toggle OFF when no saved_card returned" do
    src = File.read(CHECKOUT)
    assert_includes src, "setSaveCard"
    assert_includes src, "loadSavedCardsWithRetry"
    assert_match(/wantedSave && !savedCard && !appeared/, src)
    assert_match(/setSaveCard\(createNewCardFormState\(\),\s*false\)/, src)
  end

  # --- E5: 3DS pending does not save card -----------------------------------

  test "E5 3DS_CHECKING does not persist UserCards" do
    Fake3ds.install!
    Fake3ds.enabled = true

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/payments/new_card",
        headers: shop_headers,
        params: {
          name: "3DS Guest",
          email: @email,
          payment_method: "card",
          CardData: "x",
          save_card: true
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert body["three_ds"].present? || body["tbank_status"].to_s.upcase == "3DS_CHECKING"
      assert_equal 0, MobilePaymentMethod.where(customer_id: @customer.id).count
    end
  ensure
    Fake3ds.enabled = false
  end

  # --- E6: Net Error UI hint ------------------------------------------------

  test "E6 Checkout maps offline errors to Net Error message" do
    src = File.read(CHECKOUT)
    fsm = File.read(Rails.root.join("app/frontend/lib/shopPayFsm.js"))
    assert_includes fsm, "Нет связи. Повторить"
    assert_includes fsm, "NET_ERROR: 7"
    assert_match(/fsmFromPaymentError|PAY_FSM\.NET_ERROR/, src)
  end

  # --- E7: empty list UI ----------------------------------------------------

  test "E7 PaymentMethodsSheet empty list shows SBP, New card, Pay gate" do
    src = File.read(SHEET)
    i18n = File.read(Rails.root.join("app/frontend/lib/paymentMethodI18n.js"))
    assert_includes src, "labelAddCard"
    assert_includes i18n, 'return "Картой +"'
    assert_includes src, "labelSbp"
    assert_includes src, "CheckoutPayButton"
    assert_includes src, "{#each cards as card"
  end

  private

  module FakeSoftFail
    mattr_accessor :enabled, default: false

    module Override
      def init_payment(**)
        return super unless FakeSoftFail.enabled
        { payment_url: "https://x", provider_payment_id: "pay-soft-#{SecureRandom.hex(3)}" }
      end

      def finish_authorize(payment_id:, card_data:)
        return super unless FakeSoftFail.enabled
        {
          "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED",
          "PaymentId" => payment_id, "RebillId" => "rebill-soft",
          "CardId" => "c1", "Pan" => "430000******1111", "ExpDate" => "0927", "CardType" => "MIR"
        }
      end
    end

    def self.install!
      return if @done
      Payments::TbankAdapter.prepend(Override)
      Payments::SavedCardStore.singleton_class.prepend(Module.new do
        def persist_from_tbank!(**)
          raise StandardError, "simulated DB fail" if FakeSoftFail.enabled
          super
        end
      end)
      @done = true
    end
  end

  module FakeNoRebill
    mattr_accessor :enabled, default: false

    module Override
      def init_payment(**)
        return super unless FakeNoRebill.enabled
        { payment_url: "https://x", provider_payment_id: "pay-norebill-#{SecureRandom.hex(3)}" }
      end

      def finish_authorize(payment_id:, card_data:)
        return super unless FakeNoRebill.enabled
        {
          "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED",
          "PaymentId" => payment_id, "Pan" => "430000******2222", "ExpDate" => "0927"
        }
      end

      def get_payment_state(payment_id:)
        return super unless FakeNoRebill.enabled
        {
          "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED",
          "PaymentId" => payment_id
        }
      end
    end

    def self.install!
      return if @done
      Payments::TbankAdapter.prepend(Override)
      @done = true
    end
  end

  module Fake3ds
    mattr_accessor :enabled, default: false

    module Override
      def init_payment(**)
        return super unless Fake3ds.enabled
        { payment_url: "https://x", provider_payment_id: "pay-3ds-#{SecureRandom.hex(3)}" }
      end

      def finish_authorize(payment_id:, card_data:)
        return super unless Fake3ds.enabled
        {
          "Success" => true, "ErrorCode" => "0", "Status" => "3DS_CHECKING",
          "PaymentId" => payment_id, "ACSUrl" => "https://acs.example", "PaReq" => "x", "MD" => "y"
        }
      end
    end

    def self.install!
      return if @done
      Payments::TbankAdapter.prepend(Override)
      @done = true
    end
  end

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def webhook_payload(order_id:, payment_id:, rebill:, pan:)
    p = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => order_id.to_s,
      "PaymentId" => payment_id,
      "Status" => "CONFIRMED",
      "Amount" => 17_900,
      "RebillId" => rebill,
      "CardId" => "card-#{rebill}",
      "Pan" => pan,
      "ExpDate" => "0927",
      "CardType" => "MIR"
    }
    p["Token"] = Payments::TbankAdapter.new.build_token(p)
    p
  end

  def restore_env(key, value)
    if value
      ENV[key] = value
    else
      ENV.delete(key)
    end
  end
end
