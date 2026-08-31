require "test_helper"

class PrepKitchen::Incidents::CollectorTest < ActiveSupport::TestCase
  include TestFactories

  test "collects low and out of stock incidents" do
    tenant = create_tenant!(name: "Kitchen G", slug: "kitchen-g")
    ingredient = Ingredient.create!(name: "Beans G", unit: "g", is_active: true)
    IngredientTenantStock.create!(tenant: tenant, ingredient: ingredient, qty: 0, min_qty: 5)

    result = PrepKitchen::Incidents::Collector.call(tenant_id: tenant.id)

    assert_equal 1, result[:out_of_stock].size
    assert_equal 1, result[:low_stock].size
  end

  test "collects linked stock_empty stop list from sales points" do
    org = Organization.create!(name: "Inc Org", slug: "inc-org-#{SecureRandom.hex(4)}")
    kitchen = create_prep_kitchen_tenant!(organization: org)
    point = create_tenant!(name: "Inc Point", slug: "inc-pt-#{SecureRandom.hex(4)}", organization: org)
    user = create_user!(tenant: kitchen, role_codes: %w[prep_kitchen_manager])

    category = create_category!
    product = create_product!(category: category, name: "Inc Product")
    setting = enable_product_for_tenant!(tenant: point, product: product, price: 100)
    setting.update!(is_sold_out: true, sold_out_reason: "stock_empty")

    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: kitchen, sales_point_tenant: point)

    result = PrepKitchen::Incidents::Collector.call(tenant_id: kitchen.id, user_id: user.id)

    assert_equal 1, result[:stock_empty_stop_list].size
    assert_equal setting.id, result[:stock_empty_stop_list].first.id
  end
end
