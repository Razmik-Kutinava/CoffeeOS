# frozen_string_literal: true

require "test_helper"

# FIX-A: после email_otp/verify клиент с историей заказов должен видеть frequent_items
# без повторного оформления заказа (customer_id в сессии, не только verified email).
class Shop::Api::EmailVerifyCustomerLinkTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "evlink-#{SecureRandom.hex(3)}")
    @category = create_category!(name: "Черный")
    @product = create_product!(category: @category, name: "Фильтр-кофе Бразилия")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 250)
    Rails.cache.clear
  end

  test "after verify returning customer gets frequent_items without placing new order" do
    email = "evlink-#{SecureRandom.hex(4)}@example.com"
    customer = create_mobile_customer!(email: email)
    seed_accepted_order!(customer: customer)

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)

      sess.get "/shop/api/frequent_products",
        headers: shop_tenant_headers(@tenant.id),
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      items = sess.response.parsed_body["frequent_items"]
      assert_equal 1, items.length, "после verify с историей заказов секция «повторить» не пуста"
      assert_equal @product.id, items.first["product_id"]
    end
  end

  test "verify links customer_id for new email before first order" do
    email = "evlink-new-#{SecureRandom.hex(4)}@example.com"

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: email, session: sess)

      sess.get "/shop/api/frequent_products",
        headers: shop_tenant_headers(@tenant.id),
        as: :json
      assert_equal [], sess.response.parsed_body["frequent_items"]

      sess.get "/shop/api/profile",
        headers: shop_tenant_headers(@tenant.id),
        as: :json
      body = sess.response.parsed_body
      assert body["id"].present?, "после verify клиент привязан к сессии (id в профиле)"
      assert_equal 0, body["orders_count"]
    end
  end

  private

  def shop_tenant_headers(tenant_id)
    { "X-Shop-Tenant" => tenant_id.to_s }
  end

  def seed_accepted_order!(customer:)
    order = Order.create!(
      tenant: @tenant,
      customer_id: customer.id,
      order_number: "EVL-#{SecureRandom.hex(4)}",
      source: :mobile,
      status: :accepted,
      total_amount: 250,
      discount_amount: 0,
      final_amount: 250,
      created_at: 2.days.ago
    )
    OrderItem.create!(
      order: order,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 1,
      unit_price: 250,
      total_price: 250,
      modifier_options: { "selected_modifiers" => [] }
    )
  end
end
