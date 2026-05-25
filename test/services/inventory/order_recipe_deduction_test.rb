# frozen_string_literal: true

require "test_helper"

class Inventory::OrderRecipeDeductionTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @category = create_category!
    @product = create_product!(category: @category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)
    @ingredient = Ingredient.create!(name: "Deduction Ing", unit: "g", is_active: true)
    ProductRecipe.create!(product: @product, ingredient: @ingredient, qty_per_serving: 25)
    IngredientTenantStock.create!(tenant: @tenant, ingredient: @ingredient, qty: 40, min_qty: 0)
  end

  teardown { Current.reset }

  test "deducts stock for accepted order with items" do
    order = Order.create!(
      tenant: @tenant,
      order_number: "DED-1",
      source: "manual",
      status: "accepted",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    OrderItem.create!(
      order: order,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 2,
      unit_price: 200,
      total_price: 400
    )

    Inventory::OrderRecipeDeduction.call!(order: order)

    stock = IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: @ingredient.id)
    assert_equal(-10.to_d, stock.qty, "40 - 2×25 = -10 allowed")
  end

  test "no-op when order not accepted" do
    order = Order.create!(
      tenant: @tenant,
      order_number: "DED-2",
      source: "manual",
      status: "pending_payment",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    OrderItem.create!(
      order: order,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )

    Inventory::OrderRecipeDeduction.call!(order: order)

    stock = IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: @ingredient.id)
    assert_equal 40.to_d, stock.qty
  end
end
