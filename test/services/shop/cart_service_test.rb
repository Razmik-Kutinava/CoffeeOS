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

  test "json_lines does not EXISTS product_tenant_settings per line" do
    category2 = create_category!
    product2  = create_product!(category: category2)
    enable_product_for_tenant!(tenant: @tenant, product: product2, price: 200)

    svc = cart
    svc.add!(product_id: @product.id, quantity: 1, selected_modifiers: [])
    svc.add!(product_id: product2.id, quantity: 1, selected_modifiers: [])

    exists_count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      sql = payload[:sql].to_s
      next unless sql.match?(/product_tenant_settings/i)
      next unless sql.match?(/SELECT 1 AS one|EXISTS/i) || sql.include?("LIMIT $") && sql.include?("is_sold_out")

      exists_count += 1
    end

    svc.json_lines
    ActiveSupport::Notifications.unsubscribe(subscriber)

    assert_equal 0, exists_count, "RUBY-V: json_lines must use preloaded settings, got #{exists_count} EXISTS"
  end

  test "add! rejects client-only modifier price without id" do
    assert_raises(ActiveRecord::RecordNotFound) do
      cart.add!(
        product_id: @product.id,
        quantity: 1,
        selected_modifiers: [ { name: "Скидка", price: -999 } ]
      )
    end
  end

  test "json_lines includes product description for peek full card" do
    @product.update!(description: "Кардамон и корица — пряный акцент")
    cart.add!(product_id: @product.id, quantity: 1, selected_modifiers: [])
    line = cart.json_lines[:items].first
    assert_equal "Кардамон и корица — пряный акцент", line[:description]
    assert_equal @product.name, line[:product_name]
  end

  # ---------------------------------------------------------------------------
  # TASK_93-H — overflow guards (T-H2a / T-H2b)
  # ---------------------------------------------------------------------------

  test "T-H2a add! raises OverflowError when distinct lines exceed MAX_CART_LINES" do
    with_cart_overflow_caps(lines: 3) do
      category = create_category!(slug: "h2a-cat-#{SecureRandom.hex(3)}")
      products = 4.times.map do |i|
        p = create_product!(category: category, slug: "h2a-p-#{i}-#{SecureRandom.hex(2)}", name: "H2a #{i}")
        enable_product_for_tenant!(tenant: @tenant, product: p, price: 100 + i)
        p
      end

      svc = cart
      products.take(3).each do |p|
        svc.add!(product_id: p.id, quantity: 1, selected_modifiers: [])
      end
      assert_equal 3, @session[:shop_cart].size

      assert_raises(Shop::CartService::OverflowError) do
        svc.add!(product_id: products.last.id, quantity: 1, selected_modifiers: [])
      end
      assert_operator @session[:shop_cart].size, :<=, 3
    end
  end

  test "T-H2b add! raises OverflowError when estimated session cart bytes exceed budget" do
    with_cart_overflow_caps(bytes: 80) do
      category = create_category!(slug: "h2b-cat-#{SecureRandom.hex(3)}")
      products = 5.times.map do |i|
        p = create_product!(category: category, slug: "h2b-p-#{i}-#{SecureRandom.hex(2)}", name: "H2b #{i}")
        enable_product_for_tenant!(tenant: @tenant, product: p, price: 100)
        p
      end

      svc = cart
      assert_raises(Shop::CartService::OverflowError) do
        products.each do |p|
          svc.add!(product_id: p.id, quantity: 1, selected_modifiers: [])
        end
      end
    end
  end

  private

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
