# frozen_string_literal: true

require "test_helper"

class PrepKitchen::Stock::MovementConfirmerTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Stock Confirm", slug: "stock-confirm-#{SecureRandom.hex(3)}")
    @user = create_user!(tenant: @tenant, role_codes: %w[prep_kitchen_manager], email: "pk-confirm@test.local")
    @ingredient = Ingredient.create!(name: "Beans Confirm", unit: "g", is_active: true)
    IngredientTenantStock.create!(tenant: @tenant, ingredient: @ingredient, qty: 5, min_qty: 0)
    Current.tenant_id = @tenant.id
  end

  teardown { Current.reset }

  def draft_receipt_movement(qty_change:)
    movement = StockMovement.create!(
      tenant: @tenant,
      movement_type: :receipt,
      status: :draft,
      created_by: @user
    )
    StockMovementItem.create!(
      movement: movement,
      ingredient: @ingredient,
      qty_change: qty_change
    )
    movement
  end

  test "confirms draft and updates stock qty" do
    movement = draft_receipt_movement(qty_change: 7)

    result = PrepKitchen::Stock::MovementConfirmer.call(movement: movement, user: @user)

    assert result.success?, result.error
    assert_equal "confirmed", result.data.status
    stock = IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: @ingredient.id)
    assert_equal 12.to_d, stock.qty
  end

  test "fails when stock would go negative" do
    movement = draft_receipt_movement(qty_change: -20)

    result = PrepKitchen::Stock::MovementConfirmer.call(movement: movement, user: @user)

    assert_not result.success?
    assert_includes result.error, "отрицательным"
    assert_equal "draft", movement.reload.status
  end

  test "rejects non-draft movement" do
    movement = draft_receipt_movement(qty_change: 1)
    movement.update!(status: "confirmed", confirmed_by: @user, confirmed_at: Time.current)

    result = PrepKitchen::Stock::MovementConfirmer.call(movement: movement, user: @user)

    assert_not result.success?
    assert_includes result.error, "черновик"
  end
end
