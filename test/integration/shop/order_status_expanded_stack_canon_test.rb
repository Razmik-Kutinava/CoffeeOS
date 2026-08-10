# frozen_string_literal: true

require "test_helper"

# #35 D1 — скрин 06 (expanded): статус внутри CartSheet НАД позициями и checkout.
# Канон coffeeos-cart-sheet: одна шторка, секции стык в стык, не overlay.
class Shop::OrderStatusExpandedStackCanonTest < ActionDispatch::IntegrationTest
  def sheet
    @sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def status_sheet
    @status_sheet ||= File.read(Rails.root.join("app/frontend/components/OrderStatusSheet.svelte"))
  end

  def checkout
    @checkout ||= File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
  end

  test "CartSheet declares status-above-lines stack contract for screen 06" do
    assert_includes sheet, 'data-cart-status-stack="status-above-lines"',
      "#35 D1: явный контракт стека для MCP/приёмки vs screenshots/06"
  end

  test "source order: OrderStatusSheet before expanded cart lines and checkout" do
    status_idx = sheet.index("<OrderStatusSheet")
    expanded_idx = sheet.index('data-testid="shop-cart-expanded-horizontal"')
    peek_idx = sheet.index('data-testid="shop-cart-peek-list"')

    assert status_idx, "OrderStatusSheet must be mounted in CartSheet"
    assert expanded_idx, "expanded cart lines must exist"
    assert peek_idx, "peek/payStack cart lines must exist"
    assert_includes sheet, "embedded={true}"
    # Group 3: на pay-stack статус скрыт (нет клипа 15vh поверх «Оплата»)
    assert_match(/\{#if !payStackActive\}/, sheet)
    assert_match(
      /sheetContext=\{mode === MODE_EXPANDED \? "cart_expanded" : "peek"\}/,
      sheet
    )

    assert status_idx < expanded_idx,
      "status section must precede MODE_EXPANDED cart lines (screen 06)"
    assert status_idx < peek_idx,
      "status section must precede peek/payStack cart lines (checkout expanded)"
  end

  test "embedded OrderStatusSheet is relative section not fixed overlay" do
    assert_match(/\.oss\.embedded\s*\{[^}]*position:\s*relative/m, status_sheet)
    refute_match(/\.oss\.embedded\s*\{[^}]*position:\s*fixed/m, status_sheet)
  end

  test "Checkout does not mount a second OrderStatusSheet overlay" do
    refute_includes checkout, "OrderStatusSheet",
      "#35 D1: статус только внутри CartSheet, не второй слой на Checkout"
  end
end
