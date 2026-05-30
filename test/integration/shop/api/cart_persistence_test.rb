# frozen_string_literal: true

require "test_helper"

class Shop::Api::CartPersistenceTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "shop-cart-persist-#{SecureRandom.hex(3)}")
    @category = create_category!(slug: "shop-cart-cat-#{SecureRandom.hex(3)}")
    @product = create_product!(category: @category, slug: "shop-cart-prod-#{SecureRandom.hex(3)}", name: "Persist")
    @product.update!(base_price: 200)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 210)
    @old_key = ENV["SHOP_API_KEY"]
    ENV["SHOP_API_KEY"] = "persist-test-key"
  end

  teardown do
    ENV["SHOP_API_KEY"] = @old_key
  end

  test "api cart persists across requests with session cookie and api key" do
    open_session do |sess|
      sess.get "/shop?tenant_id=#{@tenant.id}"
      assert_equal 200, sess.response.status

      sess.post "/shop/api/cart/add",
        headers: {
          "X-Shop-Tenant" => @tenant.id.to_s,
          "X-Shop-Api-Key" => "persist-test-key"
        },
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status
      assert_equal 210.0, sess.response.parsed_body["total"]

      sess.get "/shop/api/cart",
        headers: {
          "X-Shop-Tenant" => @tenant.id.to_s,
          "X-Shop-Api-Key" => "persist-test-key"
        }
      assert_equal 200, sess.response.status
      assert_equal 210.0, sess.response.parsed_body["total"]
    end
  end
end
