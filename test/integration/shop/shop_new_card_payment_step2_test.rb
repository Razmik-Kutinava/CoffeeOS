# frozen_string_literal: true

require "test_helper"

# Шаг 2 ТЗ: Исправление сохранения карты в UserCards…
# Given: форма заполнена, save_card ON, кнопка Default
# When:  «Оплатить» → RSA CardData → бэкенд { CardData, amount, save_card: true }
# Then:  Init → FinishAuthorize → UserCards (mobile_payment_methods)
class Shop::ShopNewCardPaymentStep2Test < ActionDispatch::IntegrationTest
  include TestFactories

  ENCRYPT_LIB = Rails.root.join("app/frontend/lib/tbankCardEncrypt.js")
  FORMAT_LIB  = Rails.root.join("app/frontend/lib/tbankCardFormat.js")

  module FakeTbankNewCard
    mattr_accessor :enabled, default: false

    module Override
      def init_payment(order:, return_base_url:, notification_url:, customer_key: nil, recurrent: false, receipt: nil)
        return super unless FakeTbankNewCard.enabled
        raise "Step2 stub expects recurrent:true when save_card" unless recurrent

        {
          payment_url: "https://pay.tbank.ru/step2-unused",
          provider_payment_id: "pay-s2-#{order.id.to_s[0, 8]}"
        }
      end

      def finish_authorize(payment_id:, card_data:)
        return super unless FakeTbankNewCard.enabled

        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "CONFIRMED",
          "PaymentId" => payment_id.to_s,
          "RebillId" => "rebill-s2-5953",
          "CardId" => "card-s2-5953",
          "Pan" => "430000******5953",
          "ExpDate" => "0927",
          "CardType" => "MIR"
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
    @email = "step2-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_key = ENV["TBANK_TERMINAL_KEY"]
    @old_pass = ENV["TBANK_PASSWORD"]
    @old_rsa = ENV["TBANK_RSA_PUBLIC_KEY"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    ENV["TBANK_RSA_PUBLIC_KEY"] = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu\n-----END PUBLIC KEY-----"
    FakeTbankNewCard.install!
    FakeTbankNewCard.enabled = false
    Payments::CacheCounter.clear!
  end

  teardown do
    Current.reset
    FakeTbankNewCard.enabled = false
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    restore_env("TBANK_TERMINAL_KEY", @old_key)
    restore_env("TBANK_PASSWORD", @old_pass)
    restore_env("TBANK_RSA_PUBLIC_KEY", @old_rsa)
    Payments::CacheCounter.clear!
  end

  # --- Frontend: RSA CardData contract ---------------------------------------

  test "S2 When: CardData plaintext uses T-Bank PAN;ExpDate;CVV key=value contract" do
    assert File.exist?(FORMAT_LIB), "Шаг 2: нужен app/frontend/lib/tbankCardFormat.js"
    src = File.read(FORMAT_LIB)
    assert_includes src, "export function buildCardDataString"
    assert_match(/PAN=\$\{|PAN=.*pan/i, src)
    assert_includes src, "ExpDate="
    assert_includes src, "CVV="
  end

  test "S2 When: encrypt helper exists and does not put plain PAN into payload builders" do
    assert File.exist?(ENCRYPT_LIB), "Шаг 2: нужен app/frontend/lib/tbankCardEncrypt.js"
    enc = File.read(ENCRYPT_LIB)
    assert_includes enc, "export function encryptCardPayload"
    assert_includes enc, "jsencrypt"
    refute_match(/fetch\([^)]*pan|body:.*cvv/i, enc)
  end

  # --- Adapter: FinishAuthorize ----------------------------------------------

  test "S2 Then: finish_authorize posts CardData to /FinishAuthorize" do
    adapter = Payments::TbankAdapter.new
    captured = nil
    adapter.define_singleton_method(:post_json) do |url, payload|
      captured = { url: url, payload: payload }
      {
        "Success" => true,
        "ErrorCode" => "0",
        "Status" => "CONFIRMED",
        "PaymentId" => "fa-1",
        "RebillId" => "rebill-5953",
        "CardId" => "card-5953",
        "Pan" => "430000******5953",
        "ExpDate" => "0927",
        "CardType" => "MIR"
      }
    end

    response = adapter.finish_authorize(payment_id: "fa-1", card_data: "base64-encrypted")
    assert captured[:url].end_with?("/FinishAuthorize")
    assert_equal "base64-encrypted", captured[:payload]["CardData"]
    assert_equal "CONFIRMED", response["Status"]
    assert_equal "rebill-5953", response["RebillId"]
  end

  # --- UserCards Persist (mobile_payment_methods) ----------------------------

  test "S2 Then: SavedCardStore writes UserCards fields for CONFIRMED+RebillId" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Step2 Guest",
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
      provider_payment_id: "pay-s2-1"
    )

    card = Payments::SavedCardStore.persist_from_tbank!(
      payment: payment,
      payload: {
        "Status" => "CONFIRMED",
        "RebillId" => "rebill-5953",
        "CardId" => "card-5953",
        "Pan" => "430000******5953",
        "ExpDate" => "0927",
        "CardType" => "Mir"
      }
    )

    assert card.persisted?
    assert_equal @customer.id, card.customer_id
    assert_equal "rebill-5953", card.card_token # UserCards.rebill_id
    assert_equal "card-5953", card.bank_card_id # UserCards.card_id
    assert_equal "*5953", card.pan_display
    assert_equal "09/27", card.card_expires_at
    assert_equal "MIR", card.card_brand.upcase
  end

  # --- Оркестрация Init → FinishAuthorize → UserCards -----------------------

  test "S2 Then: new_card payment with save_card true creates UserCards row" do
    FakeTbankNewCard.enabled = true

    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/payments/new_card",
        headers: shop_headers,
        params: {
          name: "Step2 Guest",
          email: @email,
          payment_method: "card",
          CardData: "encrypted-card-data-blob",
          amount: 179,
          save_card: true
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert_equal "accepted", body["status"], body.inspect
      assert_equal true, body["save_card"]

      card = MobilePaymentMethod.for_customer(@customer.id).first
      assert card, "Шаг 2: после CONFIRMED должна появиться запись UserCards (mobile_payment_methods)"
      assert_equal "*5953", card.pan_display
      assert_equal "MIR", card.card_brand
      assert_equal "09/27", card.card_expires_at
      assert_equal "rebill-s2-5953", card.rebill_id
      assert_equal "card-s2-5953", card.bank_card_id
    end
  end

  test "S2 When: card_config exposes RSA public key for frontend encrypt" do
    get "/shop/api/payments/card_config", headers: shop_headers
    assert_response :success
    body = JSON.parse(response.body)
    assert body["rsa_public_key"].present?
    assert_equal true, body["card_data_ready"]
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
