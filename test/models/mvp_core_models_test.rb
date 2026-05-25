# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок B: CRUD и связи MVP-моделей каталога и заказа.
class MvpCoreModelsTest < ActiveSupport::TestCase
  include TestFactories

  # ---------------------------------------------------------------------------
  # Tenant
  # ---------------------------------------------------------------------------

  test "tenant create read update and organization association" do
    org = create_organization!(name: "Сеть MVP")
    tenant = create_tenant!(name: "Точка А", organization: org)

    assert tenant.persisted?
    assert_equal org, tenant.organization
    assert tenant.sales_point?
    assert tenant.active?

    tenant.update!(name: "Точка А (обновлена)")
    tenant.reload
    assert_equal "Точка А (обновлена)", tenant.name
  end

  test "tenant has_many orders" do
    tenant = create_tenant!
    order = Order.create!(
      tenant: tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )

    assert_includes tenant.orders.reload, order
  end

  # ---------------------------------------------------------------------------
  # Category
  # ---------------------------------------------------------------------------

  test "category create read update" do
    category = create_category!(name: "Кофе")
    assert category.persisted?
    assert category.is_active?

    category.update!(name: "Кофе и чай", sort_order: 5)
    category.reload
    assert_equal "Кофе и чай", category.name
    assert_equal 5, category.sort_order
  end

  test "category has_many products" do
    category = create_category!
    product = create_product!(category: category, name: "Латте")

    assert_includes category.products.reload, product
    assert_equal category, product.category
  end

  test "category destroy restricted when products exist" do
    category = create_category!
    create_product!(category: category)

    assert_not category.destroy
    assert Category.exists?(category.id)
  end

  test "category destroy succeeds when empty" do
    category = create_category!
    assert category.destroy
    assert_not Category.exists?(category.id)
  end

  # ---------------------------------------------------------------------------
  # Product
  # ---------------------------------------------------------------------------

  test "product create read update" do
    category = create_category!
    product = create_product!(category: category, name: "Капучино")

    assert product.persisted?
    product.update!(description: "Классический", base_price: 250)
    product.reload
    assert_equal "Классический", product.description
    assert_equal BigDecimal("250"), product.base_price
  end

  test "product has_many modifier groups" do
    product = create_product!(category: create_category!)
    group = ProductModifierGroup.create!(product: product, name: "Размер", sort_order: 1)

    assert_includes product.product_modifier_groups.reload, group
    assert_equal product, group.product
  end

  test "destroy product cascades modifier groups and options" do
    product = create_product!(category: create_category!)
    group = ProductModifierGroup.create!(product: product, name: "Молоко", sort_order: 1)
    option = ProductModifierOption.create!(group: group, name: "Овсяное", price_delta: 30, sort_order: 1)

    product.destroy!

    assert_not ProductModifierGroup.exists?(group.id)
    assert_not ProductModifierOption.exists?(option.id)
  end

  # ---------------------------------------------------------------------------
  # Modifier groups / options
  # ---------------------------------------------------------------------------

  test "modifier group create read update" do
    product = create_product!(category: create_category!)
    group = ProductModifierGroup.create!(product: product, name: "Сироп", is_required: false, sort_order: 2)

    assert group.persisted?
    group.update!(name: "Сиропы", is_required: true)
    group.reload
    assert_equal "Сиропы", group.name
    assert group.is_required
  end

  test "modifier option create read update" do
    product = create_product!(category: create_category!)
    group = ProductModifierGroup.create!(product: product, name: "Размер", sort_order: 1)
    option = ProductModifierOption.create!(group: group, name: "L", price_delta: 50, sort_order: 2)

    assert option.persisted?
    option.update!(name: "XL", price_delta: 70, is_active: false)
    option.reload
    assert_equal "XL", option.name
    assert_equal BigDecimal("70"), option.price_delta
    assert_not option.is_active
  end

  test "destroy modifier group cascades options" do
    product = create_product!(category: create_category!)
    group = ProductModifierGroup.create!(product: product, name: "Размер", sort_order: 1)
    option = ProductModifierOption.create!(group: group, name: "S", price_delta: 0, sort_order: 1)

    group.destroy!

    assert_not ProductModifierOption.exists?(option.id)
  end

  # ---------------------------------------------------------------------------
  # Order / OrderItem
  # ---------------------------------------------------------------------------

  test "order create read update with tenant" do
    tenant = create_tenant!
    order = Order.create!(
      tenant: tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 300,
      discount_amount: 50,
      final_amount: 250
    )

    assert order.persisted?
    assert_equal tenant, order.tenant

    order.update!(status: "preparing")
    order.reload
    assert order.preparing?
  end

  test "order has_many order_items dependent destroy" do
    tenant = create_tenant!
    product = create_product!(category: create_category!)
    order = Order.create!(
      tenant: tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    item = OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 1,
      unit_price: 100,
      total_price: 100
    )

    assert_includes order.order_items.reload, item

    order.destroy!
    assert_not OrderItem.exists?(item.id)
  end

  test "order_item stores modifier_options snapshot" do
    tenant = create_tenant!
    product = create_product!(category: create_category!)
    group = ProductModifierGroup.create!(product: product, name: "Молоко", sort_order: 1)
    option = ProductModifierOption.create!(group: group, name: "Овсяное", price_delta: 30, sort_order: 1)

    order = Order.create!(
      tenant: tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "accepted",
      total_amount: 130,
      discount_amount: 0,
      final_amount: 130
    )

    modifiers = { group.name.parameterize.underscore => option.id }
    item = OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 1,
      unit_price: 130,
      total_price: 130,
      modifier_options: modifiers
    )

    item.reload
    assert_equal option.id, item.modifier_options[group.name.parameterize.underscore]
  end

  test "order_item rejects inconsistent total_price" do
    tenant = create_tenant!
    product = create_product!(category: create_category!)
    order = Order.create!(
      tenant: tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )

    item = OrderItem.new(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 2,
      unit_price: 50,
      total_price: 80
    )

    assert_not item.valid?
    assert_includes item.errors[:total_price], "должна равняться unit_price * quantity"
  end

  test "full chain tenant category product modifiers order order_item" do
    org = create_organization!
    tenant = create_tenant!(organization: org)
    category = create_category!(name: "Напитки")
    product = create_product!(category: category, name: "Раф")
    group = ProductModifierGroup.create!(product: product, name: "Размер", sort_order: 1)
    option = ProductModifierOption.create!(group: group, name: "M", price_delta: 0, sort_order: 1)

    order = Order.create!(
      tenant: tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "manual",
      status: "accepted",
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    item = OrderItem.create!(
      order: order,
      product_id: product.id,
      product_name: product.name,
      quantity: 1,
      unit_price: 200,
      total_price: 200,
      modifier_options: { "size" => option.id }
    )

    assert_equal org, tenant.organization
    assert_equal category, product.category
    assert_equal product, group.product
    assert_equal group, option.group
    assert_equal tenant, order.tenant
    assert_equal order, item.order
    assert_equal product.id, item.product_id
  end
end
