# frozen_string_literal: true

require "test_helper"

# После F5 / потери customer_id в cookie: status + frequent восстанавливают гостя
# без повторного OTP, пока ShopEmailVerification активна.
class Shop::Api::GuestSessionRestoreTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "gsr-#{SecureRandom.hex(3)}")
    @category = create_category!(name: "Черный")
    @product = create_product!(category: @category, name: "Капучино")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 290)
    Rails.cache.clear
  end

  test "status restores customer_id so frequent_items work without re-OTP" do
    email = "gsr-#{SecureRandom.hex(4)}@example.com"
    customer = create_mobile_customer!(email: email)
    seed_accepted_order!(customer: customer)

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)
    end

    # Новый browser session (= F5 с новой cookie): verification в БД жива, customer_id нет
    open_session do |sess|
      sess.get "/shop/api/frequent_products",
        headers: shop_tenant_headers(@tenant.id),
        as: :json
      assert_equal [], sess.response.parsed_body["frequent_items"],
        "без restore секция «повторить» пуста"

      sess.get "/shop/api/email_otp/status",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: email },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      assert_equal true, sess.response.parsed_body["verified"]

      assert_equal customer.id.to_s,
        Shop::CustomerSession.customer_id(sess.request.session, @tenant.id),
        "status должен вернуть customer_id в сессию"

      sess.get "/shop/api/frequent_products",
        headers: shop_tenant_headers(@tenant.id),
        as: :json
      items = sess.response.parsed_body["frequent_items"]
      assert_equal 1, items.length
      assert_equal @product.id, items.first["product_id"]
    end
  end

  test "frequent_products restores via email param when session customer blank" do
    email = "gsr-email-#{SecureRandom.hex(4)}@example.com"
    customer = create_mobile_customer!(email: email)
    seed_accepted_order!(customer: customer)

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)
    end

    open_session do |sess|
      sess.get "/shop/api/frequent_products",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: email },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      items = sess.response.parsed_body["frequent_items"]
      assert_equal 1, items.length
      assert_equal @product.id, items.first["product_id"]
      assert_equal customer.id.to_s,
        Shop::CustomerSession.customer_id(sess.request.session, @tenant.id)
    end
  end

  test "user cards restore via email after customer session cleared" do
    email = "gsr-cards-#{SecureRandom.hex(4)}@example.com"
    customer = create_mobile_customer!(email: email)
    card = MobilePaymentMethod.create!(
      customer_id: customer.id,
      payment_type: "card",
      card_masked: "220220******5953",
      card_expires_at: "09/27",
      card_token: "rebill-#{SecureRandom.hex(4)}",
      is_active: true,
      is_default: true
    )

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)
    end

    open_session do |sess|
      sess.get "/shop/api/email_otp/status",
        headers: shop_tenant_headers(@tenant.id),
        params: { email: email },
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      assert_equal true, sess.response.parsed_body["verified"]

      sess.get "/shop/api/user/cards",
        headers: shop_tenant_headers(@tenant.id),
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal 1, body["cards"].length
      assert_equal card.id, body["primary"]["id"]
    end
  end

  private

  def shop_tenant_headers(tenant_id)
    { "X-Shop-Tenant" => tenant_id.to_s }
  end

  def seed_accepted_order!(customer:)
    # История для «повторить»: терминальный статус (issued).
    # accepted скрывает секцию (HIDE_REPEAT_STATUSES / ревизия 2026-07-31).
    order = Order.create!(
      tenant: @tenant,
      customer_id: customer.id,
      order_number: "GSR-#{SecureRandom.hex(4)}",
      source: :mobile,
      status: :issued,
      total_amount: 290,
      discount_amount: 0,
      final_amount: 290,
      created_at: 2.days.ago
    )
    OrderItem.create!(
      order: order,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 1,
      unit_price: 290,
      total_price: 290,
      modifier_options: { "selected_modifiers" => [] }
    )
  end
end
