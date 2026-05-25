# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок C: prep_kitchen_worker — просмотр своего цеха; без мутаций и чужих панелей.
class Auth::PrepKitchenWorkerRbacTest < ActionDispatch::IntegrationTest
  READONLY_PATHS = [
    [:dashboard, :prep_kitchen_dashboard_path],
    [:queue, :prep_kitchen_queue_path],
    [:inventory, :prep_kitchen_inventory_path],
    [:movements, :prep_kitchen_movements_path]
  ].freeze

  FORBIDDEN_PANELS = [
    [:barista, :barista_dashboard_path],
    [:manager, :manager_dashboard_path],
    [:platform, :platform_root_path]
  ].freeze

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @tenant = create_tenant!(name: "PK Worker Kitchen", slug: "pkw-k-#{SecureRandom.hex(4)}")
    @other_tenant = create_tenant!(name: "PK Worker Other", slug: "pkw-o-#{SecureRandom.hex(4)}")
    @manager = create_user!(
      tenant: @tenant,
      role_codes: %w[prep_kitchen_manager],
      email: "pkw-mgr-#{SecureRandom.hex(3)}@test.local"
    )
    @worker = create_user!(
      tenant: @tenant,
      role_codes: %w[prep_kitchen_worker],
      email: "pkw-wrk-#{SecureRandom.hex(3)}@test.local",
      name: "PK Worker"
    )

    @ingredient = Ingredient.create!(name: "PKW-Ing-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    @stock = IngredientTenantStock.create!(tenant: @tenant, ingredient: @ingredient, qty: 10, min_qty: 5)

    @other_ingredient = Ingredient.create!(name: "PKW-Other-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    @other_stock = IngredientTenantStock.create!(tenant: @other_tenant, ingredient: @other_ingredient, qty: 99, min_qty: 1)

    category = create_category!
    product = create_product!(category: category, name: "PKW Product")
    @pts = enable_product_for_tenant!(tenant: @tenant, product: product, price: 80)
    @pts.update!(is_sold_out: true, sold_out_reason: "manual")

    @movement = StockMovement.create!(
      tenant: @tenant,
      movement_type: "receipt",
      status: "draft",
      created_by: @manager
    )
    StockMovementItem.create!(movement: @movement, ingredient: @ingredient, qty_change: 3)

    login_as!(@worker)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "prep_kitchen_worker can view dashboard queue inventory and movements list" do
    READONLY_PATHS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :success, "worker должен открывать #{path_helper}"
    end
  end

  test "prep_kitchen_worker inventory shows own tenant stock only" do
    get prep_kitchen_inventory_path
    assert_response :success
    assert_includes response.body, @ingredient.name
    assert_not_includes response.body, @other_ingredient.name
  end

  test "prep_kitchen_worker is redirected from barista manager and platform" do
    FORBIDDEN_PANELS.each do |_name, path_helper|
      get send(path_helper)
      assert_response :redirect, "worker не должен видеть #{path_helper}"
    end
  end

  test "prep_kitchen_worker cannot open movement create form" do
    get prep_kitchen_new_movement_path
    assert_response :redirect
  end

  test "prep_kitchen_worker cannot post patch movements stop list or min qty" do
    patch prep_kitchen_inventory_min_qty_path(@stock), params: { min_qty: 8 }
    assert_response :redirect
    assert_equal 5.to_d, @stock.reload.min_qty

    patch prep_kitchen_stop_list_item_path(@pts), params: {
      product_tenant_setting: { is_sold_out: "0" }
    }
    assert_response :redirect
    assert_equal true, @pts.reload.is_sold_out

    assert_no_difference -> { StockMovement.where(tenant_id: @tenant.id).count } do
      post prep_kitchen_movements_path, params: {
        movement: {
          movement_type: "receipt",
          note: "blocked",
          items: [{ ingredient_id: @ingredient.id, qty_change: 1, unit_cost: 10 }]
        }
      }
    end
    assert_response :redirect

    post prep_kitchen_confirm_movement_path(@movement)
    assert_response :redirect
    assert_equal "draft", @movement.reload.status

    post prep_kitchen_cancel_movement_path(@movement)
    assert_response :redirect
    assert_equal "draft", @movement.reload.status
  end

  test "prep_kitchen_worker cannot mutate other tenant stock" do
    patch prep_kitchen_inventory_min_qty_path(@other_stock), params: { min_qty: 50 }
    assert_response :redirect
    assert_equal 1.to_d, @other_stock.reload.min_qty
  end
end
