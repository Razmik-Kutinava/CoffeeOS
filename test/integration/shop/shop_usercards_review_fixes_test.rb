# frozen_string_literal: true

require "test_helper"
require "json"
require "open3"

# Review fixes: 3DS settle → список карт; brand fallback last4.
class Shop::ShopUserCardsReviewFixesTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ActiveJob::TestHelper

  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")
  RETRY_LIB = Rails.root.join("app/frontend/lib/shopSavedCards.js")

  module Fake3dsThenConfirm
    mattr_accessor :enabled, default: false

    module Override
      def init_payment(**)
        return super unless Fake3dsThenConfirm.enabled

        { payment_url: "https://x", provider_payment_id: "pay-3ds-settle-#{SecureRandom.hex(3)}" }
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
    end

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
    @email = "review-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_key = ENV["TBANK_TERMINAL_KEY"]
    @old_pass = ENV["TBANK_PASSWORD"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    Fake3dsThenConfirm.install!
    Fake3dsThenConfirm.enabled = false
    Payments::CacheCounter.clear!
  end

  teardown do
    Current.reset
    Fake3dsThenConfirm.enabled = false
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    restore_env("TBANK_TERMINAL_KEY", @old_key)
    restore_env("TBANK_PASSWORD", @old_pass)
    Payments::CacheCounter.clear!
  end

  test "3DS settle list: webhook CONFIRMED+RebillId creates UserCards when save_card true" do
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
          name: "3DS Settle",
          email: @email,
          payment_method: "card",
          CardData: "encrypted-3ds",
          save_card: true
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert body["three_ds"].present? || body["tbank_status"].to_s.upcase == "3DS_CHECKING"
      order_id = body["order_id"]
      payment = Payment.find_by!(order_id: order_id)
      payment_id = payment.provider_payment_id
      assert_equal true, payment.provider_data["save_card"]
      assert_equal 0, MobilePaymentMethod.where(customer_id: @customer.id).count
    end

    payload = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => order_id.to_s,
      "PaymentId" => payment_id,
      "Status" => "CONFIRMED",
      "Amount" => 17_900,
      "RebillId" => "rebill-3ds-5953",
      "CardId" => "card-3ds-5953",
      "Pan" => "220220******5953",
      "ExpDate" => "0927",
      "CardType" => "MIR"
    }
    payload["Token"] = Payments::TbankAdapter.new.build_token(payload)

    Payments::CacheCounter.clear!
    perform_enqueued_jobs do
      post "/callbacks/tbank",
        params: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      assert_response :ok
    end

    card = MobilePaymentMethod.find_by(customer_id: @customer.id, card_token: "rebill-3ds-5953")
    assert card, "после 3DS webhook должен создать UserCards"
    assert_equal "*5953", card.pan_display
    assert_equal "MIR", card.card_brand
    assert_equal "09/27", card.card_expires_at

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      sess.get "/shop/api/user/cards",
        headers: shop_headers,
        params: { email: @email }
      list = JSON.parse(sess.response.body)
      pans = list["cards"].map { |c| c["pan"] }
      assert_includes pans, "*5953"
    end
  end

  test "3DS settle: webhook does not create card when save_card false" do
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
          name: "3DS NoSave",
          email: @email,
          payment_method: "card",
          CardData: "x",
          save_card: false
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      order_id = body["order_id"]
      payment = Payment.find_by!(order_id: order_id)
      payment_id = payment.provider_payment_id
      assert_equal false, payment.provider_data["save_card"]
    end

    payload = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => order_id.to_s,
      "PaymentId" => payment_id,
      "Status" => "CONFIRMED",
      "Amount" => 17_900,
      "RebillId" => "rebill-3ds-nosave",
      "CardId" => "card-nosave",
      "Pan" => "430000******8888",
      "ExpDate" => "1128",
      "CardType" => "VISA"
    }
    payload["Token"] = Payments::TbankAdapter.new.build_token(payload)

    Payments::CacheCounter.clear!
    perform_enqueued_jobs do
      post "/callbacks/tbank",
        params: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      assert_response :ok
    end

    assert_equal 0, MobilePaymentMethod.where(customer_id: @customer.id).count
  end

  test "Checkout 3DS settle uses loadSavedCardsWithRetry before toggle OFF" do
    src = File.read(CHECKOUT)
    assert_includes src, "loadSavedCardsWithRetry"
    assert_match(/wantedSave && !savedCard && !appeared/, src)
    assert_match(/setSaveCard\(createNewCardFormState\(\),\s*false\)/, src)
    assert_includes File.read(RETRY_LIB), "export async function loadSavedCardsWithRetry"
  end

  test "loadSavedCardsWithRetry returns cards on second attempt" do
    import_path = "./#{RETRY_LIB.relative_path_from(Rails.root).to_s.tr('\\', '/')}"
    script = <<~JS
      import { loadSavedCardsWithRetry } from #{import_path.inspect};
      let n = 0;
      const cards = await loadSavedCardsWithRetry(async () => {
        n += 1;
        return n < 2 ? [] : [{ id: "c1", pan: "*5953" }];
      }, { attempts: 3, delayMs: 1 });
      process.stdout.write(JSON.stringify({ n, pan: cards[0]?.pan }));
    JS
    stdout, stderr, status = Open3.capture3(
      "node", "--input-type=module", "-e", script,
      chdir: Rails.root.to_s
    )
    flunk stderr unless status.success?
    parsed = JSON.parse(stdout)
    assert_equal 2, parsed["n"]
    assert_equal "*5953", parsed["pan"]
  end

  test "brand fallback does not treat last4-only pan as MASTERCARD" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Brand",
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
      provider_payment_id: "pay-brand-1",
      provider_data: { "save_card" => true }
    )

    card = Payments::SavedCardStore.persist_from_tbank!(
      payment: payment,
      payload: {
        "Status" => "CONFIRMED",
        "RebillId" => "rebill-brand-last4",
        "Pan" => "*5953",
        "ExpDate" => "0927"
      }
    )
    assert_equal "CARD", card.card_brand,
      "last4-only без CardType не должен стать MASTERCARD"
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
