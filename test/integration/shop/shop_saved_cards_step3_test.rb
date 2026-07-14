# frozen_string_literal: true

require "test_helper"
require "json"
require "open3"

# Шаг 3 ТЗ: список сохранённых карт (макет 1000008925.png)
# Given: UserCards с валидным exp_date
# When:  экран выбора способа оплаты
# Then:  GET cards → UI «МИР Карта *XXXX» + «Новая карта» + Pay активна при выборе
class Shop::ShopSavedCardsStep3Test < ActionDispatch::IntegrationTest
  include TestFactories

  LABELS = Rails.root.join("app/frontend/lib/paymentMethodLabels.js")
  SHEET  = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")
  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @email = "step3-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
  end

  teardown do
    Current.reset
  end

  # --- Given/Then: API GET /shop/api/user/cards ------------------------------

  test "S3 Then: GET user/cards returns active cards for customer" do
    create_card!(pan: "*5953", brand: "MIR", exp: "09/27", token: "rebill-5953")
    create_card!(pan: "*8339", brand: "MASTERCARD", exp: "12/28", token: "rebill-8339")

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, @customer.id) if sess.respond_to?(:session)

      sess.get "/shop/api/user/cards",
        headers: shop_headers,
        params: { email: @email }

      assert_equal 200, sess.response.status, sess.response.body
      body = JSON.parse(sess.response.body)
      assert body["cards"].is_a?(Array)
      assert_equal 2, body["cards"].size

      first = body["cards"].find { |c| c["pan"] == "*5953" }
      assert first, "ожидали карту *5953"
      assert_equal "MIR", first["card_type"]
      assert_equal "09/27", first["exp_date"]
      assert first["id"].present?
    end
  end

  test "S3 Then: GET user/cards filters expired cards" do
    create_card!(pan: "*5953", brand: "MIR", exp: "09/27", token: "rebill-ok")
    create_card!(pan: "*1111", brand: "VISA", exp: "01/20", token: "rebill-expired")

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.get "/shop/api/user/cards",
        headers: shop_headers,
        params: { email: @email }

      body = JSON.parse(sess.response.body)
      pans = body["cards"].map { |c| c["pan"] }
      assert_includes pans, "*5953"
      refute_includes pans, "*1111", "истёкшие карты не должны отдаваться"
    end
  end

  test "S3 Then: GET user/cards empty without customer session/email" do
    get "/shop/api/user/cards", headers: shop_headers
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body["cards"]
  end

  # --- Labels / UI mockup 1000008925 ----------------------------------------

  test "S3 Then: paymentMethodLabels formats brand + Карта *XXXX" do
    assert File.exist?(LABELS), "Шаг 3: нужен paymentMethodLabels.js"
    src = File.read(LABELS)
    assert_includes src, "export function formatCardListLabel"
    assert_includes src, "export function formatCardFullLabel"
    assert_includes src, "export function cardBrandShort"
    assert_includes src, "Карта"
  end

  test "S3 Then: PaymentMethodsSheet renders list, New card, pay gate" do
    assert File.exist?(SHEET), "Шаг 3: нужен PaymentMethodsSheet.svelte"
    src = File.read(SHEET)
    assert_includes src, 'data-testid="payment-methods-sheet"'
    assert_includes src, 'data-testid="payment-method-new-card"'
    assert_includes src, "Новая карта"
    assert_match(/formatCardFullLabel|formatCardListLabel/, src)
    assert_match(/Оплатить|payment-methods-pay/, src)
    assert_includes src, "СБП"
  end

  test "S3 When: Checkout loads user/cards and opens payment methods sheet" do
    assert File.exist?(CHECKOUT)
    src = File.read(CHECKOUT)
    assert_match(%r{user/cards|/saved_cards}, src)
    assert_includes src, "PaymentMethodsSheet"
    sheet = File.read(SHEET)
    assert_includes sheet, "NewCardForm"
  end

  # --- Node unit labels ------------------------------------------------------

  test "S3 Then: formatCardFullLabel mirrors mockup examples" do
    assert File.exist?(LABELS)
    assert_equal "МИР Карта *5953", js_label("formatCardFullLabel", {
      "pan" => "*5953", "payment_system" => "MIR", "card_type" => "MIR"
    })
    assert_equal "Mastercard Карта *8339", js_label("formatCardFullLabel", {
      "pan" => "*8339", "payment_system" => "MASTERCARD"
    })
  end

  private

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  def create_card!(pan:, brand:, exp:, token:)
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
      last_used_at: Time.current
    )
  end

  def js_label(fn, card)
    import_path = "./#{LABELS.relative_path_from(Rails.root).to_s.tr('\\', '/')}"
    script = <<~JS
      import * as labels from #{import_path.inspect};
      const result = labels.#{fn}(#{JSON.generate(card)});
      process.stdout.write(JSON.stringify(result));
    JS
    stdout, stderr, status = Open3.capture3(
      "node", "--input-type=module", "-e", script,
      chdir: Rails.root.to_s
    )
    flunk "Node: #{stderr}" unless status.success?
    JSON.parse(stdout)
  end
end
