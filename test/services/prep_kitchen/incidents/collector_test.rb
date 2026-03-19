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
end
