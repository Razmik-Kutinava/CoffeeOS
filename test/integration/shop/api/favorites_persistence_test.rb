# frozen_string_literal: true

require "test_helper"

class Shop::Api::FavoritesPersistenceTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category, name: "Fav Latte")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 199)
    @email = "fav-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
  end

  teardown do
    Current.reset
  end

  test "guest favorites stay in session only" do
    open_session do |sess|
      headers = { "X-Shop-Tenant" => @tenant.id.to_s }

      sess.post "/shop/api/favorites",
        headers: headers,
        params: { product_id: @product.id },
        as: :json
      assert_equal 200, sess.response.status

      assert_equal 0, Shop::CustomerFavorite.count

      sess.get "/shop/api/favorites", headers: headers
      ids = JSON.parse(sess.response.body).map { |row| row["id"] }
      assert_includes ids, @product.id
    end
  end

  test "logged-in customer persists favorites to database and survives new session" do
    open_session do |sess|
      headers = { "X-Shop-Tenant" => @tenant.id.to_s }
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/favorites",
        headers: headers,
        params: { product_id: @product.id },
        as: :json
      assert_equal 200, sess.response.status

      assert_equal 1, Shop::CustomerFavorite.where(customer_id: @customer.id, tenant_id: @tenant.id).count

      sess.reset!

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.get "/shop/api/favorites", headers: headers
      ids = JSON.parse(sess.response.body).map { |row| row["id"] }
      assert_includes ids, @product.id
    end
  end

  test "session favorites merge into database on login" do
    open_session do |sess|
      headers = { "X-Shop-Tenant" => @tenant.id.to_s }

      sess.post "/shop/api/favorites",
        headers: headers,
        params: { product_id: @product.id },
        as: :json
      assert_equal 200, sess.response.status
      assert_equal 0, Shop::CustomerFavorite.count

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      assert_equal 1, Shop::CustomerFavorite.where(customer_id: @customer.id, tenant_id: @tenant.id).count
    end
  end
end
