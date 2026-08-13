# frozen_string_literal: true

require "test_helper"

# Фаза 1: persist UserCards без worker — webhook perform_now + finalize GetState.
class Shop::ShopUsercardsPhase1PersistTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ActiveJob::TestHelper

  module Fake3dsThenConfirm
    mattr_accessor :enabled, default: false

    module Override
      def init_payment(pay_type: nil, data: nil, **)
        return super unless Fake3dsThenConfirm.enabled

        { payment_url: "https://x", provider_payment_id: "pay-p1-3ds-#{SecureRandom.hex(3)}" }
      end

      def finish_authorize(payment_id:, card_data:)
        return super unless Fake3dsThenConfirm.enabled

        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "3DS_CHECKING",
          "PaymentId" => payment_id,
          "ACSUrl" => "https://acs.example/3ds",
          "PaReq" => "pareq-x",
          "MD" => "md-y"
        }
      end

      def get_payment_state(payment_id:)
        return super unless Fake3dsThenConfirm.get_state_enabled

        Fake3dsThenConfirm.get_state_response.merge("PaymentId" => payment_id.to_s)
      end
    end

    mattr_accessor :get_state_enabled, default: false
    mattr_accessor :get_state_response, default: {}

    def self.install!
      return if @done

      Payments::TbankAdapter.prepend(Override)
      @done = true
    end
  end

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "phase1-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_key = ENV["TBANK_TERMINAL_KEY"]
    @old_pass = ENV["TBANK_PASSWORD"]
    @old_pause = ENV["TBANK_REBILL_SYNC_PAUSE_SEC"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    ENV["TBANK_REBILL_SYNC_PAUSE_SEC"] = "0"
    Fake3dsThenConfirm.install!
    Fake3dsThenConfirm.enabled = false
    FakeFaNoRebillRetry.install!
    FakeFaNoRebillRetry.enabled = false
    Payments::CacheCounter.clear!
  end

  teardown do
    Current.reset
    Fake3dsThenConfirm.enabled = false
    Fake3dsThenConfirm.get_state_enabled = false
    Fake3dsThenConfirm.get_state_response = {}
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    restore_env("TBANK_TERMINAL_KEY", @old_key)
    restore_env("TBANK_PASSWORD", @old_pass)
    restore_env("TBANK_REBILL_SYNC_PAUSE_SEC", @old_pause)
    Payments::CacheCounter.clear!
  end

  test "P1 webhook CONFIRMED+RebillId persists UserCards without worker (perform_now)" do
    Fake3dsThenConfirm.enabled = true
    order_id = nil
    payment_id = nil

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/payments/new_card",
        headers: shop_headers,
        params: {
          name: "Phase1",
          email: @email,
          payment_method: "card",
          CardData: "encrypted-p1",
          save_card: true
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      order_id = body["order_id"]
      payment = Payment.find_by!(order_id: order_id)
      payment_id = payment.provider_payment_id
      assert_equal true, payment.provider_data["save_card"]
    end

    payload = webhook_payload(
      order_id: order_id,
      payment_id: payment_id,
      rebill_id: "rebill-p1-5953",
      pan: "220196******5953"
    )

    assert_no_enqueued_jobs(only: Payments::TbankCallbackJob) do
      post "/callbacks/tbank",
        params: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      assert_response :ok
    end

    card = MobilePaymentMethod.find_by(customer_id: @customer.id, card_token: "rebill-p1-5953")
    assert card, "webhook perform_now должен создать UserCards без worker"
    assert_equal "*5953", card.pan_display
    assert_equal "MIR", card.card_brand

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      sess.get "/shop/api/user/cards", headers: shop_headers, params: { email: @email }
      list = JSON.parse(sess.response.body)
      assert_includes list["cards"].map { |c| c["pan"] }, "*5953"
    end
  end

  test "P1 replay: succeeded payment without RebillId gets card on webhook" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Replay",
      order_number: "",
      source: :mobile,
      status: :accepted,
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
      status: :succeeded,
      provider_payment_id: "pay-replay-8861552152",
      provider_data: {
        "save_card" => true,
        "Status" => "CONFIRMED",
        "PaymentId" => "pay-replay-8861552152"
      }
    )
    assert_equal 0, MobilePaymentMethod.where(customer_id: @customer.id).count

    payload = webhook_payload(
      order_id: order.id,
      payment_id: payment.provider_payment_id,
      rebill_id: "rebill-replay-5953",
      pan: "220196******5953"
    )

    post "/callbacks/tbank",
      params: payload.to_json,
      headers: { "Content-Type" => "application/json" }
    assert_response :ok

    card = MobilePaymentMethod.find_by(customer_id: @customer.id, card_token: "rebill-replay-5953")
    assert card, "повторный webhook с RebillId должен дописать UserCards"
    assert_equal "*5953", card.pan_display
  end

  test "P1 finalize GetState with RebillId persists UserCards after 3DS" do
    Fake3dsThenConfirm.enabled = true
    Fake3dsThenConfirm.get_state_enabled = true
    Fake3dsThenConfirm.get_state_response = {
      "Success" => true,
      "ErrorCode" => "0",
      "Status" => "CONFIRMED",
      "RebillId" => "rebill-fin-5953",
      "Pan" => "220196******5953",
      "ExpDate" => "0927",
      "CardType" => "MIR"
    }
    order_id = nil

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/payments/new_card",
        headers: shop_headers,
        params: {
          name: "Finalize",
          email: @email,
          payment_method: "card",
          CardData: "encrypted-fin",
          save_card: true
        },
        as: :json

      body = JSON.parse(sess.response.body)
      order_id = body["order_id"]

      sess.post "/shop/api/orders/#{order_id}/finalize",
        headers: shop_headers,
        as: :json
      fin = JSON.parse(sess.response.body)
      assert_equal true, fin["payment_settled"]
    end

    card = MobilePaymentMethod.find_by(customer_id: @customer.id, card_token: "rebill-fin-5953")
    assert card, "finalize/GetState с RebillId должен создать UserCards"
  end

  test "P1 FA CONFIRMED without RebillId GetState retry persists UserCards" do
    FakeFaNoRebillRetry.install!
    FakeFaNoRebillRetry.enabled = true
    FakeFaNoRebillRetry.attempts = 0
    order_id = nil

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/payments/new_card",
        headers: shop_headers,
        params: {
          name: "RetryRebill",
          email: @email,
          payment_method: "card",
          CardData: "encrypted-retry",
          save_card: true
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert_equal "accepted", body["status"]
      order_id = body["order_id"]
    end

    payment = Payment.find_by!(order_id: order_id)
    card = MobilePaymentMethod.find_by(
      customer_id: payment.order.customer_id,
      card_token: "rebill-fa-retry-8782"
    )
    assert card, "FA без RebillId + retry GetState должен создать UserCards (attempts=#{FakeFaNoRebillRetry.attempts})"
    assert_equal "*8782", card.pan_display
    assert_operator FakeFaNoRebillRetry.attempts, :>=, 2
  ensure
    FakeFaNoRebillRetry.enabled = false
    FakeFaNoRebillRetry.attempts = 0
  end

  module FakeFaNoRebillRetry
    mattr_accessor :enabled, default: false
    mattr_accessor :attempts, default: 0

    module Override
      def init_payment(pay_type: nil, data: nil, **)
        return super unless FakeFaNoRebillRetry.enabled

        { payment_url: "https://x", provider_payment_id: "pay-fa-retry-#{SecureRandom.hex(3)}" }
      end

      def finish_authorize(payment_id:, card_data:)
        return super unless FakeFaNoRebillRetry.enabled

        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "CONFIRMED",
          "PaymentId" => payment_id
        }
      end

      def get_payment_state(payment_id:)
        return super unless FakeFaNoRebillRetry.enabled

        FakeFaNoRebillRetry.attempts += 1
        base = { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED", "PaymentId" => payment_id.to_s }
        if FakeFaNoRebillRetry.attempts >= 2
          base.merge(
            "RebillId" => "rebill-fa-retry-8782",
            "Pan" => "220196******8782",
            "ExpDate" => "1029",
            "CardType" => "MIR"
          )
        else
          base
        end
      end
    end

    def self.install!
      return if @done

      Payments::TbankAdapter.prepend(Override)
      @done = true
    end
  end

  private

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def webhook_payload(order_id:, payment_id:, rebill_id:, pan:)
    p = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => order_id.to_s,
      "PaymentId" => payment_id,
      "Status" => "CONFIRMED",
      "Amount" => 17_900,
      "RebillId" => rebill_id,
      "CardId" => "card-#{rebill_id}",
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
