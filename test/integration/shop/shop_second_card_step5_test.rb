# frozen_string_literal: true

require "test_helper"

# Шаг 5 ТЗ: добавление второй карты
# Given: уже есть сохранённые карты (*5953, …)
# When:  «Новая карта» → форма 1000008924 + save_card:true → оплата
# Then:  новая карта в списке; без дублей; сортировка по дате
class Shop::ShopSecondCardStep5Test < ActionDispatch::IntegrationTest
  include TestFactories

  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")

  module FakeTbankSecondCard
    mattr_accessor :enabled, default: false
    mattr_accessor :pan_suffix, default: "1594"
    mattr_accessor :rebill, default: "rebill-s5-1594"

    module Override
      def init_payment(order:, return_base_url:, notification_url:, customer_key: nil, recurrent: false, **)
        return super unless FakeTbankSecondCard.enabled
        raise "Step5 expects recurrent:true" unless recurrent

        {
          payment_url: "https://pay.tbank.ru/step5-unused",
          provider_payment_id: "pay-s5-#{order.id.to_s[0, 8]}"
        }
      end

      def finish_authorize(payment_id:, card_data:)
        return super unless FakeTbankSecondCard.enabled

        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "CONFIRMED",
          "PaymentId" => payment_id.to_s,
          "RebillId" => FakeTbankSecondCard.rebill,
          "CardId" => "card-s5-#{FakeTbankSecondCard.pan_suffix}",
          "Pan" => "430000******#{FakeTbankSecondCard.pan_suffix}",
          "ExpDate" => "1128",
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
    @email = "step5-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)

    # Уже есть карты (макет 1000008925)
    @existing = [
      create_card!(pan: "*5953", brand: "MIR", exp: "09/27", token: "rebill-5953", used_at: 4.days.ago),
      create_card!(pan: "*5938", brand: "MIR", exp: "10/27", token: "rebill-5938", used_at: 3.days.ago),
      create_card!(pan: "*8339", brand: "MASTERCARD", exp: "12/28", token: "rebill-8339", used_at: 2.days.ago),
      create_card!(pan: "*1594", brand: "VISA", exp: "01/29", token: "rebill-1594", used_at: 1.day.ago)
    ]

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_key = ENV["TBANK_TERMINAL_KEY"]
    @old_pass = ENV["TBANK_PASSWORD"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    FakeTbankSecondCard.install!
    FakeTbankSecondCard.enabled = false
    FakeTbankSecondCard.pan_suffix = "4242"
    FakeTbankSecondCard.rebill = "rebill-s5-4242"
    Payments::CacheCounter.clear!
  end

  teardown do
    Current.reset
    FakeTbankSecondCard.enabled = false
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    restore_env("TBANK_TERMINAL_KEY", @old_key)
    restore_env("TBANK_PASSWORD", @old_pass)
    Payments::CacheCounter.clear!
  end

  test "S5 Then: second new_card appears in list without duplicates" do
    FakeTbankSecondCard.enabled = true

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
          name: "Step5 Guest",
          email: @email,
          payment_method: "card",
          CardData: "encrypted-second-card",
          save_card: true
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert_equal "accepted", body["status"], body.inspect

      sess.get "/shop/api/user/cards",
        headers: shop_headers,
        params: { email: @email }

      list = JSON.parse(sess.response.body)
      pans = list["cards"].map { |c| c["pan"] }
      assert_equal 5, pans.size, "ожидали 4 старых + 1 новую: #{pans.inspect}"
      assert_equal pans.uniq, pans, "список не должен дублироваться"
      assert_includes pans, "*4242"
      # текущая логика: новые сверху (last_used_at desc)
      assert_equal "*4242", pans.first, "новая карта должна быть сверху списка"
    end
  end

  test "S5 Then: SavedCardStore upsert same rebill does not duplicate" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Step5",
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
      provider_payment_id: "pay-s5-dup"
    )

    payload = {
      "Status" => "CONFIRMED",
      "RebillId" => "rebill-5953",
      "CardId" => "card-5953",
      "Pan" => "430000******5953",
      "ExpDate" => "0927",
      "CardType" => "MIR"
    }

    Payments::SavedCardStore.persist_from_tbank!(payment: payment, payload: payload)
    Payments::SavedCardStore.persist_from_tbank!(payment: payment, payload: payload)

    assert_equal 4, MobilePaymentMethod.for_customer(@customer.id).count
    assert_equal 1, MobilePaymentMethod.where(customer_id: @customer.id, card_token: "rebill-5953").count
  end

  test "S5 Then: upsert same pan+exp without new rebill row duplicate" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Step5",
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
      provider_payment_id: "pay-s5-pan"
    )

    # новый RebillId, тот же pan+exp → upsert, не дубль
    Payments::SavedCardStore.persist_from_tbank!(
      payment: payment,
      payload: {
        "Status" => "CONFIRMED",
        "RebillId" => "rebill-5953-rotated",
        "CardId" => "card-5953-b",
        "Pan" => "430000******5953",
        "ExpDate" => "0927",
        "CardType" => "MIR"
      }
    )

    cards = MobilePaymentMethod.where(customer_id: @customer.id, card_masked: "*5953")
    assert_equal 1, cards.count, "pan+exp не должен плодить дубль"
    assert_equal "rebill-5953-rotated", cards.first.card_token
  end

  test "S5 When: Checkout new_card path encrypts and posts payments/new_card" do
    src = File.read(CHECKOUT)
    assert_match(%r{payments/new_card}, src)
    assert_match(/encryptCardPayload|encryptCardDataString/, src)
    assert_match(/card_config/, src)
    assert_match(/selectionMode === ["']new_card["']/, src)
    assert_includes src, "save_card"
  end

  private

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def create_card!(pan:, brand:, exp:, token:, used_at:)
    MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: token,
      card_masked: pan,
      card_brand: brand,
      card_expires_at: exp,
      bank_card_id: "bank-#{token}",
      is_active: true,
      is_default: false,
      last_used_at: used_at,
      created_at: used_at
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
