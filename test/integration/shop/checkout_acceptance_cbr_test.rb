# frozen_string_literal: true

require "test_helper"

# CBR checkout критерии приёмки п.1–10 (docs/.../CUSTOMER_BUSINESS_REQUIREMENTS.md).
class Shop::CheckoutAcceptanceCbrTest < ActionDispatch::IntegrationTest
  include TestFactories

  VITRINA_FILES = %w[
    routes/Checkout.svelte
    routes/Cart.svelte
    routes/PaymentResult.svelte
    components/CategorySection.svelte
    routes/CategoryProducts.svelte
  ].freeze

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "cbr-#{SecureRandom.hex(4)}@example.com"
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  # п.1 — Email вместо телефона + валидация
  test "cbr_01 checkout has email field with validation not phone" do
    checkout = vitrina_source("routes/Checkout.svelte")
    profile = File.read(Rails.root.join("app/frontend/lib/shopGuestProfile.js"))

    assert_includes checkout, "Email"
    assert_includes checkout, 'type="email"'
    assert_includes checkout, "isValidEmail"
    refute_includes checkout, "Телефон"
    assert_match(/isValidEmail\(email\)/, checkout)
    assert_includes profile, "export function isValidEmail"
    assert_includes profile, "@"
  end

  # п.2 — отправка кода
  test "cbr_02 email otp send endpoint accepts valid email" do
    post "/shop/api/email_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { email: @email },
      as: :json

    assert_response :success
    assert_equal @email, response.parsed_body["email"]
    assert ShopEmailOtpCode.active(@email).exists?
  end

  # п.3 — нет комментария
  test "cbr_03 comment field absent from checkout vitrina" do
    checkout = vitrina_source("routes/Checkout.svelte")
    refute_includes checkout, "Комментарий"
    refute_includes checkout, "comment"
  end

  # п.4 — нет наличия в каталоге
  test "cbr_04 stock labels absent from catalog vitrina" do
    VITRINA_FILES.each do |rel|
      next if rel == "routes/Checkout.svelte"

      content = vitrina_source(rel)
      refute_includes content, "Нет в наличии", "#{rel} still shows stock label"
    end
  end

  # п.5 — СБП disabled + «Будет позже»
  test "cbr_05 sbp disabled with later message in checkout" do
    checkout = vitrina_source("routes/Checkout.svelte")
    assert_includes checkout, "СБП"
    assert_includes checkout, "Будет позже"
    assert_includes checkout, "sbpNotice"
    assert_includes checkout, 'aria-disabled="true"'
  end

  # п.6 — по разделу «Изменения»: чекбокс «в машину» убран (критерий в CBR противоречит — сдаём по изменениям)
  test "cbr_06 car pickup checkbox removed per changes section" do
    checkout = vitrina_source("routes/Checkout.svelte")
    refute_includes checkout, "Выдача в машину"
    refute_includes checkout, "is_car_pickup"
    refute_includes checkout, "car_number"
  end

  # п.7 — крошки скрыты
  test "cbr_07 breadcrumbs hidden on checkout flow pages" do
    %w[routes/Checkout.svelte routes/PaymentResult.svelte].each do |rel|
      refute_includes vitrina_source(rel), "Корзина → Оформление"
    end
  end

  # п.8 — валидация до оплаты (canPay требует verify)
  test "cbr_08 pay blocked until name email and verification" do
    checkout = vitrina_source("routes/Checkout.svelte")
    assert_match(/canPay.*emailVerified/m, checkout.gsub(/\s+/, " "))
    assert_match(/disabled=\{!canPay/, checkout)
  end

  # п.9 — код уходит на указанный email (запись OTP + API ok)
  test "cbr_09 confirmation code stored for submitted email" do
    post "/shop/api/email_otp/send",
      headers: shop_tenant_headers(@tenant.id),
      params: { email: @email },
      as: :json
    assert_response :success

    record = ShopEmailOtpCode.active(@email).order(created_at: :desc).first
    assert record
    assert_equal 6, record.code.length
  end

  # п.10 — без verify заказ не создаётся (детали API: email_otp_checkout_test)
  test "cbr_10 order rejected without verified email" do
    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    post "/shop/api/orders",
      headers: shop_tenant_headers(@tenant.id),
      params: shop_order_params(email: @email, payment_method: "cash"),
      as: :json

    assert_response :unprocessable_entity
    assert_match(/подтвердите email/i, response.parsed_body["error"].to_s)
  end

  private

  def vitrina_source(rel)
    File.read(Rails.root.join("app/frontend", rel))
  end
end
