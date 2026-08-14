# frozen_string_literal: true

require "test_helper"

class Shop::ModifierGroupsPresenterTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    category = create_category!
    @product = create_product!(category: category, name: "Латте")
    @group = ProductModifierGroup.create!(
      product: @product, name: "Молоко", is_required: false, sort_order: 1
    )
    @oat = ProductModifierOption.create!(
      group: @group, name: "Овсяное", price_delta: 50, sort_order: 2, is_active: true
    )
    @cow = ProductModifierOption.create!(
      group: @group, name: "Коровье", price_delta: 0, sort_order: 1, is_active: true
    )
    ProductModifierOption.create!(
      group: @group, name: "Скрытое", price_delta: 0, sort_order: 3, is_active: false
    )
  end

  test "deduplicated_rows skips inactive options and sorts by sort_order" do
    rows = Shop::ModifierGroupsPresenter.deduplicated_rows(@product.reload)
    names = rows.first.modifiers.map(&:name)
    assert_equal [ "Коровье", "Овсяное" ], names
  end

  test "deduplicated_rows with preload does not SELECT product_modifier_options again" do
    product = Product.includes(product_modifier_groups: :product_modifier_options).find(@product.id)

    option_selects = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      sql = payload[:sql].to_s
      next unless sql.match?(/FROM\s+"product_modifier_options"/i)
      next if sql.match?(/\A\s*(BEGIN|COMMIT|SAVEPOINT|RELEASE)/i)

      option_selects += 1
    end

    rows = Shop::ModifierGroupsPresenter.deduplicated_rows(product)
    ActiveSupport::Notifications.unsubscribe(subscriber)

    assert_equal 0, option_selects, "RUBY-19: preload must be reused, got #{option_selects} option SELECTs"
    assert_equal 2, rows.first.modifiers.size
  end
end
