require "test_helper"

class PrepKitchen::Queue::DemandCalculatorTest < ActiveSupport::TestCase
  include TestFactories

  test "calculates ingredient demand from order items and recipes" do
    tenant = create_tenant!(name: "Kitchen F", slug: "kitchen-f")
    user = create_user!(tenant: tenant, role_codes: %w[barista], email: "bar-q@test.com")
    category = create_category!(name: "Cat Q")
    product = create_product!(category: category, name: "Latte Q")
    ingredient = Ingredient.create!(name: "Milk Q", unit: "ml", is_active: true)
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: 200)
    shift = open_cash_shift!(tenant: tenant, opened_by: user)
    order = Order.create!(
      tenant: tenant,
      cash_shift: shift,
      order_number: "Q-1",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    OrderItem.create!(order: order, product_id: product.id, product_name: product.name, quantity: 2, unit_price: 50, total_price: 100)

    result = PrepKitchen::Queue::DemandCalculator.call(orders: [order])

    row = result[:ingredient_demand].find { |item| item[:ingredient_id] == ingredient.id }
    assert_equal 400.to_d, row[:qty]
  end
end
