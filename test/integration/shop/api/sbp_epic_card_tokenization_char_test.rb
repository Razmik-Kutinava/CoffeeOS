# frozen_string_literal: true

require "test_helper"

# Characterization Шаги 7–8 эпика SBP Deep Link + card tokenization (Т-Касса v2).
# Код не переписываем — фиксируем as-is: Recurrent→RebillId в БД + Charge one_click + invalid token.
#
# Канон уже в:
# - shop_new_card_payment_step2_test / shop_usercards_phase1_persist_test (RebillId)
# - shop_one_click_payment_step4_test (Charge)
# - repeat_invalid_token_* (FE invalid rebill)
class Shop::Api::SbpEpicCardTokenizationCharTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "sbp-char-#{SecureRandom.hex(4)}@example.com"
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
  end

  # --- Шаг 7: Init Recurrent=Y → RebillId в БД (CustomerKey / customer_id) ---

  test "step7 Init with recurrent puts Recurrent=Y in T-Kassa payload" do
    order = build_char_order!
    adapter = Payments::TbankAdapter.new
    captured = nil
    adapter.define_singleton_method(:post_json) do |_url, payload|
      captured = payload
      { "Success" => true, "ErrorCode" => "0", "PaymentId" => "pay-rec-1", "PaymentURL" => "https://pay.example/x" }
    end

    adapter.init_payment(
      order: order,
      return_base_url: "https://example.com",
      notification_url: "https://example.com/callbacks/tbank",
      customer_key: @customer.id.to_s,
      recurrent: true
    )

    assert_equal "Y", captured["Recurrent"]
    assert_equal @customer.id.to_s, captured["CustomerKey"]
  end

  test "step7 SavedCardStore persists RebillId linked to customer (CustomerKey)" do
    order = build_char_order!
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 179,
      method: :card,
      provider: "tbank",
      status: :succeeded,
      provider_payment_id: "pay-char-7",
      provider_data: { "save_card" => true }
    )

    card = Payments::SavedCardStore.persist_from_tbank!(
      payment: payment,
      payload: {
        "Status" => "CONFIRMED",
        "RebillId" => "rebill-char-7",
        "CardId" => "card-char-7",
        "Pan" => "430000******1234",
        "ExpDate" => "1227",
        "CardType" => "VISA"
      }
    )

    assert card.persisted?
    assert_equal @customer.id, card.customer_id
    assert_equal "rebill-char-7", card.card_token
    assert_equal "*1234", card.pan_display
  end

  # --- Шаг 8: Charge по RebillId + ошибки невалидного токена ---

  test "step8 Charge posts RebillId to /v2/Charge" do
    adapter = Payments::TbankAdapter.new
    captured = nil
    adapter.define_singleton_method(:post_json) do |url, payload|
      captured = { url: url, payload: payload }
      { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED", "PaymentId" => "pay-ch-1" }
    end

    response = adapter.charge(payment_id: "pay-ch-1", rebill_id: "rebill-char-8")
    assert captured[:url].end_with?("/Charge")
    assert_equal "rebill-char-8", captured[:payload]["RebillId"]
    assert_equal "CONFIRMED", response["Status"]
  end

  test "step8 one_click with invalid RebillId returns 422 and error_code" do
    card = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-bad-token",
      card_masked: "*9999",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )

    Payments::TbankAdapter.class_eval do
      alias_method :__char_charge_recurrent_orig, :charge_recurrent unless method_defined?(:__char_charge_recurrent_orig)

      define_method(:charge_recurrent) do |**_kwargs|
        raise Payments::TbankAdapter::ApiError.new(
          error_code: "1014",
          message: "Invalid token"
        )
      end
    end

    begin
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
            name: "Char Guest",
            email: @email,
            payment_method: "card",
            card_id: card.id
          },
          as: :json

        body = JSON.parse(sess.response.body)
        assert_equal 422, sess.response.status, body.inspect
        assert_equal "1014", body["error_code"].to_s
        assert body["error"].present?
      end
    ensure
      Payments::TbankAdapter.class_eval do
        if method_defined?(:__char_charge_recurrent_orig)
          alias_method :charge_recurrent, :__char_charge_recurrent_orig
          remove_method :__char_charge_recurrent_orig
        end
      end
    end
  end

  private

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def build_char_order!
    Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Char Guest",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 179,
      discount_amount: 0,
      final_amount: 179
    )
  end

  def restore_env(key, value)
    if value
      ENV[key] = value
    else
      ENV.delete(key)
    end
  end
end
