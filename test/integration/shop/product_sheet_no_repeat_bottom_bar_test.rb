# frozen_string_literal: true

require "test_helper"

# TASK_106: на товаре нет «повторить» и его резерва высоты; нижняя панель — одна кнопка с суммой
# без «Итого» слева; пустая корзина без истории/заказа — шторка по высоте содержимого (без пустого низа).
class Shop::ProductSheetNoRepeatBottomBarTest < ActionDispatch::IntegrationTest
  def sheet
    @sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def thresholds
    @thresholds ||= File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))
  end

  def checkout_bar
    sheet[/\{#snippet checkoutBar[\s\S]*?\{\/snippet\}/] || flunk("checkoutBar snippet not found")
  end

  def height_vh_block
    sheet[/let heightVh = \$derived\.by\(\(\) => \{[\s\S]*?\n  \}\)/] || flunk("heightVh block not found")
  end

  test "Subtask 1: repeat is hidden on product route via showRepeatInSheet" do
    assert_match(/let showRepeatInSheet = \$derived\(showRepeat && !onProduct\)/, sheet)
    assert_match(/\{#if showRepeatInSheet\}\s*<div data-testid="shop-repeat-slot-empty"/, sheet)
    %w[shop-repeat-slot-peek shop-repeat-slot-expanded shop-repeat-slot-single].each do |slot|
      assert_match(
        /data-testid="#{slot}"[^>]*>\s*\{#if showRepeatInSheet\}<RepeatSection/,
        sheet,
        "#{slot} must be gated by showRepeatInSheet"
      )
    end
    refute_match(/\{#if showRepeat\}/, sheet)
  end

  test "Subtask 2: sheet height does not reserve WithRepeat space on product" do
    refute_match(/\bshowRepeat \?/, height_vh_block)
    refute_match(/\bshowRepeat &&/, height_vh_block)
    assert_includes height_vh_block, "showRepeatInSheet"
  end

  test "add-card CTA logic still uses showRepeat (payment flow not changed)" do
    assert_match(/hasRepeatContext: showRepeat,/, sheet)
  end

  test "owner: checkoutBar has no left Итого block, only full-width button" do
    refute_includes checkout_bar, 'data-testid="shop-cart-order-total"'
    refute_includes checkout_bar, ">Итого<"
    assert_match(/data-testid="shop-cart-sheet-checkout"\s+class="[^"]*\bw-full\b/, checkout_bar)
    assert_match(/data-testid="shop-cart-add-card"\s+class="[^"]*\bw-full\b/, checkout_bar)
  end

  test "owner: button sum has no plus sign" do
    assert_match(/function formatCartButtonTotal\(n\) \{\s*return `\$\{formatThousands\(n\)\}₽`/, sheet)
  end

  test "Subtask 3: empty cart without repeat/order fits content height" do
    assert_match(
      /let fitContent = \$derived\(\s*!count && !hasActiveOrderFlag && !showRepeatInSheet && !payStackActive && !phoneAuthSlim/,
      sheet
    )
    assert_match(/fitContent && fitHeightPx > 0\s*\? fitHeightPx/, sheet)
    assert_includes sheet, "new ResizeObserver"
  end

  test "bugbot: fit mode is off while status widget is visible" do
    assert_match(/let fitContent = \$derived\([^)]*!statusWidgetVisible/, sheet)
  end

  test "bugbot: late-mounted sheet children are observed (MutationObserver childList)" do
    assert_includes sheet, "new MutationObserver"
    assert_match(/childList: true/, sheet)
  end

  test "bugbot: fitHeightPx is reset when fit mode turns off" do
    assert_match(/fitHeightPx = 0/, sheet)
  end

  test "gesture zone, safe-area and thresholds values unchanged" do
    assert_includes sheet, 'data-testid="shop-cart-sheet-gesture-zone"'
    assert_includes sheet, 'style:padding-bottom={payStackActive ? null : "var(--shop-safe-bottom, 0px)"}'
    assert_includes thresholds, "peekSingleWithRepeat: 46"
    assert_includes thresholds, "PRODUCT_CTA_EXTRA_VH = 14"
    assert_includes thresholds, "GESTURE_ZONE_SAVED_PX = 56"
  end
end
