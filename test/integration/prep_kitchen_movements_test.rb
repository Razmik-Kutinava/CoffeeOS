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

  test "manager can create movement via form-style params" do
    tenant = create_tenant!(name: "Kitchen F", slug: "kitchen-f")
    manager = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_manager], email: "km4@test.com", name: "Manager3")
    ingredient = create_ingredient!

    login_as!(manager)
    assert_difference -> { StockMovement.where(tenant_id: tenant.id).count }, 1 do
      post prep_kitchen_movements_path, params: {
        movement: {
          movement_type: "receipt",
          note: "demo receipt",
          items: [
            { ingredient_id: "", qty_change: "", unit_cost: "" },
            { ingredient_id: ingredient.id, qty_change: "12.5", unit_cost: "99.9" }
          ]
        }
      }
    end

    assert_redirected_to prep_kitchen_movements_path
    movement = StockMovement.where(tenant_id: tenant.id).order(created_at: :desc).first!
    assert_equal "draft", movement.status
    assert_equal "receipt", movement.movement_type
    assert_equal "demo receipt", movement.note
    assert_equal 1, movement.stock_movement_items.count
    assert_equal ingredient.id, movement.stock_movement_items.first.ingredient_id
    assert_equal BigDecimal("12.5"), movement.stock_movement_items.first.qty_change
  end
end
