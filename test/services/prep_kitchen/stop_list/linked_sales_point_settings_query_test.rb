# frozen_string_literal: true

require "test_helper"

class PrepKitchen::StopList::LinkedSalesPointSettingsQueryTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = Organization.create!(name: "Stop Org", slug: "stop-org-#{SecureRandom.hex(4)}")
    @kitchen = create_prep_kitchen_tenant!(organization: @org)
    @point_a = create_tenant!(name: "Stop Point A", slug: "stop-a-#{SecureRandom.hex(4)}", organization: @org)
    @point_b = create_tenant!(name: "Stop Point B", slug: "stop-b-#{SecureRandom.hex(4)}", organization: @org)
    @manager = create_user!(tenant: @kitchen, role_codes: %w[prep_kitchen_manager])

    category = create_category!
    @product_a = create_product!(category: category, name: "Stop Latte A")
    @product_b = create_product!(category: category, name: "Stop Latte B")

    @setting_a = enable_product_for_tenant!(tenant: @point_a, product: @product_a, price: 210)
    @setting_a.update!(is_sold_out: true, sold_out_reason: "manual")
    @setting_b = enable_product_for_tenant!(tenant: @point_b, product: @product_b, price: 220)
    @setting_b.update!(is_sold_out: true, sold_out_reason: "stock_empty")

    PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: @kitchen, sales_point_tenant: @point_a)
  end

  test "returns sold out settings only from linked sales points" do
    items = PrepKitchen::StopList::LinkedSalesPointSettingsQuery.call(
      prep_kitchen_tenant_id: @kitchen.id,
      user_id: @manager.id
    )

    ids = items.map(&:id)
    assert_includes ids, @setting_a.id
    assert_not_includes ids, @setting_b.id
  end

  test "filters by reason" do
    items = PrepKitchen::StopList::LinkedSalesPointSettingsQuery.call(
      prep_kitchen_tenant_id: @kitchen.id,
      reason: "manual",
      user_id: @manager.id
    )

    assert_equal [ @setting_a.id ], items.map(&:id)
  end
end
