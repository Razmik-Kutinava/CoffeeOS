# frozen_string_literal: true

require "test_helper"

class Barista::OrderCancellationServiceTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Cancel Svc", slug: "cancel-svc-#{SecureRandom.hex(3)}")
    @user = create_user!(tenant: @tenant, role_codes: %w[barista], email: "cancel-svc@test.local")
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @user)
    category = create_category!
    @product = create_product!(category: category, name: "Latte Cancel")
    @ingredient = Ingredient.create!(name: "Milk Cancel", unit: "ml", is_active: true)
    ProductRecipe.create!(product: @product, ingredient: @ingredient, qty_per_serving: 200)
    IngredientTenantStock.create!(tenant: @tenant, ingredient: @ingredient, qty: 1000, min_qty: 0)
    Current.tenant_id = @tenant.id
  end

  teardown { Current.reset }

  def build_order!(status:)
    order = Order.create!(
      tenant: @tenant,
      cash_shift: @shift,
      order_number: "CN-#{SecureRandom.hex(2)}",
      source: "manual",
      status: status,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    OrderItem.create!(
      order: order,
      product_id: @product.id,
      product_name: @product.name,
      quantity: 2,
      unit_price: 50,
      total_price: 100
    )
    order
  end

  def call_service(order, **kwargs)
    Barista::OrderCancellationService.new(
      order: order,
      actor: @user,
      tenant_id: @tenant.id,
      user_id: @user.id,
      **kwargs
    ).call!
  end

  test "raises when reason blank" do
    order = build_order!(status: "accepted")

    assert_raises(Barista::OrderCancellationService::OrderCancellationError) do
      call_service(order, reason: "   ")
    end
    assert_equal "accepted", order.reload.status
  end

  test "cancels accepted order and writes audit log" do
    order = build_order!(status: "accepted")

    assert_difference ["OrderStatusLog.count", "AdminAuditLog.count"], 1 do
      assert_no_difference "StockMovement.count" do
        result = call_service(order, reason: "Клиент ушёл")
        assert_equal "cancelled", result.status
        assert_equal "Клиент ушёл", result.cancel_reason
      end
    end

    log = AdminAuditLog.order(created_at: :desc).first
    assert_equal "order_cancelled", log.action
  end

  test "preparing cancel with unused ingredients restores stock via return movement" do
    order = build_order!(status: "preparing")
    stock_before = IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: @ingredient.id).qty

    assert_difference "StockMovement.count", 1 do
      call_service(order, reason: "Ошибка", ingredients_used: "false")
    end

    movement = StockMovement.order(created_at: :desc).first
    assert_equal "return", movement.movement_type
    assert_equal "confirmed", movement.status
    assert_equal order.id, movement.reference_id
    assert_equal 1, movement.stock_movement_items.count
    assert_equal 400.to_d, movement.stock_movement_items.first.qty_change

    stock_after = IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: @ingredient.id).qty
    assert_equal stock_before + 400, stock_after
  end

  test "preparing cancel without ingredients_used flag skips stock restore" do
    order = build_order!(status: "preparing")

    assert_no_difference "StockMovement.count" do
      call_service(order, reason: "Отмена")
    end
  end
end
