# frozen_string_literal: true

require "test_helper"
require_relative "../support/db_triggers"

# Веха 1 / блок F: списание по техкарте, отрицательный остаток, prep_kitchen movements.
class BlockFStockFlowTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    TestDbTriggers.ensure!
  end

  test "barista order insert accepted deducts ingredient stock by product recipe" do
    tenant = create_tenant!(slug: "bf-barista-#{SecureRandom.hex(3)}")
    barista = create_user!(tenant: tenant, role_codes: %w[barista], email: "bf-b@#{SecureRandom.hex(4)}.test")
    open_cash_shift!(tenant: tenant, opened_by: barista)

    category = create_category!
    product = create_product!(category: category, name: "BF Latte")
    enable_product_for_tenant!(tenant: tenant, product: product, price: 200)

    ingredient = Ingredient.create!(name: "BF Milk #{SecureRandom.hex(2)}", unit: "ml", is_active: true)
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: 150)
    IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 500, min_qty: 50)

    login_as!(barista)
    post "/barista/orders", params: {
      cart_items: [ { product_id: product.id, quantity: 2 } ],
      payment_method: "cash"
    }
    assert_response :redirect

    stock = IngredientTenantStock.find_by!(tenant_id: tenant.id, ingredient_id: ingredient.id)
    assert_equal 200.to_d, stock.qty, "500 - 2×150 = 200"
  end

  test "shop order insert accepted deducts ingredient stock" do
    tenant = create_tenant!(slug: "bf-shop-#{SecureRandom.hex(3)}")
    category = create_category!
    product = create_product!(category: category, name: "BF Cappuccino")
    enable_product_for_tenant!(tenant: tenant, product: product, price: 250)

    ingredient = Ingredient.create!(name: "BF Beans #{SecureRandom.hex(2)}", unit: "g", is_active: true)
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: 18)
    IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 36, min_qty: 10)

    headers = { "X-Shop-Tenant" => tenant.id.to_s }
    post "/shop/api/cart/add",
      headers: headers,
      params: { product_id: product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    email = "bf-shop-#{SecureRandom.hex(4)}@test.local"
    verify_shop_email!(tenant_id: tenant.id, email: email)

    post "/shop/api/orders",
      headers: headers,
      params: shop_order_params(email: email, name: "Block F", payment_method: "card"),
      as: :json
    assert_response :success

    stock = IngredientTenantStock.find_by!(tenant_id: tenant.id, ingredient_id: ingredient.id)
    assert_equal 18.to_d, stock.qty, "36 - 18 = 18"
  end

  test "sale allowed when stock insufficient goes negative" do
    tenant = create_tenant!(slug: "bf-neg-#{SecureRandom.hex(3)}")
    category = create_category!
    product = create_product!(category: category, name: "BF Overdraw")
    enable_product_for_tenant!(tenant: tenant, product: product, price: 100)

    ingredient = Ingredient.create!(name: "BF Low #{SecureRandom.hex(2)}", unit: "g", is_active: true)
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: 50)
    IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 10, min_qty: 0)

    headers = { "X-Shop-Tenant" => tenant.id.to_s }
    post "/shop/api/cart/add", headers: headers, params: { product_id: product.id, quantity: 1 }, as: :json

    email = "bf-neg-#{SecureRandom.hex(4)}@test.local"
    verify_shop_email!(tenant_id: tenant.id, email: email)

    post "/shop/api/orders",
      headers: headers,
      params: shop_order_params(email: email, name: "Negative OK", payment_method: "card"),
      as: :json
    assert_response :success

    stock = IngredientTenantStock.find_by!(tenant_id: tenant.id, ingredient_id: ingredient.id)
    assert_equal(-40.to_d, stock.qty, "10 - 50 = -40 (QA 4.2)")
  end

  test "auto_deduct update path does not double deduct on noop update" do
    tenant = create_tenant!(slug: "bf-idem-#{SecureRandom.hex(3)}")
    barista = create_user!(tenant: tenant, role_codes: %w[barista])
    shift = open_cash_shift!(tenant: tenant, opened_by: barista)

    category = create_category!
    product = create_product!(category: category)
    enable_product_for_tenant!(tenant: tenant, product: product, price: 100)
    ingredient = Ingredient.create!(name: "BF Idem #{SecureRandom.hex(2)}", unit: "g", is_active: true)
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: 10)
    IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 100, min_qty: 0)

    order = Order.create!(
      tenant: tenant,
      cash_shift: shift,
      order_number: "IDEM-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "pending_payment",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 1,
      unit_price: 100,
      total_price: 100
    )

    order.update!(status: "accepted")
    stock_after_accept = IngredientTenantStock.find_by!(tenant_id: tenant.id, ingredient_id: ingredient.id)
    assert_equal 90.to_d, stock_after_accept.qty

    order.update!(customer_name: "Renamed")
    stock_after_update = IngredientTenantStock.find_by!(tenant_id: tenant.id, ingredient_id: ingredient.id)
    assert_equal 90.to_d, stock_after_update.qty, "no second deduction"
  end

  test "prep_kitchen draft movement confirm updates stock" do
    tenant = create_prep_kitchen_tenant!(slug: "bf-pk-#{SecureRandom.hex(3)}")
    manager = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_manager], email: "bf-pk@#{SecureRandom.hex(4)}.test")
    ingredient = Ingredient.create!(name: "BF PK #{SecureRandom.hex(2)}", unit: "g", is_active: true)

    login_as!(manager)
    post prep_kitchen_movements_path, params: {
      movement: {
        movement_type: "receipt",
        note: "Block F receipt",
        items: [ { ingredient_id: ingredient.id, qty_change: "25", unit_cost: "100" } ]
      }
    }
    assert_redirected_to prep_kitchen_movements_path

    movement = StockMovement.where(tenant_id: tenant.id).order(created_at: :desc).first!
    assert_equal "draft", movement.status

    post "/prep_kitchen/movements/#{movement.id}/confirm"
    assert_response :redirect
    assert_equal "confirmed", movement.reload.status

    stock = IngredientTenantStock.find_by!(tenant_id: tenant.id, ingredient_id: ingredient.id)
    assert_equal 25.to_d, stock.qty
  end
end
