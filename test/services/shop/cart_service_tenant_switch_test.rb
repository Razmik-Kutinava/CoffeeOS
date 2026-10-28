# frozen_string_literal: true

require "test_helper"

# TASK_120: корзина помнит точку, в которой её наполняли; при чтении из другой точки — сброс.
class Shop::CartServiceTenantSwitchTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant_a = create_tenant!
    @tenant_b = create_tenant!
    category  = create_category!
    @shared   = create_product!(category: category, name: "Капучино")
    @only_b   = create_product!(category: category, name: "Только B")
    enable_product_for_tenant!(tenant: @tenant_a, product: @shared, price: 111)
    enable_product_for_tenant!(tenant: @tenant_b, product: @shared, price: 222)
    enable_product_for_tenant!(tenant: @tenant_b, product: @only_b, price: 300)
    @session = {}
  end

  def cart_in(tenant)
    Shop::CartService.new(@session, tenant.id)
  end

  test "TENANT_SESSION_KEY is :shop_cart_tenant_id" do
    assert_equal :shop_cart_tenant_id, Shop::CartService::TENANT_SESSION_KEY
  end

  test "add! remembers the point where the cart is filled" do
    cart_in(@tenant_b).add!(product_id: @shared.id, quantity: 1, selected_modifiers: [])

    assert_equal @tenant_b.id.to_s, @session[:shop_cart_tenant_id]
  end

  test "Subtask 1: cart of point B read from point A is cleared, not repriced" do
    cart_in(@tenant_b).add!(product_id: @shared.id, quantity: 2, selected_modifiers: [])

    svc = cart_in(@tenant_a)
    data = svc.json_lines

    assert svc.tenant_reset?
    assert_equal [], data[:items]
    assert_equal 0, data[:total]
    assert_equal [], @session[:shop_cart]
    assert_nil @session[:shop_cart_tenant_id]
  end

  test "Subtask 1: cart with product missing in point A is cleared instead of 'Товар недоступен'" do
    cart_in(@tenant_b).add!(product_id: @only_b.id, quantity: 1, selected_modifiers: [])

    svc = cart_in(@tenant_a)
    assert_nothing_raised { svc.json_lines }
    assert svc.tenant_reset?
    assert_equal [], @session[:shop_cart]
  end

  test "Subtask 1: after reset add! in point A stamps point A" do
    cart_in(@tenant_b).add!(product_id: @only_b.id, quantity: 1, selected_modifiers: [])

    svc = cart_in(@tenant_a)
    svc.add!(product_id: @shared.id, quantity: 1, selected_modifiers: [])

    assert svc.tenant_reset?
    assert_equal 1, @session[:shop_cart].size
    assert_equal @tenant_a.id.to_s, @session[:shop_cart_tenant_id]
    assert_equal 111.0, svc.json_lines[:total]
  end

  test "Subtask 3: empty cart with mark of other point is not reported as reset" do
    @session[:shop_cart] = []
    @session[:shop_cart_tenant_id] = @tenant_b.id.to_s

    svc = cart_in(@tenant_a)

    refute svc.tenant_reset?
    assert_nil @session[:shop_cart_tenant_id]
  end

  test "Subtask 4: same point — no reset, cart and price unchanged" do
    cart_in(@tenant_b).add!(product_id: @shared.id, quantity: 2, selected_modifiers: [])

    svc = cart_in(@tenant_b)
    data = svc.json_lines

    refute svc.tenant_reset?
    assert_equal 1, data[:items].size
    assert_equal 444.0, data[:total]
    assert_equal @tenant_b.id.to_s, @session[:shop_cart_tenant_id]
  end

  test "Subtask 7: legacy cart without mark is processed as before" do
    @session[:shop_cart] = [ { "product_id" => @shared.id, "quantity" => 1, "selected_modifiers" => [] } ]

    svc = cart_in(@tenant_a)
    data = svc.json_lines

    refute svc.tenant_reset?
    assert_equal 111.0, data[:total]
  end

  test "clear! drops the point mark" do
    cart_in(@tenant_b).add!(product_id: @shared.id, quantity: 1, selected_modifiers: [])

    cart_in(@tenant_b).clear!

    assert_equal [], @session[:shop_cart]
    assert_nil @session[:shop_cart_tenant_id]
  end

  test "replace_line! keeps the point mark of the current point" do
    cart_in(@tenant_b).add!(product_id: @shared.id, quantity: 1, selected_modifiers: [])
    @session.delete(:shop_cart_tenant_id)

    cart_in(@tenant_b).replace_line!(0, selected_modifiers: [], quantity: 2)

    assert_equal @tenant_b.id.to_s, @session[:shop_cart_tenant_id]
  end

  test "Subtask 1: order in point A with cart of point B is not created from foreign items" do
    cart_in(@tenant_b).add!(product_id: @shared.id, quantity: 1, selected_modifiers: [])
    Current.tenant_id = @tenant_a.id

    error = assert_raises(Shop::OrderCreator::Error) do
      Shop::OrderCreator.new(@session, tenant: @tenant_a).call!({ payment_method: "card" })
    end
    assert_match(/Корзина пуста/, error.message)
  ensure
    Current.reset
  end
end
