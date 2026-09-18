# frozen_string_literal: true

require "test_helper"

class Callbacks::PaymentStatusUpdaterTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @order = Order.create!(
      tenant: @tenant,
      order_number: "PAY-1",
      source: "mobile",
      status: "pending_payment",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    @payment = Payment.create!(
      order: @order,
      tenant: @tenant,
      amount: 200,
      method: "card",
      provider: "shop",
      status: "pending"
    )
  end

  test "succeeded payment accepts order" do
    payment = Callbacks::PaymentStatusUpdater.new(
      payment: @payment,
      new_status: "succeeded",
      provider_data: { "ok" => true },
      provider_payment_id: "ext-1"
    ).call!

    assert_equal "succeeded", payment.status
    assert_equal "accepted", @order.reload.status
    assert PaymentStatusLog.exists?(payment: @payment, status_to: "succeeded")
    assert OrderStatusLog.exists?(order: @order, status_to: "accepted", source: "payment_callback")
  end

  test "rejects invalid status" do
    assert_raises(Callbacks::PaymentStatusUpdater::InvalidStatusError) do
      Callbacks::PaymentStatusUpdater.new(payment: @payment, new_status: "bogus").call!
    end
  end

  test "failed payment cancels pending order and journals" do
    assert_difference [ "AdminAuditLog.count", "OrderStatusLog.count" ], 1 do
      Callbacks::PaymentStatusUpdater.new(
        payment: @payment,
        new_status: "failed",
        provider_data: { "Status" => "REJECTED" },
        note: "Т-Банк: REJECTED"
      ).call!
    end

    assert_equal "failed", @payment.reload.status
    assert_equal "cancelled", @order.reload.status
    log = AdminAuditLog.order(created_at: :desc).first
    assert_equal Shop::PaymentFailureJournal::ACTION, log.action
    assert_equal "bank_rejected", log.details["reason"]
  end

  test "#78 subscription_intent closes order and creates subscription (no barista accepted)" do
    customer = create_mobile_customer!(email: "sub-cb-#{SecureRandom.hex(3)}@example.com")
    @order.update!(customer_id: customer.id)
    plan = SubscriptionPlan.create!(
      code: "pilot_cb_#{SecureRandom.hex(3)}",
      price: 499,
      currency: "RUB",
      period_days: 7,
      drink_limit: 5,
      discount_price_per_drink: 119,
      over_limit_discount_percent: 20,
      active: true
    )
    pm = MobilePaymentMethod.create!(
      customer_id: customer.id,
      payment_type: "card",
      card_token: "rebill-cb",
      card_masked: "*1111",
      is_active: true,
      is_default: true
    )
    @payment.update!(
      provider_data: {
        "subscription_intent" => true,
        "subscription_plan_id" => plan.id,
        "subscription_payment_method_id" => pm.id,
        "auto_renew" => true,
        "save_card" => false
      }
    )

    Callbacks::PaymentStatusUpdater.new(
      payment: @payment,
      new_status: "succeeded",
      provider_data: { "Status" => "CONFIRMED" },
      provider_payment_id: "pid-sub-cb"
    ).call!

    assert_equal "succeeded", @payment.reload.status
    assert_equal "closed", @order.reload.status
    refute OrderStatusLog.exists?(order: @order, status_to: "accepted")

    sub = Subscription.find_by!(payment_id: @payment.id)
    assert_equal "active", sub.status
    assert_equal plan.id, sub.plan_id
    assert_equal 0, sub.drinks_used_this_period
  end

  # --- TASK_93-A: money ↔ order / stock soft-fail ---

  def attach_recipe_item!(qty_needed: 25, stock_qty: nil)
    category = create_category!
    product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: product, price: 200)
    ingredient = Ingredient.create!(name: "Upd Ing #{SecureRandom.hex(2)}", unit: "g", is_active: true)
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: qty_needed)
    if stock_qty
      IngredientTenantStock.create!(tenant: @tenant, ingredient: ingredient, qty: stock_qty, min_qty: 0)
    end
    OrderItem.create!(
      order: @order,
      product_id: product.id,
      product_name: product.name,
      quantity: 1,
      unit_price: 200,
      total_price: 200
    )
    ingredient
  end

  # T-A1a
  test "succeeded accepts order even when recipe deduction would fail (insufficient stock)" do
    ingredient = attach_recipe_item!(qty_needed: 25, stock_qty: 5)

    assert_nothing_raised do
      Callbacks::PaymentStatusUpdater.new(payment: @payment, new_status: "succeeded").call!
    end

    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted", @order.reload.status
    stock = IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: ingredient.id)
    assert_equal 5.to_d, stock.qty
    assert AdminAuditLog.exists?(action: "inventory_deduction_skipped", tenant_id: @tenant.id)
  end

  # T-A1b
  test "succeeded accepts order when stock row missing (no find_or_create trap)" do
    ingredient = attach_recipe_item!(qty_needed: 25, stock_qty: nil)

    Callbacks::PaymentStatusUpdater.new(payment: @payment, new_status: "succeeded").call!

    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted", @order.reload.status
    refute IngredientTenantStock.exists?(tenant_id: @tenant.id, ingredient_id: ingredient.id)
    assert AdminAuditLog.exists?(action: "inventory_deduction_skipped", tenant_id: @tenant.id)
  end

  # T-A5a / T-A5b / T-A5c (service-level CONFIRMED scenarios)
  test "CONFIRMED path with missing stock succeeds and accepts" do
    attach_recipe_item!(stock_qty: nil)
    Callbacks::PaymentStatusUpdater.new(payment: @payment, new_status: "succeeded").call!
    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted", @order.reload.status
  end

  test "CONFIRMED path with insufficient stock succeeds and leaves stock unchanged" do
    ingredient = attach_recipe_item!(qty_needed: 40, stock_qty: 10)
    Callbacks::PaymentStatusUpdater.new(payment: @payment, new_status: "succeeded").call!
    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted", @order.reload.status
    assert_equal 10.to_d, IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: ingredient.id).qty
  end

  test "CONFIRMED path with enough stock succeeds and deducts" do
    ingredient = attach_recipe_item!(qty_needed: 25, stock_qty: 40)
    Callbacks::PaymentStatusUpdater.new(payment: @payment, new_status: "succeeded").call!
    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted", @order.reload.status
    assert_equal 15.to_d, IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: ingredient.id).qty
  end

  # T-A6a
  test "succeeded on cancelled order does not quiet-return without audit" do
    @order.update!(status: "cancelled")

    assert_difference -> { AdminAuditLog.where(action: "payment_on_non_pending_order").count }, 1 do
      Callbacks::PaymentStatusUpdater.new(payment: @payment, new_status: "succeeded").call!
    end

    assert_equal "succeeded", @payment.reload.status
    assert_equal "cancelled", @order.reload.status
    log = AdminAuditLog.where(action: "payment_on_non_pending_order").order(created_at: :desc).first
    assert_equal "needs_manual_refund", log.details["reason"]
  end

  # T-A6b
  test "succeeded on closed order does not quiet-return without audit" do
    @order.update!(status: "closed")

    assert_difference -> { AdminAuditLog.where(action: "payment_on_non_pending_order").count }, 1 do
      Callbacks::PaymentStatusUpdater.new(payment: @payment, new_status: "succeeded").call!
    end

    assert_equal "succeeded", @payment.reload.status
    assert_equal "closed", @order.reload.status
  end
end
