# frozen_string_literal: true

require "test_helper"

# #35 A2 — sticky OrderStatusSheet смонтирован в App, не в CartSheet [TDD RED]
class Shop::OrderStatusSheetMountAcceptanceTest < ActionDispatch::IntegrationTest
  test "#35 App.svelte mounts OrderStatusSheet component" do
    app = File.read(Rails.root.join("app/frontend/App.svelte"))
    assert_match(/OrderStatusSheet/, app, "#35 sticky sheet must mount in App.svelte")
    assert_match(
      %r{components/OrderStatusSheet\.svelte|from ["'].*OrderStatusSheet},
      app
    )
  end

  test "#35 OrderStatusSheet.svelte exists" do
    path = Rails.root.join("app/frontend/components/OrderStatusSheet.svelte")
    assert path.exist?, "#35 missing app/frontend/components/OrderStatusSheet.svelte"
  end

  test "#35/#36 status sheet stays above cart and spans full viewport" do
    sheet = File.read(Rails.root.join("app/frontend/components/OrderStatusSheet.svelte"))
    accordion = File.read(Rails.root.join("app/frontend/components/ActiveOrdersAccordion.svelte"))

    assert_includes sheet, "z-index: 60"
    assert_match(/\.oss\s*\{[\s\S]*?left:\s*0;[\s\S]*?right:\s*0;/, sheet)
    refute_includes sheet, "right: 7.5rem"
    refute_includes sheet, "max-width: 24.5rem"
    refute_includes sheet, "border-right: 3px solid #ff8c42"
    # #36: progress labels/track вынесены в ActiveOrdersAccordion
    assert_match(/aoa__label|oss__label/, accordion)
    assert_match(/aoa__track|oss__track/, accordion)
  end

  test "#35/#36 exposes hidden peek expanded modes and one-expanded state" do
    sheet = File.read(Rails.root.join("app/frontend/components/OrderStatusSheet.svelte"))

    assert_includes sheet, 'data-status-sheet-mode={statusSheetMode}'
    assert_match(/statusSheetMode[\s\S]*?HIDDEN/, sheet)
    assert_match(/statusSheetMode[\s\S]*?PEEK/, sheet)
    assert_match(/statusSheetMode[\s\S]*?EXPANDED/, sheet)
    assert_includes sheet, "activeExpandedOrderId"
  end

  test "#35 initial cable connect does not recurse through active refresh" do
    sheet = File.read(Rails.root.join("app/frontend/components/OrderStatusSheet.svelte"))

    assert_includes sheet, "connectionLost"
    assert_match(/else if \(connectionLost\)/, sheet)
  end

  test "#35 CartSheet does not embed order progress steps (separate sheet)" do
    cart = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    assert_no_match(/orderProgressView|PROGRESS_STEPS/, cart)
  end
end
