# frozen_string_literal: true

require "test_helper"
require_relative "../support/db_triggers"

# E2E-тесты триггеров БД: списание ингредиентов при принятии заказа
# и автоматический стоп-лист при нулевом остатке
class DbTriggersTest < ActionDispatch::IntegrationTest
  setup do
    TestDbTriggers.ensure!
  end

  def create_ingredient!(name: "ing-#{SecureRandom.hex(3)}", unit: "g")
    Ingredient.create!(name: name, unit: unit, is_active: true)
  end

  test "auto_deduct: ingredients are deducted when order status changes to accepted" do
    tenant = create_tenant!(name: "Trig Tenant", slug: "trig-tenant-#{SecureRandom.hex(4)}")
    user = create_user!(tenant: tenant, role_codes: %w[barista], email: "trig@test.com", name: "Trig")
    cash_shift = open_cash_shift!(tenant: tenant, opened_by: user)

    category = create_category!
    product = create_product!(category: category, name: "Latte")
    enable_product_for_tenant!(tenant: tenant, product: product, price: 150)

    ingredient = create_ingredient!(name: "Milk", unit: "ml")
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: 200)

    IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 500, min_qty: 50)

    order = Order.create!(
      tenant: tenant,
      cash_shift: cash_shift,
      order_number: "TRIG-#{SecureRandom.hex(4)}",
      source: "manual",
      status: "pending_payment",
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )
    OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 2,
      unit_price: 150,
      total_price: 300
    )

    stock_before = IngredientTenantStock.find_by!(tenant_id: tenant.id, ingredient_id: ingredient.id)
    assert_equal 500.to_d, stock_before.qty, "Stock should be 500 before accept"

    order.update!(status: "accepted")

    stock_after = IngredientTenantStock.find_by!(tenant_id: tenant.id, ingredient_id: ingredient.id)
    # 2 portions * 200 ml = 400
    assert_equal 100.to_d, stock_after.qty, "Stock should decrease by 400 (2*200) after accept"
  end

  test "auto_stop_list: product is marked sold_out when ingredient stock goes to zero" do
    tenant = create_tenant!(name: "Stop Tenant", slug: "stop-tenant-#{SecureRandom.hex(4)}")
    category = create_category!
    product = create_product!(category: category, name: "Cappuccino")
    enable_product_for_tenant!(tenant: tenant, product: product, price: 120, is_sold_out: false)

    ingredient = create_ingredient!(name: "Beans", unit: "g")
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: 18)

    stock = IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 18, min_qty: 10)

    setting = ProductTenantSetting.find_by!(tenant_id: tenant.id, product_id: product.id)
    assert_equal false, setting.is_sold_out, "Product should not be sold out initially"
    assert_nil setting.sold_out_reason

    stock.update!(qty: 0)

    setting.reload
    assert_equal true, setting.is_sold_out, "Product should be marked sold_out when stock zero"
    assert_equal "stock_empty", setting.sold_out_reason, "Reason should be stock_empty"
  end

  test "auto_stop_list: does not fire when stock stays above zero" do
    tenant = create_tenant!(name: "NoStop Tenant", slug: "nostop-#{SecureRandom.hex(4)}")
    category = create_category!
    product = create_product!(category: category, name: "Americano")
    enable_product_for_tenant!(tenant: tenant, product: product, price: 80, is_sold_out: false)

    ingredient = create_ingredient!(name: "Water", unit: "ml")
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: 250)

    stock = IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 100, min_qty: 50)
    setting = ProductTenantSetting.find_by!(tenant_id: tenant.id, product_id: product.id)

    stock.update!(qty: 50)

    setting.reload
    assert_equal false, setting.is_sold_out, "Product should stay available when stock > 0"
  end
end
