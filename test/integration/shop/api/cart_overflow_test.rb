# frozen_string_literal: true

require "test_helper"

# TASK_93-H — cookie/session cart overflow → 422, not 500/NameError
class Shop::Api::CartOverflowTest < ActionDispatch::IntegrationTest
  include TestFactories

  OVERFLOW_MSG = "Корзина переполнена. Мы её очистили — добавьте товары снова."

  setup do
    @tenant = create_tenant!(slug: "shop-cart-ovf-#{SecureRandom.hex(3)}")
    @category = create_category!(slug: "shop-cart-ovf-cat-#{SecureRandom.hex(3)}")
    @product = create_product!(category: @category, slug: "shop-cart-ovf-prod-#{SecureRandom.hex(3)}", name: "Overflow")
    @product.update!(base_price: 200)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 210)
    @old_key = ENV["SHOP_API_KEY"]
    ENV["SHOP_API_KEY"] = "overflow-test-key"
  end

  teardown do
    ENV["SHOP_API_KEY"] = @old_key
  end

  test "T-H1a CartController rescues CartService::OverflowError with 422 and clears" do
    open_session do |sess|
      sess.get "/shop?tenant_id=#{@tenant.id}"
      assert_equal 200, sess.response.status

      Shop::CartService.stub(:new, raising_cart_service(:add!)) do
        sess.post "/shop/api/cart/add",
          headers: cart_headers,
          params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
          as: :json
      end

      assert_equal 422, sess.response.status, sess.response.body
      body = sess.response.parsed_body
      assert_equal OVERFLOW_MSG, body["error"]

      sess.get "/shop/api/cart", headers: cart_headers
      assert_equal 200, sess.response.status
      assert_equal [], sess.response.parsed_body["items"]
    end
  end

  test "T-H1b controller does not bare-rescue undefined ActionDispatch::CookieOverflow alone" do
    source = File.read(Rails.root.join("app/controllers/shop/api/cart_controller.rb"))
    assert_match(/CartService::OverflowError/, source)

    if source.match?(/rescue\s+ActionDispatch::CookieOverflow/)
      assert_match(
        /const_defined\?\(\s*:CookieOverflow\s*\)/,
        source,
        "CookieOverflow rescue must be gated by ActionDispatch.const_defined?(:CookieOverflow)"
      )
    end

    refute defined?(ActionDispatch::CookieOverflow) &&
      source.match?(/rescue\s+ActionDispatch::CookieOverflow\b/) &&
      !source.match?(/const_defined\?\(\s*:CookieOverflow\s*\)/),
      "bare CookieOverflow rescue without const_defined? is forbidden"
  end

  test "T-H1c update path rescues OverflowError with 422 and clears" do
    open_session do |sess|
      sess.get "/shop?tenant_id=#{@tenant.id}"
      assert_equal 200, sess.response.status

      sess.post "/shop/api/cart/add",
        headers: cart_headers,
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      Shop::CartService.stub(:new, raising_cart_service(:update_quantity!, :replace_line!)) do
        sess.patch "/shop/api/cart/items/0",
          headers: cart_headers,
          params: { delta: 1 },
          as: :json
      end

      assert_equal 422, sess.response.status, sess.response.body
      assert_equal OVERFLOW_MSG, sess.response.parsed_body["error"]

      sess.get "/shop/api/cart", headers: cart_headers
      assert_equal [], sess.response.parsed_body["items"]
    end
  end

  test "T-H3a POST cart/add until overflow returns 422 not 500" do
    with_cart_overflow_caps(lines: 3) do
      products = 4.times.map do |i|
        p = create_product!(
          category: @category,
          slug: "ovf-many-#{i}-#{SecureRandom.hex(2)}",
          name: "Ovf #{i}"
        )
        enable_product_for_tenant!(tenant: @tenant, product: p, price: 100 + i)
        p
      end

      open_session do |sess|
        sess.get "/shop?tenant_id=#{@tenant.id}"
        assert_equal 200, sess.response.status

        statuses = products.map do |p|
          sess.post "/shop/api/cart/add",
            headers: cart_headers,
            params: { product_id: p.id, quantity: 1, selected_modifiers: [] },
            as: :json
          refute_equal 500, sess.response.status, "overflow path must not 500: #{sess.response.body}"
          sess.response.status
        end

        assert_includes statuses, 422, "expected a 422 overflow response, got #{statuses.inspect}"
        last_overflow = statuses.rindex(422)
        assert last_overflow, "missing 422"

        sess.get "/shop/api/cart", headers: cart_headers
        assert_equal 200, sess.response.status
        items = sess.response.parsed_body["items"]
        assert items.empty? || items.size <= 3
      end
    end
  end

  test "T-H3b normal small cart still 200" do
    open_session do |sess|
      sess.get "/shop?tenant_id=#{@tenant.id}"
      assert_equal 200, sess.response.status

      2.times do
        sess.post "/shop/api/cart/add",
          headers: cart_headers,
          params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
          as: :json
        assert_equal 200, sess.response.status, sess.response.body
      end

      sess.get "/shop/api/cart", headers: cart_headers
      assert_equal 200, sess.response.status
      assert_equal 2, sess.response.parsed_body["items"].first["quantity"]
    end
  end

  private

  def cart_headers
    {
      "X-Shop-Tenant" => @tenant.id.to_s,
      "X-Shop-Api-Key" => "overflow-test-key"
    }
  end

  # Real CartService for show/clear after overflow; raises OverflowError on mutating methods.
  def raising_cart_service(*raising_methods)
    overflow = Shop::CartService::OverflowError
    lambda do |session, tenant_id|
      real = Shop::CartService.allocate
      real.send(:initialize, session, tenant_id)
      raising_methods.each do |meth|
        real.define_singleton_method(meth) do |*|
          raise overflow, "forced overflow"
        end
      end
      real
    end
  end

  def with_cart_overflow_caps(lines: nil, bytes: nil)
    originals = {}
    if lines
      originals[:lines] = Shop::CartService::MAX_CART_LINES
      Shop::CartService.send(:remove_const, :MAX_CART_LINES)
      Shop::CartService.const_set(:MAX_CART_LINES, lines)
    end
    if bytes
      originals[:bytes] = Shop::CartService::MAX_SESSION_CART_BYTES
      Shop::CartService.send(:remove_const, :MAX_SESSION_CART_BYTES)
      Shop::CartService.const_set(:MAX_SESSION_CART_BYTES, bytes)
    end
    yield
  ensure
    if originals.key?(:lines)
      Shop::CartService.send(:remove_const, :MAX_CART_LINES)
      Shop::CartService.const_set(:MAX_CART_LINES, originals[:lines])
    end
    if originals.key?(:bytes)
      Shop::CartService.send(:remove_const, :MAX_SESSION_CART_BYTES)
      Shop::CartService.const_set(:MAX_SESSION_CART_BYTES, originals[:bytes])
    end
  end
end
