# frozen_string_literal: true

require "test_helper"

class Payments::TbankCallbackJobTest < ActiveJob::TestCase
  include TestFactories

  setup do
    disable_rls_on_orders_payments!
    @tenant = create_tenant!
    @order = Order.create!(
      tenant: @tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "pending_payment",
      total_amount: 500,
      discount_amount: 0,
      final_amount: 500
    )
    @provider_payment_id = "pay_#{SecureRandom.hex(4)}"
    @payment = Payment.create!(
      order: @order,
      tenant: @tenant,
      amount: 500,
      method: "card",
      provider: "tbank",
      provider_payment_id: @provider_payment_id,
      status: "pending"
    )
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  def build_payload(amount_kopecks: 50_000, status: "CONFIRMED")
    p = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => @order.id.to_s,
      "PaymentId" => @provider_payment_id,
      "Status" => status,
      "Amount" => amount_kopecks
    }
    p["Token"] = Payments::TbankAdapter.new.build_token(p)
    p
  end

  test "CONFIRMED with matching Amount marks payment succeeded" do
    Payments::TbankCallbackJob.perform_now(build_payload)
    assert_equal "succeeded", @payment.reload.status
  end

  test "CONFIRMED with Amount mismatch raises and does not mark payment succeeded" do
    assert_raises(Payments::TbankCallbackJob::AmountMismatchError) do
      Payments::TbankCallbackJob.perform_now(build_payload(amount_kopecks: 100))
    end
    assert_equal "pending", @payment.reload.status
  end

  test "CONFIRMED with insufficient stock still marks payment succeeded and accepts order" do
    category = create_category!
    product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: product, price: 500)
    ingredient = Ingredient.create!(name: "Cb Low #{SecureRandom.hex(2)}", unit: "g", is_active: true)
    ProductRecipe.create!(product: product, ingredient: ingredient, qty_per_serving: 100)
    IngredientTenantStock.create!(tenant: @tenant, ingredient: ingredient, qty: 5, min_qty: 0)
    OrderItem.create!(
      order: @order,
      product_id: product.id,
      product_name: product.name,
      quantity: 1,
      unit_price: 500,
      total_price: 500
    )

    Payments::TbankCallbackJob.perform_now(build_payload)

    assert_equal "succeeded", @payment.reload.status
    assert_equal "accepted", @order.reload.status
    assert_equal 5.to_d, IngredientTenantStock.find_by!(tenant_id: @tenant.id, ingredient_id: ingredient.id).qty
  end

  def disable_rls_on_orders_payments!
    conn = ActiveRecord::Base.connection
    %w[orders payments].each do |table|
      next unless conn.table_exists?(table)

      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} DISABLE ROW LEVEL SECURITY")
    end
  end
end
