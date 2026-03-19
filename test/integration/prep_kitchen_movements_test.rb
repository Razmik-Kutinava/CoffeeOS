require "test_helper"

class PrepKitchenMovementsTest < ActionDispatch::IntegrationTest
  def create_ingredient!(name: "ing-#{SecureRandom.hex(3)}")
    Ingredient.create!(name: name, unit: "g", is_active: true)
  end

  test "manager can create and confirm movement" do
    tenant = create_tenant!(name: "Kitchen D", slug: "kitchen-d")
    manager = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_manager], email: "km2@test.com", name: "Manager")
    ingredient = create_ingredient!

    login_as!(manager)
    movement = StockMovement.create!(
      tenant_id: tenant.id,
      movement_type: "receipt",
      status: "draft",
      created_by: manager
    )
    StockMovementItem.create!(movement: movement, ingredient: ingredient, qty_change: 10, unit_cost: 100)

    post "/prep_kitchen/movements/#{movement.id}/confirm"
    assert_response :redirect

    assert_equal "confirmed", movement.reload.status
    stock = IngredientTenantStock.find_by!(tenant_id: tenant.id, ingredient_id: ingredient.id)
    assert_equal 10.to_d, stock.qty
  end

  test "worker cannot confirm movement" do
    tenant = create_tenant!(name: "Kitchen E", slug: "kitchen-e")
    manager = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_manager], email: "km3@test.com", name: "Manager2")
    worker = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_worker], email: "kw3@test.com", name: "Worker2")
    ingredient = create_ingredient!

    movement = StockMovement.create!(
      tenant_id: tenant.id,
      movement_type: "receipt",
      status: "draft",
      created_by: manager
    )
    StockMovementItem.create!(movement: movement, ingredient: ingredient, qty_change: 5)

    login_as!(worker)
    post "/prep_kitchen/movements/#{movement.id}/confirm"
    assert_response :redirect
    assert_not_equal "confirmed", movement.reload.status
  end
end
