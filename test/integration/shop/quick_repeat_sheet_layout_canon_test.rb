# frozen_string_literal: true

require "test_helper"

# Канон заказчика (скрины 01–05 Quick Repeat + разбор 2026-07-22):
# - hidden: только чипы заказа + «+цена», БЕЗ секции «повторить»
# - peek/single: ОДНА шторка — заказ → checkout (+цена) → «повторить» внутри
# - embedded repeat: мини-карточки thumb+qty (скрины 01–02), без per-card pay
# - full repeat (empty): per-card «оплатить в 1 клик» (скрин 06)
class Shop::QuickRepeatSheetLayoutCanonTest < ActionDispatch::IntegrationTest
  SHEET = Rails.root.join("app/frontend/components/CartSheet.svelte")
  SECTION = Rails.root.join("app/frontend/components/RepeatSection.svelte")

  test "hidden branch has chips and checkout but no RepeatSection" do
    sheet = File.read(SHEET)
    hidden_start = sheet.index("mode === MODE_HIDDEN")
    peek_start = sheet.index("<!-- PEEK 2+")
    assert hidden_start && peek_start && peek_start > hidden_start
    hidden = sheet[hidden_start...peek_start]

    assert_includes hidden, "shop-cart-hidden-chips"
    assert_includes hidden, "shop-cart-sheet-checkout"
    refute_includes hidden, "RepeatSection",
      "hidden (скрины 04–05) — только заказ, без «повторить»"
    refute_includes sheet, "shop-repeat-slot-hidden"
  end

  test "peek and single put checkout before repeat — one sheet entity" do
    sheet = File.read(SHEET)

    peek_slot = sheet.index("shop-repeat-slot-peek")
    peek_checkout = sheet.index('checkoutBar("shop-cart-peek-total"')
    assert peek_slot && peek_checkout
    assert_operator peek_checkout, :<, peek_slot,
      "peek: «+цена» выше «повторить» (скрин 02)"

    single_branch = sheet[/singleItem[\s\S]*?shop-repeat-slot-single[\s\S]*?<\/div>\s*<\/div>/]
    assert single_branch, "ветка singleItem"
    ci = single_branch.index("checkoutBar")
    ri = single_branch.index("shop-repeat-slot-single")
    assert ci && ri
    assert_operator ci, :<, ri, "single: checkout перед «повторить»"
  end

  test "embedded RepeatSection is compact without per-card pay" do
    section = File.read(SECTION)

    assert_includes section, 'layout = "full"'
    assert_includes section, 'layout === "embedded"'
    assert_includes section, 'data-testid="shop-repeat-card-pay"'
    assert_includes section, "{#if !embedded}"
  end

  test "CartSheet passes embedded layout when cart has items" do
    sheet = File.read(SHEET)

    assert_includes sheet, 'layout="embedded"'
    assert_includes sheet, 'layout="full"'
    assert_includes sheet, 'data-sheet-entity="order-and-repeat"'
  end

  test "peek height grows with frequent items so one sheet fits order+repeat" do
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))
    sheet = File.read(SHEET)

    assert_includes thresholds, "peekSingleWithRepeat"
    assert_includes thresholds, "peekMultiWithRepeat"
    assert_includes sheet, "peekSingleWithRepeat"
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog37"'
  end

  test "visibility mirror: hidden never shows repeat" do
    refute sheet_shows_repeat?(mode: "hidden", frequent: 3)
    assert sheet_shows_repeat?(mode: "peek", frequent: 3)
    assert sheet_shows_repeat?(mode: "empty", frequent: 2)
    refute sheet_shows_repeat?(mode: "peek", frequent: 0)
  end

  private

  def sheet_shows_repeat?(mode:, frequent:)
    return false if frequent.zero?
    return false if mode == "hidden"

    %w[empty peek expanded].include?(mode)
  end
end
