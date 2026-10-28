# frozen_string_literal: true

require "test_helper"

# TASK_120 Патч 1: cookie_store с expire_after пишет cookie на каждом ответе. Ответ параллельного
# запроса, начатого со старой cookie, затирал сброс корзины и добавление товара.
# Гонку воспроизводим последовательно: запрос уходит с подменённой старой cookie.
class Shop::Api::SessionStaleSnapshotTest < ActionDispatch::IntegrationTest
  include TestFactories

  SESSION_COOKIE = "_coffeeos_session"
  READ_ONLY_PATHS = %w[
    /shop/api/categories
    /shop/api/orders/active
    /shop/api/frequent_products
    /shop/api/config
    /shop/api/tenants
  ].freeze

  setup do
    @tenant_a = create_tenant!(slug: "stale-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(slug: "stale-b-#{SecureRandom.hex(3)}")
    category  = create_category!
    @coffee   = create_product!(category: category, name: "Капучино")
    @tea      = create_product!(category: category, name: "Чай")
    [ @tenant_a, @tenant_b ].each do |t|
      enable_product_for_tenant!(tenant: t, product: @coffee, price: 100)
      enable_product_for_tenant!(tenant: t, product: @tea, price: 50)
    end
  end

  def tenant_header(tenant)
    { "X-Shop-Tenant" => tenant.id.to_s }
  end

  def add_to_cart(tenant, product)
    post "/shop/api/cart/add", headers: tenant_header(tenant),
      params: { product_id: product.id, quantity: 1, selected_modifiers: [] }, as: :json
    assert_response :success
  end

  def session_cookie_written?
    Array(response.headers["set-cookie"]).join("\n").include?("#{SESSION_COOKIE}=")
  end

  # Запрос со старым снимком cookie; браузер сохраняет ответ, только если в нём есть Set-Cookie.
  def stale_request(stale_cookie)
    current = cookies[SESSION_COOKIE]
    cookies[SESSION_COOKIE] = stale_cookie
    yield
    written = session_cookie_written?
    cookies[SESSION_COOKIE] = current unless written
    written
  end

  test "Subtask 1/6: read-only requests with stale cookie do not bring back cart of point A after reset in B" do
    add_to_cart(@tenant_a, @coffee)
    snapshot_a = cookies[SESSION_COOKIE]

    get "/shop/api/cart", headers: tenant_header(@tenant_b)
    assert_response :success
    assert_equal true, response.parsed_body["cart_reset"]

    READ_ONLY_PATHS.each do |path|
      written = stale_request(snapshot_a) { get path, headers: tenant_header(@tenant_b) }
      assert_response :success, path
      refute written, "#{path} must not rewrite session cookie"
    end

    get "/shop/api/cart", headers: tenant_header(@tenant_b)
    assert_response :success
    assert_nil response.parsed_body["cart_reset"], "reset is not repeated"

    get "/shop/api/cart", headers: tenant_header(@tenant_a)
    assert_response :success
    assert_equal [], response.parsed_body["items"], "cart of point A stays cleared"
    assert_nil response.parsed_body["cart_reset"]
  end

  test "Subtask 1a: two parallel GET /cart with stale cookie both reset to the same state" do
    add_to_cart(@tenant_a, @coffee)
    snapshot_a = cookies[SESSION_COOKIE]

    get "/shop/api/cart", headers: tenant_header(@tenant_b)
    assert_equal true, response.parsed_body["cart_reset"]

    written = stale_request(snapshot_a) { get "/shop/api/cart", headers: tenant_header(@tenant_b) }
    assert_equal true, response.parsed_body["cart_reset"]
    assert written, "reset changes session — cookie is written"

    get "/shop/api/cart", headers: tenant_header(@tenant_a)
    assert_equal [], response.parsed_body["items"]
    assert_nil response.parsed_body["cart_reset"]
  end

  test "Subtask 4/6: stale read-only request (including unchanged GET /cart) does not drop item just added" do
    add_to_cart(@tenant_a, @coffee)
    before_add = cookies[SESSION_COOKIE]
    add_to_cart(@tenant_a, @tea)

    (READ_ONLY_PATHS + [ "/shop/api/cart" ]).each do |path|
      written = stale_request(before_add) { get path, headers: tenant_header(@tenant_a) }
      assert_response :success, path
      refute written, "#{path} must not rewrite session cookie"
    end

    get "/shop/api/cart", headers: tenant_header(@tenant_a)
    assert_equal [ @coffee.id, @tea.id ].sort, response.parsed_body["items"].map { |l| l["product_id"] }.sort
  end

  test "Subtask 10: requests that change session still write cookie" do
    add_to_cart(@tenant_a, @coffee)
    assert session_cookie_written?, "POST /cart/add"

    patch "/shop/api/cart/items/0", headers: tenant_header(@tenant_a), params: { delta: 1 }, as: :json
    assert_response :success
    assert session_cookie_written?, "PATCH /cart/items/:index"

    get "/shop/api/cart", headers: tenant_header(@tenant_b)
    assert_equal true, response.parsed_body["cart_reset"]
    assert session_cookie_written?, "GET /cart with reset"

    add_to_cart(@tenant_b, @tea)
    delete "/shop/api/cart", headers: tenant_header(@tenant_b)
    assert_response :success
    assert session_cookie_written?, "DELETE /cart"
  end

  test "Subtask 10: first GET /cart without session cookie creates and writes session" do
    get "/shop/api/cart", headers: tenant_header(@tenant_a)
    assert_response :success
    assert session_cookie_written?
  end

  test "Subtask 11: GET /shop still refreshes cookie expiry" do
    add_to_cart(@tenant_a, @coffee)

    get "/shop", params: { tenant_id: @tenant_a.id }
    assert_response :success
    header = Array(response.headers["set-cookie"]).join("\n")
    assert_includes header, "#{SESSION_COOKIE}="
    assert_match(/expires=/i, header)
  end

  test "Subtask 12: error response without session change does not write cookie" do
    add_to_cart(@tenant_a, @coffee)
    ProductTenantSetting.find_by!(tenant: @tenant_a, product: @coffee).update_columns(is_sold_out: true)

    get "/shop/api/cart", headers: tenant_header(@tenant_a)
    assert_response :not_found
    refute session_cookie_written?
  end
end
