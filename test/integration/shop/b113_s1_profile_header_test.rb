# frozen_string_literal: true

require "test_helper"

# B1.13-S1: «Профиль › ID» в шапке · убрать «Профиль» из bottom nav
class Shop::B113S1ProfileHeaderTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    @tenant = create_tenant!(slug: "b113-s1-#{SecureRandom.hex(3)}")
    @category = create_category!
    @product = create_product!(category: @category, slug: "b113-prod-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 199)
    @email = "b113-#{SecureRandom.hex(4)}@example.com"
    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "1"
  end

  teardown do
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
  end

  test "header source: profile link replaces vitrina label" do
    header = File.read(Rails.root.join("app/frontend/components/Header.svelte"))
    lib = File.read(Rails.root.join("app/frontend/lib/shopProfileHeader.js"))

    refute_includes header, ">Витрина<"
    refute_includes header, "Витрина</span>"
    assert_includes header, 'data-testid="shop-header-profile"'
    assert_includes header, 'push("/profile")'
    assert_includes header, "formatProfileIdShort"
    assert_includes header, "shop-hours-display"
    assert_includes lib, "formatProfileIdShort"
  end

  test "bottom nav source: no profile tab" do
    bottom = File.read(Rails.root.join("app/frontend/components/BottomNav.svelte"))

    refute_includes bottom, ">Профиль<"
    refute_includes bottom, "push('/profile')"
    assert_includes bottom, "Каталог"
    assert_includes bottom, "Избранное"
  end

  test "formatProfileIdShort matches acceptance truncation rule" do
    assert_equal "100234", format_profile_id_short("100234")
    assert_equal "1002…78", format_profile_id_short("1002345678")
    uuid = "655aaccb-004a-4bb9-a50a-ce618854dda3"
    assert_equal "655a…a3", format_profile_id_short(uuid)
  end

  private

  # Зеркало app/frontend/lib/shopProfileHeader.js для теста
  def format_profile_id_short(id)
    s = id.to_s.strip
    return s if s.length <= 8

    "#{s[0, 4]}…#{s[-2, 2]}"
  end

  test "profile api returns id after order binds customer session" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      assert_equal 200, sess.response.status

      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "B113 Guest", payment_method: "cash"),
        as: :json
      assert_equal 200, sess.response.status, sess.response.body

      sess.get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id)
      assert_equal 200, sess.response.status
      body = sess.response.parsed_body
      assert body["id"].present?, "ожидался id клиента в profile после заказа"
      assert body["name"].present?
    end
  end

  test "profile api guest has no id" do
    get "/shop/api/profile", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    body = response.parsed_body
    assert_nil body["id"]
    assert_equal "Гость", body["name"]
  end
end
