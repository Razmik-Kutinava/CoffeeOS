# frozen_string_literal: true

require "test_helper"

class Barista::DashboardHelperTest < ActionView::TestCase
  include Barista::DashboardHelper

  test "barista_modifier_tags splits added and removed" do
    item = Struct.new(:modifier_options).new(
      {
        "selected_modifiers" => [{ "name" => "Со льдом" }],
        "removed_modifiers" => [{ "name" => "Сахар" }]
      }
    )

    tags = barista_modifier_tags(item)
    assert_equal 1, tags[:added].size
    assert_equal 1, tags[:removed].size
    assert_equal "Со льдом", tags[:added].first["name"]
    assert_equal "Сахар", tags[:removed].first["name"]
  end

  test "barista_modifier_tags handles empty options" do
    item = Struct.new(:modifier_options).new(nil)
    tags = barista_modifier_tags(item)
    assert_empty tags[:added]
    assert_empty tags[:removed]
  end

  test "barista_status_button_label and next status" do
    assert_equal "ГОТОВИТСЯ", barista_status_button_label("accepted")
    assert_equal "ГОТОВ", barista_status_button_label("preparing")
    assert_equal "Выдать", barista_status_button_label("ready")
    assert_equal "preparing", barista_next_status("accepted")
    assert_equal "ready", barista_next_status("preparing")
    assert_equal "issued", barista_next_status("ready")
  end
end
