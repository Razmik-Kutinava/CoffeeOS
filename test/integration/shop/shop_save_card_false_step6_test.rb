# frozen_string_literal: true

require "test_helper"
require "json"
require "open3"

# Шаг 6 ТЗ: оплата без сохранения (save_card=false)
# Given: форма 1000008924, тумблер OFF
# When:  оплата CONFIRMED
# Then:  UserCards НЕ создаётся; GET user/cards без новой карты
class Shop::ShopSaveCardFalseStep6Test < ActionDispatch::IntegrationTest
  include TestFactories

  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")
  FORM_LIB = Rails.root.join("app/frontend/lib/shopNewCardForm.js")
  FORM_UI  = Rails.root.join("app/frontend/components/NewCardForm.svelte")

  module FakeTbankNoSave
    mattr_accessor :enabled, default: false
    mattr_accessor :last_recurrent, default: nil

    module Override
      def init_payment(order:, return_base_url:, notification_url:, customer_key: nil, recurrent: false)
        return super unless FakeTbankNoSave.enabled

        FakeTbankNoSave.last_recurrent = recurrent
        {
          payment_url: "https://pay.tbank.ru/step6-unused",
          provider_payment_id: "pay-s6-#{order.id.to_s[0, 8]}"
        }
      end

      def finish_authorize(payment_id:, card_data:)
        return super unless FakeTbankNoSave.enabled

        # Даже если банк вернул RebillId — при save_card=false мы НЕ пишем UserCards.
        {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => "CONFIRMED",
          "PaymentId" => payment_id.to_s,
          "RebillId" => "rebill-s6-should-not-persist",
          "CardId" => "card-s6-9999",
          "Pan" => "430000******9999",
          "ExpDate" => "1229",
          "CardType" => "VISA"
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
    @email = "step6-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    @old_key = ENV["TBANK_TERMINAL_KEY"]
    @old_pass = ENV["TBANK_PASSWORD"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    FakeTbankNoSave.install!
    FakeTbankNoSave.enabled = false
    FakeTbankNoSave.last_recurrent = nil
    Payments::CacheCounter.clear!
  end

  teardown do
    Current.reset
    FakeTbankNoSave.enabled = false
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    restore_env("TBANK_TERMINAL_KEY", @old_key)
    restore_env("TBANK_PASSWORD", @old_pass)
    Payments::CacheCounter.clear!
  end

  test "S6 Then: new_card with save_card false does not create UserCards row" do
    FakeTbankNoSave.enabled = true
    before = MobilePaymentMethod.where(customer_id: @customer.id).count

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
          name: "Step6 Guest",
          email: @email,
          payment_method: "card",
          CardData: "encrypted-no-save",
          save_card: false
        },
        as: :json

      body = JSON.parse(sess.response.body)
      assert_equal 200, sess.response.status, body.inspect
      assert_equal "accepted", body["status"], body.inspect
      assert_equal false, body["save_card"]
      assert_nil body["saved_card"]
      assert_equal false, FakeTbankNoSave.last_recurrent,
        "Init должен идти с recurrent:false при save_card=false"

      after = MobilePaymentMethod.where(customer_id: @customer.id).count
      assert_equal before, after, "UserCards не должна пополниться"

      sess.get "/shop/api/user/cards",
        headers: shop_headers,
        params: { email: @email }

      list = JSON.parse(sess.response.body)
      pans = list["cards"].map { |c| c["pan"] }
      refute_includes pans, "*9999",
        "на экране 1000008925 новая карта не должна появиться"
    end
  end

  test "S6 Given/When: form toggle OFF sets save_card false in state" do
    assert File.exist?(FORM_LIB)
    src = File.read(FORM_LIB)
    assert_includes src, "export function setSaveCard"
    assert_includes src, "save_card: true"

    ui = File.read(FORM_UI)
    assert_includes ui, "shop-new-card-save-toggle"
    assert_includes ui, "setSaveCard"

    # Node: OFF → save_card false
    import_path = "./#{FORM_LIB.relative_path_from(Rails.root).to_s.tr('\\', '/')}"
    script = <<~JS
      import * as form from #{import_path.inspect};
      let s = form.createNewCardFormState();
      s = form.setSaveCard(s, false);
      process.stdout.write(JSON.stringify(s.save_card));
    JS
    stdout, stderr, status = Open3.capture3(
      "node", "--input-type=module", "-e", script,
      chdir: Rails.root.to_s
    )
    flunk stderr unless status.success?
    assert_equal false, JSON.parse(stdout)
  end

  test "S6 When: Checkout posts save_card from form toggle" do
    src = File.read(CHECKOUT)
    assert_match(
      /save_card:\s*!!newCardState\.save_card|save_card:\s*newCardState\.save_card|save_card:\s*wantedSave/,
      src
    )
    assert_match(%r{payments/new_card}, src)
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
