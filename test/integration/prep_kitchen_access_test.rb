require "test_helper"

class PrepKitchenAccessTest < ActionDispatch::IntegrationTest
  test "kitchen manager can open prep kitchen pages" do
    tenant = create_tenant!(name: "Kitchen A", slug: "kitchen-a")
    manager = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_manager], email: "kman@test.com", name: "KMan")

    login_as!(manager)

    [
      "/prep_kitchen",
      "/prep_kitchen/queue",
      "/prep_kitchen/recipes",
      "/prep_kitchen/inventory",
      "/prep_kitchen/movements",
      "/prep_kitchen/stop_list",
      "/prep_kitchen/incidents",
      "/prep_kitchen/reports"
    ].each do |path|
      get path
      assert_response :success, "expected success for #{path}"
    end
  end

  test "kitchen worker can open prep kitchen pages" do
    tenant = create_tenant!(name: "Kitchen B", slug: "kitchen-b")
    worker = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_worker], email: "kworker@test.com", name: "KWorker")

    login_as!(worker)

    get "/prep_kitchen"
    assert_response :success
    get "/prep_kitchen/inventory"
    assert_response :success
  end

  test "non kitchen user gets denied" do
    tenant = create_tenant!(name: "Kitchen C", slug: "kitchen-c")
    office = create_user!(tenant: tenant, role_codes: %w[office_manager], email: "office-k@test.com", name: "Office")

    login_as!(office)
    get "/prep_kitchen"
    assert_response :redirect
  end

  test "worker cannot PATCH inventory min_qty" do
    tenant = create_tenant!(name: "Kitchen RBAC", slug: "kitchen-rbac-#{SecureRandom.hex(4)}")
    manager = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_manager], email: "mgr-rbac@test.com", name: "Manager")
    worker = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_worker], email: "wrk-rbac@test.com", name: "Worker")

    ingredient = Ingredient.create!(name: "ing-rbac-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    stock = IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 10, min_qty: 5)

    login_as!(worker)
    patch prep_kitchen_inventory_min_qty_path(stock), params: { min_qty: 8 }

    assert_response :redirect
    assert_equal 5.to_d, stock.reload.min_qty, "Worker must not change min_qty"
  end

  test "worker cannot PATCH stop_list" do
    tenant = create_tenant!(name: "Kitchen Stop RBAC", slug: "kitchen-stop-#{SecureRandom.hex(4)}")
    worker = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_worker], email: "wrk-stop@test.com", name: "Worker")

    category = create_category!
    product = create_product!(category: category, name: "Product Stop")
    setting = enable_product_for_tenant!(tenant: tenant, product: product, price: 99, is_sold_out: false)
    setting.update!(is_sold_out: true, sold_out_reason: "manual")

    login_as!(worker)
    patch prep_kitchen_stop_list_item_path(setting), params: {
      product_tenant_setting: { is_sold_out: "0" }
    }

    assert_response :redirect
    assert_equal true, setting.reload.is_sold_out, "Worker must not change stop_list"
  end

  test "manager can PATCH inventory min_qty" do
    tenant = create_tenant!(name: "Kitchen Mgr Inv", slug: "kitchen-mgr-inv-#{SecureRandom.hex(4)}")
    manager = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_manager], email: "mgr-inv@test.com", name: "Manager")

    ingredient = Ingredient.create!(name: "ing-mgr-#{SecureRandom.hex(3)}", unit: "g", is_active: true)
    stock = IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 20, min_qty: 5)

    login_as!(manager)
    patch prep_kitchen_inventory_min_qty_path(stock), params: { min_qty: 10 }

    assert_response :redirect
    assert_equal 10.to_d, stock.reload.min_qty, "Manager should update min_qty"
  end
end
