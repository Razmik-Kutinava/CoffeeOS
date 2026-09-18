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

  # T-A2c
  test "deducts when stock sufficient" do
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
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )

    Inventory::OrderRecipeDeduction.call!(order: order)

    stock = IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: @ingredient.id)
    assert_equal 15.to_d, stock.qty, "40 - 1×25"
  end

  # T-A2b — soft-fail: no deduct + audit signal (не raise для rollback оплаты)
  test "does not deduct when insufficient; signals shortfall" do
    order = Order.create!(
      tenant: @tenant,
      order_number: "DED-LOW",
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

    assert_difference -> { AdminAuditLog.where(action: "inventory_deduction_skipped").count }, 1 do
      assert_nothing_raised { Inventory::OrderRecipeDeduction.call!(order: order) }
    end

    stock = IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: @ingredient.id)
    assert_equal 40.to_d, stock.qty
    log = AdminAuditLog.where(action: "inventory_deduction_skipped").order(created_at: :desc).first
    assert_equal "insufficient_stock", log.details["reason"]
  end

  # T-A2a
  test "skips deduct and reports when stock row absent" do
    IngredientTenantStock.where(tenant_id: @tenant.id, ingredient_id: @ingredient.id).delete_all
    order = Order.create!(
      tenant: @tenant,
      order_number: "DED-MISS",
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
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )

    assert_difference -> { AdminAuditLog.where(action: "inventory_deduction_skipped").count }, 1 do
      assert_nothing_raised { Inventory::OrderRecipeDeduction.call!(order: order) }
    end

    refute IngredientTenantStock.exists?(tenant_id: @tenant.id, ingredient_id: @ingredient.id),
           "must not create qty=0 trap row"
    log = AdminAuditLog.where(action: "inventory_deduction_skipped").order(created_at: :desc).first
    assert_equal "stock_row_absent", log.details["reason"]
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
