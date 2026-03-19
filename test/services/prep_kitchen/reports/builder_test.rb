require "test_helper"

class PrepKitchen::Reports::BuilderTest < ActiveSupport::TestCase
  include TestFactories

  test "builds basic movement report" do
    tenant = create_tenant!(name: "Kitchen H", slug: "kitchen-h")
    user = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_manager], email: "krep@test.com")
    ingredient = Ingredient.create!(name: "Sugar H", unit: "g", is_active: true)

    receipt = StockMovement.create!(tenant: tenant, movement_type: "receipt", status: "confirmed", created_by: user, confirmed_by: user, confirmed_at: Time.current)
    StockMovementItem.create!(movement: receipt, ingredient: ingredient, qty_change: 12)
    write_off = StockMovement.create!(tenant: tenant, movement_type: "write_off", status: "confirmed", created_by: user, confirmed_by: user, confirmed_at: Time.current)
    StockMovementItem.create!(movement: write_off, ingredient: ingredient, qty_change: -2)

    report = PrepKitchen::Reports::Builder.call(tenant_id: tenant.id, from: 1.day.ago, to: 1.day.from_now, group_by: "movement_type")

    assert_equal 12.to_d, report[:receipt_qty]
    assert_equal(-2.to_d, report[:write_off_qty])
    assert_equal 10.to_d, report[:net_qty]
  end
end
