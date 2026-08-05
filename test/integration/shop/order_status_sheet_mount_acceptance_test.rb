# frozen_string_literal: true

require "test_helper"

# Status inside cart sheet — OrderStatusSheet внутри CartSheet, не overlay в App
class Shop::OrderStatusSheetMountAcceptanceTest < ActionDispatch::IntegrationTest
  test "CartSheet.svelte embeds OrderStatusSheet (not App overlay)" do
    cart = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    app = File.read(Rails.root.join("app/frontend/App.svelte"))

    assert_match(/OrderStatusSheet/, cart, "status must mount inside CartSheet")
    assert_match(
      %r{components/OrderStatusSheet\.svelte|from ["'].*OrderStatusSheet},
      cart
    )
    refute_match(/OrderStatusSheet/, app, "App must not mount status as sibling overlay")
  end

  test "OrderStatusSheet.svelte exists" do
    path = Rails.root.join("app/frontend/components/OrderStatusSheet.svelte")
    assert path.exist?, "missing app/frontend/components/OrderStatusSheet.svelte"
  end

  test "embedded status is not a fixed z-60 overlay sibling of cart" do
    sheet = File.read(Rails.root.join("app/frontend/components/OrderStatusSheet.svelte"))
    accordion = File.read(Rails.root.join("app/frontend/components/ActiveOrdersAccordion.svelte"))

    assert_includes sheet, "embedded"
    assert_match(/class:embedded|embedded\s*=/, sheet)
    # Overlay fixed+z60 только для legacy non-embedded — в embedded запрещён как default path
    assert_match(/\.oss\.embedded|\.oss\.embedded\s*\{/, sheet)
    refute_match(/\.oss\.embedded[\s\S]{0,200}position:\s*fixed/, sheet)
    refute_includes sheet, "right: 7.5rem"
    refute_includes sheet, "max-width: 24.5rem"
    assert_match(/aoa__label|oss__label/, accordion)
    assert_match(/aoa__track|oss__track/, accordion)
  end

  test "status sheet exposes hidden peek expanded modes and one-expanded state" do
    sheet = File.read(Rails.root.join("app/frontend/components/OrderStatusSheet.svelte"))

    assert_includes sheet, 'data-status-sheet-mode={statusSheetMode}'
    assert_match(/statusSheetMode[\s\S]*?HIDDEN/, sheet)
    assert_match(/statusSheetMode[\s\S]*?PEEK/, sheet)
    assert_match(/statusSheetMode[\s\S]*?EXPANDED/, sheet)
    assert_includes sheet, "activeExpandedOrderId"
  end

  test "initial cable connect does not recurse through active refresh" do
    sheet = File.read(Rails.root.join("app/frontend/components/OrderStatusSheet.svelte"))

    assert_includes sheet, "connectionLost"
    assert_match(/else if \(connectionLost\)/, sheet)
  end

  test "scroll hint is gated by shouldScrollStatusList (multi-order >2)" do
    sheet = File.read(Rails.root.join("app/frontend/components/OrderStatusSheet.svelte"))

    assert_includes sheet, "oss__scroll-hint"
    assert_includes sheet, "shouldScrollStatusList(orders)"
    assert_match(/\{#if\s+scrollable\}[\s\S]*oss__scroll-hint/, sheet)
  end
end
