# frozen_string_literal: true

require "test_helper"

class Shop::CartServiceTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant   = create_tenant!
    category  = create_category!
    @product  = create_product!(category: category)
    @setting  = enable_product_for_tenant!(tenant: @tenant, product: @product, price: 150)
    @session  = {}
  end

  def cart
    Shop::CartService.new(@session, @tenant.id)
  end

  # ---------------------------------------------------------------------------
  # Session key constant
  # ---------------------------------------------------------------------------

  test "SESSION_KEY is :shop_cart" do
    assert_equal :shop_cart, Shop::CartService::SESSION_KEY
  end

  # ---------------------------------------------------------------------------
  # add!
  # ---------------------------------------------------------------------------

  test "add! with valid product adds item to session" do
    cart.add!(product_id: @product.id, quantity: 1, selected_modifiers: [])
    assert_equal 1, @session[:shop_cart].size
    assert_equal @product.id, @session[:shop_cart].first["product_id"]
  end

  test "add! records correct quantity in session" do
    cart.add!(product_id: @product.id, quantity: 3, selected_modifiers: [])
    assert_equal 3, @session[:shop_cart].first["quantity"]
  end

  test "add! same product twice accumulates quantity" do
    svc = cart
    svc.add!(product_id: @product.id, quantity: 2, selected_modifiers: [])
    svc.add!(product_id: @product.id, quantity: 3, selected_modifiers: [])
    assert_equal 1, @session[:shop_cart].size
    assert_equal 5, @session[:shop_cart].first["quantity"]
  end

  test "add! with unavailable product (no setting) raises ActiveRecord::RecordNotFound" do
    other_tenant  = create_tenant!
    category2     = create_category!
    other_product = create_product!(category: category2)
    # other_product has no ProductTenantSetting for @tenant → shop_available? is false
    assert_raises(ActiveRecord::RecordNotFound) do
      cart.add!(product_id: other_product.id, quantity: 1, selected_modifiers: [])
    end
  end

  test "add! with sold_out product raises ActiveRecord::RecordNotFound" do
    category2   = create_category!
    product_out = create_product!(category: category2)
    enable_product_for_tenant!(tenant: @tenant, product: product_out, price: 80, is_enabled: true)
    ProductTenantSetting.find_by!(tenant: @tenant, product: product_out)
                        .update_columns(is_sold_out: true, sold_out_reason: "manual")
    assert_raises(ActiveRecord::RecordNotFound) do
      cart.add!(product_id: product_out.id, quantity: 1, selected_modifiers: [])
    end
  end

  test "add! with disabled product raises ActiveRecord::RecordNotFound" do
    category2      = create_category!
    product_disabled = create_product!(category: category2)
    enable_product_for_tenant!(
      tenant:     @tenant,
      product:    product_disabled,
      price:      90,
      is_enabled: false
    )
    assert_raises(ActiveRecord::RecordNotFound) do
      cart.add!(product_id: product_disabled.id, quantity: 1, selected_modifiers: [])
    end
  end

  # ---------------------------------------------------------------------------
  # remove!
  # ---------------------------------------------------------------------------

  test "remove!(0) removes first item from session" do
    svc = cart
    svc.add!(product_id: @product.id, quantity: 1, selected_modifiers: [])
    assert_equal 1, @session[:shop_cart].size

    svc.remove!(0)
    assert_equal 0, @session[:shop_cart].size
  end

  # ---------------------------------------------------------------------------
  # update_quantity!
  # ---------------------------------------------------------------------------

  test "update_quantity! increases quantity by delta" do
    svc = cart
    svc.add!(product_id: @product.id, quantity: 2, selected_modifiers: [])
    svc.update_quantity!(0, 3)
    assert_equal 5, @session[:shop_cart].first["quantity"]
  end

  test "update_quantity! rejects negative delta below minimum quantity" do
    svc = cart
    svc.add!(product_id: @product.id, quantity: 1, selected_modifiers: [])
    assert_raises(ActiveRecord::RecordNotFound) { svc.update_quantity!(0, -1) }
    assert_equal 1, @session[:shop_cart].first["quantity"]
  end

  test "update_quantity! rejects delta above MAX_ITEM_QUANTITY" do
    @session[:shop_cart] = [
      { "product_id" => @product.id, "quantity" => Shop::CartService::MAX_ITEM_QUANTITY, "selected_modifiers" => [] }
    ]
    svc = cart
    assert_raises(ActiveRecord::RecordNotFound) { svc.update_quantity!(0, 1) }
  end

  # ---------------------------------------------------------------------------
  # clear!
  # ---------------------------------------------------------------------------

  test "clear! empties the session cart" do
    svc = cart
    svc.add!(product_id: @product.id, quantity: 2, selected_modifiers: [])
    assert_equal 1, @session[:shop_cart].size

    svc.clear!
    assert_equal 0, @session[:shop_cart].size
  end

  # ---------------------------------------------------------------------------
  # json_lines
  # ---------------------------------------------------------------------------

  test "add! does not store removed_modifiers in session cookie payload" do
    group = ProductModifierGroup.create!(product: @product, name: "Добавки", is_required: false, sort_order: 1)
    sugar = ProductModifierOption.create!(group: group, name: "Сахар", price_delta: 0, sort_order: 1)
    ProductModifierOption.create!(group: group, name: "Сироп", price_delta: 30, sort_order: 2)
    selected = [ { id: sugar.id, name: "Сахар", price: 0 } ]

    cart.add!(product_id: @product.id, quantity: 1, selected_modifiers: selected)
    line = @session[:shop_cart].first
    refute line.key?("removed_modifiers")

    result = cart.json_lines
    assert_equal "Сироп", result[:items].first[:removed_modifiers].first["name"]
  end

  test "add! stores only modifier id in session to avoid cookie overflow" do
    group = ProductModifierGroup.create!(product: @product, name: "Молоко", is_required: false, sort_order: 1)
    oat = ProductModifierOption.create!(group: group, name: "Овсяное молоко", price_delta: 50, sort_order: 1)
    selected = [ { id: oat.id, name: "Овсяное молоко", price: 50 } ]

    cart.add!(product_id: @product.id, quantity: 1, selected_modifiers: selected)
    stored = @session[:shop_cart].first["selected_modifiers"].first
    assert_equal({ "id" => oat.id }, stored)
    refute stored.key?("name"), "name не должен храниться в cookie"
    refute stored.key?("price"), "price не должен храниться в cookie"
  end

  test "json_lines hydrates modifier name and price from id" do
    group = ProductModifierGroup.create!(product: @product, name: "Молоко", is_required: false, sort_order: 1)
    oat = ProductModifierOption.create!(group: group, name: "Овсяное молоко", price_delta: 50, sort_order: 1)

    cart.add!(product_id: @product.id, quantity: 1, selected_modifiers: [ { id: oat.id, name: "Овсяное молоко", price: 50 } ])
    mod = cart.json_lines[:items].first[:selected_modifiers].first
    assert_equal oat.id, mod["id"]
    assert_equal "Овсяное молоко", mod["name"]
    assert_equal 50.0, mod["price"]
  end

  test "json_lines with no items returns items empty array and total 0" do
    result = cart.json_lines
    assert_equal [], result[:items]
    assert_equal 0,  result[:total]
  end

  test "json_lines calculates line_total as price multiplied by quantity" do
    svc = cart
    svc.add!(product_id: @product.id, quantity: 3, selected_modifiers: [])
    result = svc.json_lines
    line = result[:items].first
    assert_equal 150.0,  line[:price]
    assert_equal 450.0,  line[:line_total]
    assert_equal 450.0,  result[:total]
  end

  test "json_lines with multiple lines sums total correctly" do
    category2  = create_category!
    product2   = create_product!(category: category2)
    enable_product_for_tenant!(tenant: @tenant, product: product2, price: 200)

    svc = cart
    svc.add!(product_id: @product.id, quantity: 2, selected_modifiers: [])  # 300
    svc.add!(product_id: product2.id, quantity: 1, selected_modifiers: [])  # 200
    result = svc.json_lines
    assert_equal 500.0, result[:total]
  end

  test "json_lines includes product description for peek full card" do
    @product.update!(description: "Кардамон и корица — пряный акцент")
    cart.add!(product_id: @product.id, quantity: 1, selected_modifiers: [])
    line = cart.json_lines[:items].first
    assert_equal "Кардамон и корица — пряный акцент", line[:description]
    assert_equal @product.name, line[:product_name]
  end
end
