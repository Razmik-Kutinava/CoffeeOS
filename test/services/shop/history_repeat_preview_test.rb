# frozen_string_literal: true

require "test_helper"

# TASK_121 Subtask 1, 5, 7, 10: текущие цены позиций заказа из истории в текущей точке
# без изменения корзины / сессии гостя и без побочных эффектов акции.
class Shop::HistoryRepeatPreviewTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @category = create_category!
    @latte = create_product!(category: @category, name: "Латте")
    @latte_setting = enable_product_for_tenant!(tenant: @tenant, product: @latte, price: 200)
    @croissant = create_product!(category: @category, name: "Круассан")
    @croissant_setting = enable_product_for_tenant!(tenant: @tenant, product: @croissant, price: 150)
    @customer = create_mobile_customer!(email: "repeat-preview-#{SecureRandom.hex(3)}@example.com")
  end

  def create_history_order!(lines:, discount: 0, final: nil)
    subtotal = lines.sum { |l| l[:unit] * l[:qty] }
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "T121-#{SecureRandom.hex(3)}",
      source: :mobile,
      status: :issued,
      total_amount: subtotal,
      discount_amount: discount,
      final_amount: final || (subtotal - discount)
    )
    lines.each do |l|
      OrderItem.create!(
        order: order,
        product_id: l[:product].id,
        product_name: l[:product].name,
        quantity: l[:qty],
        unit_price: l[:unit],
        total_price: l[:unit] * l[:qty],
        modifier_options: { "selected_modifiers" => l[:mods] || [], "removed_modifiers" => [] }
      )
    end
    order.reload
  end

  def preview(order)
    Shop::HistoryRepeatPreview.new(order: order, tenant_id: @tenant.id).call
  end

  def item_for(result, product)
    result[:items].find { |i| i[:product_id] == product.id }
  end

  test "prices unchanged → current unit_total equals previous price, totals equal" do
    order = create_history_order!(lines: [
      { product: @latte, qty: 2, unit: 200 },
      { product: @croissant, qty: 1, unit: 150 }
    ])
    result = preview(order)

    assert_equal order.id, result[:order_id]
    assert_equal 2, result[:items].size
    latte = item_for(result, @latte)
    assert_equal 200.0, latte[:price]
    assert_equal 200.0, latte[:unit_total]
    assert_equal 400.0, latte[:line_total]
    assert_equal 2, latte[:quantity]
    assert_equal false, latte[:unavailable]
    assert_equal 550.0, result[:total]
    assert_equal 550.0, result[:previous_total]
    assert_equal 0.0, result[:previous_discount]
  end

  test "price raised in this point → new unit_total and total" do
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 200 } ])
    @latte_setting.update!(price: 260)
    result = preview(order)

    assert_equal 200.0, item_for(result, @latte)[:price]
    assert_equal 260.0, item_for(result, @latte)[:unit_total]
    assert_equal 260.0, result[:total]
    assert_equal 200.0, result[:previous_total]
  end

  test "price lowered in this point → new unit_total and total" do
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 200 } ])
    @latte_setting.update!(price: 180)
    result = preview(order)

    assert_equal 180.0, item_for(result, @latte)[:unit_total]
    assert_equal 180.0, result[:total]
  end

  test "sold out product → unavailable, other lines still priced" do
    order = create_history_order!(lines: [
      { product: @latte, qty: 1, unit: 200 },
      { product: @croissant, qty: 1, unit: 150 }
    ])
    @croissant_setting.update_columns(is_sold_out: true, sold_out_reason: "manual")
    result = preview(order)

    croissant = item_for(result, @croissant)
    assert_equal true, croissant[:unavailable]
    assert_nil croissant[:unit_total]
    assert_equal false, item_for(result, @latte)[:unavailable]
    assert_equal 200.0, result[:total]
  end

  test "disabled product setting → unavailable" do
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 200 } ])
    @latte_setting.update_columns(is_enabled: false)
    assert_equal true, item_for(preview(order), @latte)[:unavailable]
  end

  test "product not sold in this point (no setting) → unavailable" do
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 200 } ])
    @latte_setting.destroy!
    assert_equal true, item_for(preview(order), @latte)[:unavailable]
  end

  test "inactive product → unavailable" do
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 200 } ])
    @latte.update_columns(is_active: false)
    assert_equal true, item_for(preview(order), @latte)[:unavailable]
  end

  test "modifier price included in unit_total; changed option price → new unit_total" do
    group = ProductModifierGroup.create!(product: @latte, name: "Сироп", is_required: false, sort_order: 1)
    syrup = ProductModifierOption.create!(group: group, name: "Ваниль", price_delta: 30, sort_order: 1)
    mods = [ { "id" => syrup.id, "name" => "Ваниль", "price" => 30.0 } ]
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 230, mods: mods } ])

    assert_equal 230.0, item_for(preview(order), @latte)[:unit_total]

    syrup.update!(price_delta: 50)
    assert_equal 250.0, item_for(preview(order), @latte)[:unit_total]
  end

  test "inactive modifier option → line unavailable" do
    group = ProductModifierGroup.create!(product: @latte, name: "Сироп", is_required: false, sort_order: 1)
    syrup = ProductModifierOption.create!(group: group, name: "Ваниль", price_delta: 30, sort_order: 1)
    mods = [ { "id" => syrup.id, "name" => "Ваниль", "price" => 30.0 } ]
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 230, mods: mods } ])
    syrup.update_columns(is_active: false)

    assert_equal true, item_for(preview(order), @latte)[:unavailable]
  end

  test "deleted modifier option → line unavailable" do
    group = ProductModifierGroup.create!(product: @latte, name: "Сироп", is_required: false, sort_order: 1)
    syrup = ProductModifierOption.create!(group: group, name: "Ваниль", price_delta: 30, sort_order: 1)
    mods = [ { "id" => syrup.id, "name" => "Ваниль", "price" => 30.0 } ]
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 230, mods: mods } ])
    syrup.destroy!

    assert_equal true, item_for(preview(order), @latte)[:unavailable]
  end

  test "identical lines are priced separately, not merged" do
    order = create_history_order!(lines: [
      { product: @latte, qty: 1, unit: 200 },
      { product: @latte, qty: 2, unit: 200 }
    ])
    result = preview(order)

    assert_equal [ 1, 2 ], result[:items].map { |i| i[:quantity] }.sort
    assert_equal 600.0, result[:total]
  end

  test "promo order → previous_total is paid amount, previous_discount exposed" do
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 200 } ], discount: 189, final: 11)
    result = preview(order)

    assert_equal 11.0, result[:previous_total]
    assert_equal 189.0, result[:previous_discount]
    assert_equal 200.0, result[:total]
  end

  test "no GrowthPromo pricing or promo counter side effects" do
    order = create_history_order!(lines: [ { product: @latte, qty: 1, unit: 200 } ])
    calls = []
    originals = %i[price! available? eligible?].to_h { |m| [ m, Payments::GrowthPromo.method(m) ] }
    originals.each_key do |m|
      Payments::GrowthPromo.define_singleton_method(m) { |*_args, **_kw| calls << m }
    end

    preview(order)

    assert_empty calls, "GrowthPromo must not be called from repeat preview"
  ensure
    originals&.each { |m, original| Payments::GrowthPromo.define_singleton_method(m, original) }
  end
end
