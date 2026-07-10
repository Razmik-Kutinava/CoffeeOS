# frozen_string_literal: true

require "test_helper"

class Shop::CheckoutUiCleanupTest < ActionDispatch::IntegrationTest
  include TestFactories

  REMOVED_UI_STRINGS = [
    "Комментарий",
    "Выдача в машину",
    "Корзина → Оформление",
    "Нет в наличии"
  ].freeze

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "cleanup-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  teardown do
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
  end

  test "order create works without comment and car pickup fields" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: { email: @email, name: "Checkout Cleanup", payment_method: "card" },
        as: :json

      assert_equal 200, sess.response.status, sess.response.body
      body = JSON.parse(sess.response.body)
      assert_equal "accepted", body["status"]
    end
  end

  test "checkout vitrina sources do not contain removed UI labels" do
    root = Rails.root.join("app/frontend")
    files = [
      root.join("routes/Checkout.svelte"),
      root.join("routes/Cart.svelte"),
      root.join("routes/PaymentResult.svelte"),
      root.join("components/CategorySection.svelte"),
      root.join("routes/CategoryProducts.svelte")
    ]

    files.each do |path|
      content = File.read(path)
      REMOVED_UI_STRINGS.each do |label|
        refute_includes content, label, "#{path.basename} still contains #{label.inspect}"
      end
    end

    checkout = File.read(root.join("routes/Checkout.svelte"))
    sheet = File.read(root.join("components/CheckoutPaymentSheet.svelte"))
    assert_includes sheet, "Способ оплаты"
    assert_includes sheet, "СБП"
    assert_includes checkout, "CheckoutPaymentSheet"
    refute_includes checkout, "is_car_pickup"
    assert_includes checkout, "Email"
    refute_includes checkout, "Телефон"
    refute_includes checkout, "Промокод"
    refute_includes checkout, "promo_code"
    refute_includes checkout, "Наличные"
    refute_includes checkout, '"cash"'
  end
end
