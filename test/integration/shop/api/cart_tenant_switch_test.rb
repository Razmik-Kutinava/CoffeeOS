# frozen_string_literal: true

require "test_helper"

# TASK_120: переход в другую точку на том же хосте очищает корзину и сообщает об этом.
class Shop::Api::CartTenantSwitchTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant_a = create_tenant!(slug: "cartsw-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(slug: "cartsw-b-#{SecureRandom.hex(3)}")
    category  = create_category!
    @shared   = create_product!(category: category, name: "Капучино")
    @only_b   = create_product!(category: category, name: "Только B")
    @other_a  = create_product!(category: category, name: "Латте A")
    enable_product_for_tenant!(tenant: @tenant_a, product: @shared, price: 111)
    enable_product_for_tenant!(tenant: @tenant_b, product: @shared, price: 222)
    enable_product_for_tenant!(tenant: @tenant_b, product: @only_b, price: 300)
    enable_product_for_tenant!(tenant: @tenant_a, product: @other_a, price: 150)
  end

  def tenant_header(tenant)
    { "X-Shop-Tenant" => tenant.id.to_s }
  end

  def add_in_b(product = @shared)
    post "/shop/api/cart/add", headers: tenant_header(@tenant_b),
      params: { product_id: product.id, quantity: 1, selected_modifiers: [] }, as: :json
    assert_response :success
  end

  test "Subtask 1/6: ?tenant_id of other point on same host clears cart with reset flag" do
    add_in_b

    get "/shop/api/cart", params: { tenant_id: @tenant_a.id }
    assert_response :success
    assert_equal true, response.parsed_body["cart_reset"]
    assert_equal [], response.parsed_body["items"]
    assert_equal 0, response.parsed_body["total"]

    get "/shop/api/cart", params: { tenant_id: @tenant_a.id }
    assert_response :success
    assert_nil response.parsed_body["cart_reset"], "reset is reported once"
  end

  test "Subtask 1: X-Shop-Tenant of other point with product missing there — reset, not 404" do
    add_in_b(@only_b)

    get "/shop/api/cart", headers: tenant_header(@tenant_a)
    assert_response :success
    assert_equal true, response.parsed_body["cart_reset"]
    assert_equal [], response.parsed_body["items"]
  end

  test "Subtask 1: add in other point resets old lines and adds new one" do
    add_in_b(@only_b)

    post "/shop/api/cart/add", headers: tenant_header(@tenant_a),
      params: { product_id: @other_a.id, quantity: 1, selected_modifiers: [] }, as: :json
    assert_response :success
    assert_equal true, response.parsed_body["cart_reset"]
    assert_equal [ @other_a.id ], response.parsed_body["cart"].map { |l| l["product_id"] }
    assert_equal 150.0, response.parsed_body["total"]
  end

  test "Subtask 3: empty cart — no reset flag after switching point" do
    get "/shop/api/cart", headers: tenant_header(@tenant_b)
    assert_response :success

    get "/shop/api/cart", headers: tenant_header(@tenant_a)
    assert_response :success
    assert_nil response.parsed_body["cart_reset"]
    assert_equal [], response.parsed_body["items"]
  end

  test "Subtask 4: same point — no reset, contract unchanged" do
    add_in_b

    get "/shop/api/cart", headers: tenant_header(@tenant_b)
    assert_response :success
    refute response.parsed_body.key?("cart_reset")
    assert_equal 222.0, response.parsed_body["total"]
  end

  test "Subtask 5: after 404 'Товар недоступен' DELETE /cart lets guest add again" do
    post "/shop/api/cart/add", headers: tenant_header(@tenant_a),
      params: { product_id: @shared.id, quantity: 1, selected_modifiers: [] }, as: :json
    assert_response :success
    ProductTenantSetting.find_by!(tenant: @tenant_a, product: @shared).update_columns(is_sold_out: true)

    get "/shop/api/cart", headers: tenant_header(@tenant_a)
    assert_response :not_found
    assert_equal "Товар недоступен", response.parsed_body["error"]

    delete "/shop/api/cart", headers: tenant_header(@tenant_a)
    assert_response :success

    post "/shop/api/cart/add", headers: tenant_header(@tenant_a),
      params: { product_id: @other_a.id, quantity: 1, selected_modifiers: [] }, as: :json
    assert_response :success
    assert_equal 150.0, response.parsed_body["total"]
  end

  test "Subtask 8: cart of other host is neither transferred nor cleared" do
    old_base = ENV["SHOP_BASE_DOMAIN"]
    ENV["SHOP_BASE_DOMAIN"] = "cartsw.test"

    host! "#{@tenant_b.slug}.cartsw.test"
    post "/shop/api/cart/add", params: { product_id: @shared.id, quantity: 1, selected_modifiers: [] }, as: :json
    assert_response :success

    host! "#{@tenant_a.slug}.cartsw.test"
    get "/shop/api/cart"
    assert_response :success
    assert_equal [], response.parsed_body["items"]
    assert_nil response.parsed_body["cart_reset"]

    host! "#{@tenant_b.slug}.cartsw.test"
    get "/shop/api/cart"
    assert_response :success
    assert_equal 222.0, response.parsed_body["total"]
  ensure
    ENV["SHOP_BASE_DOMAIN"] = old_base
  end
end
