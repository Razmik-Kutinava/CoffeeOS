# frozen_string_literal: true

require "test_helper"

class PrepKitchen::Stock::MovementCancellerTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Stock Cancel", slug: "stock-cancel-#{SecureRandom.hex(3)}")
    @user = create_user!(tenant: @tenant, role_codes: %w[prep_kitchen_manager], email: "pk-cancel@test.local")
    @ingredient = Ingredient.create!(name: "Syrup Cancel", unit: "ml", is_active: true)
    Current.tenant_id = @tenant.id
  end

  teardown { Current.reset }

  test "cancels draft movement" do
    movement = StockMovement.create!(
      tenant: @tenant,
      movement_type: :write_off,
      status: :draft,
      created_by: @user
    )
    StockMovementItem.create!(movement: movement, ingredient: @ingredient, qty_change: -1)

    result = PrepKitchen::Stock::MovementCanceller.call(movement: movement)

    assert result.success?, result.error
    assert_equal "cancelled", result.data.status
  end

  test "rejects cancelling confirmed movement" do
    movement = StockMovement.create!(
      tenant: @tenant,
      movement_type: :receipt,
      status: :draft,
      created_by: @user
    )
    StockMovementItem.create!(movement: movement, ingredient: @ingredient, qty_change: 1)
    movement.update!(status: "confirmed", confirmed_by: @user, confirmed_at: Time.current)

    result = PrepKitchen::Stock::MovementCanceller.call(movement: movement)

    assert_not result.success?
    assert_includes result.error, "черновик"
  end
end
