# frozen_string_literal: true

require "test_helper"

class Shop::ModifierSelectionTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    category = create_category!
    @product = create_product!(category: category, name: "Капучино")
    @group = ProductModifierGroup.create!(
      product: @product,
      name: "Крепость",
      is_required: true,
      sort_order: 1
    )
    @opt_regular = ProductModifierOption.create!(
      group: @group,
      name: "Обычный",
      price_delta: 0,
      sort_order: 1
    )
    @opt_strong = ProductModifierOption.create!(
      group: @group,
      name: "По крепче",
      price_delta: 10,
      sort_order: 2
    )
  end

  test "build returns unselected modifiers as removed" do
    selected = [ { id: @opt_strong.id, name: "По крепче", price: 10 } ]
    result = Shop::ModifierSelection.build(product: @product, selected_modifiers: selected)

    assert_equal 1, result[:selected_modifiers].size
    assert_equal @opt_strong.id.to_s, result[:selected_modifiers].first["id"].to_s
    assert_equal 1, result[:removed_modifiers].size
    assert_equal "Обычный", result[:removed_modifiers].first["name"]
  end
end
