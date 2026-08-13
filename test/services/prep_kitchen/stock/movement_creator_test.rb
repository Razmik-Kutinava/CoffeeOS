# frozen_string_literal: true

require "test_helper"

class PrepKitchen::Stock::MovementCreatorTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Stock Creator", slug: "stock-creator-#{SecureRandom.hex(3)}")
    @user = create_user!(tenant: @tenant, role_codes: %w[prep_kitchen_manager], email: "pk-creator@test.local")
    @ingredient = Ingredient.create!(name: "Milk Creator", unit: "ml", is_active: true)
    Current.tenant_id = @tenant.id
  end

  teardown { Current.reset }

  test "creates draft receipt movement with items" do
    result = PrepKitchen::Stock::MovementCreator.call(
      tenant_id: @tenant.id,
      user: @user,
      params: {
        movement_type: "receipt",
        note: "Test receipt",
        items: [ { ingredient_id: @ingredient.id, qty_change: 10 } ]
      }
    )

    assert result.success?, result.error
    movement = result.data
    assert_equal "draft", movement.status
    assert_equal "receipt", movement.movement_type
    assert_equal 1, movement.stock_movement_items.size
    assert_equal 10.to_d, movement.stock_movement_items.first.qty_change
  end

  test "accepts items hash from form params" do
    result = PrepKitchen::Stock::MovementCreator.call(
      tenant_id: @tenant.id,
      user: @user,
      params: {
        movement_type: "receipt",
        items: { "0" => { ingredient_id: @ingredient.id, qty_change: 5 } }
      }
    )

    assert result.success?, result.error
    assert_equal 1, result.data.stock_movement_items.size
  end

  test "rejects invalid movement type" do
    result = PrepKitchen::Stock::MovementCreator.call(
      tenant_id: @tenant.id,
      user: @user,
      params: { movement_type: "unknown", items: [ { ingredient_id: @ingredient.id, qty_change: 1 } ] }
    )

    assert_not result.success?
    assert_includes result.error, "тип движения"
  end

  test "rejects empty items" do
    result = PrepKitchen::Stock::MovementCreator.call(
      tenant_id: @tenant.id,
      user: @user,
      params: { movement_type: "receipt", items: [] }
    )

    assert_not result.success?
    assert_includes result.error, "позицию"
  end

  test "rejects duplicate ingredients in one document" do
    result = PrepKitchen::Stock::MovementCreator.call(
      tenant_id: @tenant.id,
      user: @user,
      params: {
        movement_type: "receipt",
        items: [
          { ingredient_id: @ingredient.id, qty_change: 1 },
          { ingredient_id: @ingredient.id, qty_change: 2 }
        ]
      }
    )

    assert_not result.success?
    assert_includes result.error, "повторяться"
  end
end
