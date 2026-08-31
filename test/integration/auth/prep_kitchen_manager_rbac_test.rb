# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок C: prep_kitchen_manager — полный доступ к цеху; чужие панели закрыты.
class Auth::PrepKitchenManagerRbacTest < ActionDispatch::IntegrationTest
  ALLOWED_PATHS = [
    [ :dashboard, :prep_kitchen_dashboard_path ],
    [ :sales_points, :prep_kitchen_sales_points_path ],
    [ :queue, :prep_kitchen_queue_path ],
    [ :recipes, :prep_kitchen_recipes_path ],
    [ :inventory, :prep_kitchen_inventory_path ],
    [ :movements, :prep_kitchen_movements_path ],
    [ :stop_list, :prep_kitchen_stop_list_path ],
    [ :incidents, :prep_kitchen_incidents_path ],
    [ :reports, :prep_kitchen_reports_path ],
    [ :new_movement, :prep_kitchen_new_movement_path ]
  ].freeze

  FORBIDDEN_PANELS = [
    [ :barista, :barista_dashboard_path ],
    [ :manager, :manager_dashboard_path ],
    [ :platform, :platform_root_path ]
  ].freeze

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @tenant = create_tenant!(name: "PK Kitchen", slug: "pk-k-#{SecureRandom.hex(4)}", type: "production_kitchen")
    FeatureFlag.create!(tenant: @tenant, module: "prep_kitchen", enabled: true)
    @other_tenant = create_tenant!(name: "Other Kitchen", slug: "pk-o-#{SecureRandom.hex(4)}", type: "production_kitchen")
    @manager = create_user!(
      tenant: @tenant,
      role_codes: %w[prep_kitchen_manager],
      email: "pkm-#{SecureRandom.hex(3)}@test.local",
      name: "PK Manager"
    )

    @ingredient = Ingredient.create!(name: "PK-Ing-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    @stock = IngredientTenantStock.create!(tenant: @tenant, ingredient: @ingredient, qty: 10, min_qty: 3)

    category = create_category!
    product = create_product!(category: category, name: "PK Product")
    @pts = enable_product_for_tenant!(tenant: @tenant, product: product, price: 99)
    @pts.update!(is_sold_out: true, sold_out_reason: "manual")

    login_as!(@manager)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "prep_kitchen_manager can access all prep kitchen pages" do
    ALLOWED_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :success, "prep_kitchen_manager должен открывать #{path_helper}"
    end
  end

  test "prep_kitchen_manager is redirected from barista manager and platform" do
    FORBIDDEN_PANELS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :redirect, "prep_kitchen_manager не должен видеть #{path_helper}"
    end
  end

  test "prep_kitchen_manager can update min_qty for own kitchen stock" do
    patch prep_kitchen_inventory_min_qty_path(@stock), params: { min_qty: 7 }

    assert_response :redirect
    assert_equal 7.to_d, @stock.reload.min_qty
  end

  test "prep_kitchen_manager can update stop list for own tenant" do
    patch prep_kitchen_stop_list_item_path(@pts), params: {
      product_tenant_setting: { is_sold_out: "0" }
    }

    assert_response :redirect
    assert_equal false, @pts.reload.is_sold_out
  end

  test "prep_kitchen_manager can create confirm and cancel draft movement" do
    assert_difference -> { StockMovement.where(tenant_id: @tenant.id, status: "draft").count }, +1 do
      post prep_kitchen_movements_path, params: {
        movement: {
          movement_type: "receipt",
          note: "PK RBAC",
          items: [ { ingredient_id: @ingredient.id, qty_change: 4, unit_cost: 50 } ]
        }
      }
    end
    assert_response :redirect

    movement = StockMovement.where(tenant_id: @tenant.id).order(created_at: :desc).first
    assert_equal "draft", movement.status

    post prep_kitchen_confirm_movement_path(movement)
    assert_response :redirect
    assert_equal "confirmed", movement.reload.status
    assert_equal 14.to_d, @stock.reload.qty

    movement2 = StockMovement.create!(
      tenant: @tenant,
      movement_type: "write_off",
      status: "draft",
      created_by: @manager
    )
    StockMovementItem.create!(movement: movement2, ingredient: @ingredient, qty_change: -2)

    post prep_kitchen_cancel_movement_path(movement2)
    assert_response :redirect
    assert_equal "cancelled", movement2.reload.status
  end

  test "prep_kitchen_manager cannot mutate other tenant stock or movements" do
    other_manager = create_user!(
      tenant: @other_tenant,
      role_codes: %w[prep_kitchen_manager],
      email: "pkm-other-#{SecureRandom.hex(3)}@test.local"
    )
    other_ingredient = Ingredient.create!(name: "Other-Ing-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    other_stock = IngredientTenantStock.create!(tenant: @other_tenant, ingredient: other_ingredient, qty: 8, min_qty: 2)
    foreign_movement = StockMovement.create!(
      tenant: @other_tenant,
      movement_type: "receipt",
      status: "draft",
      created_by: other_manager
    )
    StockMovementItem.create!(movement: foreign_movement, ingredient: other_ingredient, qty_change: 3)

    patch prep_kitchen_inventory_min_qty_path(other_stock), params: { min_qty: 99 }
    assert_response :redirect
    assert_equal 2.to_d, other_stock.reload.min_qty

    post prep_kitchen_confirm_movement_path(foreign_movement)
    assert_response :redirect
    assert_equal "draft", foreign_movement.reload.status
  end
end
