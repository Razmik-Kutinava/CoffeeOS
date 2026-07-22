# frozen_string_literal: true

require "test_helper"

# Quick Repeat Bottom Sheet — Шаг B1 (ТЗ Шаг 1):
# агрегация частых товаров клиента за окно WINDOW_DAYS, топ MAX_REPEAT_ITEMS
# по частоте и свежести, группировка по [product_id, modifier_options].
class Shop::CustomerFrequentProductsServiceTest < ActiveSupport::TestCase
  include TestFactories

  SYRUP_CARAMEL = { "syrup" => "caramel" }.freeze
  SYRUP_VANILLA = { "syrup" => "vanilla" }.freeze

  setup do
    @org = create_organization!
    @tenant = create_tenant!(slug: "freq-#{SecureRandom.hex(3)}", organization: @org)
    @tenant_other = create_tenant!(slug: "freq-other-#{SecureRandom.hex(3)}", organization: @org)
    @customer = create_mobile_customer!(email: "freq-#{SecureRandom.hex(4)}@example.com")

    @category = create_category!(name: "Черный")
    @filter = create_product!(category: @category, name: "Фильтр-кофе без кофеина (декаф) Гватемала")
    @filter.update!(image_url: "https://cdn.example.com/filter.png")
    @bumble = create_product!(category: @category, name: "Бамбл")
    @tonic = create_product!(category: @category, name: "Кофе-тоник")
    @matcha = create_product!(category: @category, name: "Матча тоник")

    [ @filter, @bumble, @tonic, @matcha ].each do |product|
      enable_product_for_tenant!(tenant: @tenant, product: product, price: 250)
    end
  end

  test "business limits live in service constants, not hardcode" do
    assert_includes 30..60, Shop::CustomerFrequentProductsService::WINDOW_DAYS
    assert_equal 3, Shop::CustomerFrequentProductsService::MAX_REPEAT_ITEMS
  end

  test "aggregates same drink with same modifiers across orders in window" do
    # ТЗ Given: 5 заказов за 45 дней, 3 из них — один напиток с одинаковыми модификаторами
    3.times do |i|
      create_paid_order!(product: @filter, modifiers: SYRUP_CARAMEL, created_at: (i * 10 + 2).days.ago)
    end
    create_paid_order!(product: @bumble, created_at: 5.days.ago)
    create_paid_order!(product: @tonic, created_at: 40.days.ago)

    items = call_service

    assert items.length.between?(1, 3), "ожидалось 1–3 объекта, получено #{items.length}"

    top = items.first
    assert_equal @filter.id, top[:product_id]
    assert_equal "Фильтр-кофе без кофеина (декаф) Гватемала", top[:name]
    assert_equal 250.0, top[:price]
    assert_equal "https://cdn.example.com/filter.png", top[:image_url]
    assert_equal SYRUP_CARAMEL, top[:modifier_options]
  end

  test "returns empty array without matching orders" do
    assert_equal [], call_service
  end

  test "caps result at MAX_REPEAT_ITEMS sorted by frequency" do
    # 4 разных напитка: бамбл 4 раза, фильтр 3, тоник 2, матча 1 → топ-3 без матчи
    4.times { |i| create_paid_order!(product: @bumble, created_at: (i + 1).days.ago) }
    3.times { |i| create_paid_order!(product: @filter, created_at: (i + 1).days.ago) }
    2.times { |i| create_paid_order!(product: @tonic, created_at: (i + 1).days.ago) }
    create_paid_order!(product: @matcha, created_at: 1.day.ago)

    items = call_service

    assert_equal 3, items.length
    assert_equal [ @bumble.id, @filter.id, @tonic.id ], items.map { |i| i[:product_id] }
    refute_includes items.map { |i| i[:product_id] }, @matcha.id
  end

  test "equal frequency is sorted by recency" do
    2.times { |i| create_paid_order!(product: @tonic, created_at: (20 + i).days.ago) }
    2.times { |i| create_paid_order!(product: @bumble, created_at: (1 + i).days.ago) }

    items = call_service
    assert_equal [ @bumble.id, @tonic.id ], items.map { |i| i[:product_id] }
  end

  test "equivalent modifier_options variants aggregate into one frequent item" do
    create_paid_order!(product: @filter, modifiers: {}, created_at: 3.days.ago)
    create_paid_order!(product: @filter, modifiers: { "selected_modifiers" => [] }, created_at: 2.days.ago)
    create_paid_order!(
      product: @filter,
      modifiers: { "removed_modifiers" => [], "selected_modifiers" => [] },
      created_at: 1.day.ago
    )

    items = call_service

    assert_equal 1, items.length
    assert_equal({ "selected_modifiers" => [] }, items.first[:modifier_options])
  end

  test "same product with different modifiers makes separate entries" do
    2.times { |i| create_paid_order!(product: @filter, modifiers: SYRUP_CARAMEL, created_at: (i + 1).days.ago) }
    create_paid_order!(product: @filter, modifiers: SYRUP_VANILLA, created_at: 1.day.ago)

    items = call_service

    assert_equal 2, items.length
    assert_equal [ SYRUP_CARAMEL, SYRUP_VANILLA ], items.map { |i| i[:modifier_options] }
  end

  test "orders outside window are ignored" do
    window = Shop::CustomerFrequentProductsService::WINDOW_DAYS
    create_paid_order!(product: @filter, created_at: (window + 1).days.ago)
    create_paid_order!(product: @bumble, created_at: (window - 1).days.ago)

    items = call_service
    assert_equal [ @bumble.id ], items.map { |i| i[:product_id] }
  end

  test "only mobile source orders are counted" do
    create_paid_order!(product: @filter, created_at: 1.day.ago, source: :manual)
    assert_equal [], call_service
  end

  test "pending and cancelled orders are not counted" do
    create_paid_order!(product: @filter, created_at: 1.day.ago, status: :pending_payment)
    create_paid_order!(product: @bumble, created_at: 1.day.ago, status: :cancelled)
    assert_equal [], call_service
  end

  test "orders of another tenant are isolated" do
    enable_product_for_tenant!(tenant: @tenant_other, product: @filter, price: 300)
    create_paid_order!(product: @filter, tenant: @tenant_other, created_at: 1.day.ago)

    assert_equal [], call_service
  end

  test "products disabled for tenant are excluded" do
    create_paid_order!(product: @filter, created_at: 1.day.ago)
    ProductTenantSetting.find_by(tenant_id: @tenant.id, product_id: @filter.id).update!(is_enabled: false)

    assert_equal [], call_service
  end

  test "product without image returns nil image_url for placeholder" do
    create_paid_order!(product: @matcha, created_at: 1.day.ago)

    items = call_service
    assert_nil items.first[:image_url]
  end

  private

  def call_service
    Shop::CustomerFrequentProductsService.call(customer_id: @customer.id, tenant_id: @tenant.id)
  end

  def create_paid_order!(product:, tenant: @tenant, modifiers: {}, created_at: Time.current,
                         status: :accepted, source: :mobile, quantity: 1, unit_price: 250)
    order = Order.create!(
      tenant: tenant,
      customer_id: @customer.id,
      order_number: "FREQ-#{SecureRandom.hex(4)}",
      source: source,
      status: status,
      total_amount: unit_price * quantity,
      discount_amount: 0,
      final_amount: unit_price * quantity,
      created_at: created_at
    )
    OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: quantity,
      unit_price: unit_price,
      total_price: unit_price * quantity,
      modifier_options: modifiers
    )
    order
  end
end
