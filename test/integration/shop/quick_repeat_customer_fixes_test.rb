# frozen_string_literal: true

require "test_helper"

# FIX-A…F: жалоба заказчика «зарегался — повторов нет» + расхождение со скринами.
class Shop::QuickRepeatCustomerFixesTest < ActionDispatch::IntegrationTest
  test "CartSheet hides repeat section on checkout route (UX-3)" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, "onCheckout"
    assert_match(/#if !onCheckout}<RepeatSection/, sheet)
  end

  test "CartSheet shows repeat in single-item branch (screenshot 01)" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, "shop-repeat-slot-single"
    assert_includes sheet, "shop-repeat-slot-peek"
    assert_includes sheet, "shop-repeat-slot-expanded"
    assert_includes sheet, "shop-repeat-slot-empty"
  end

  test "expanded sheet has order cards only without catalog grid" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, 'data-testid="shop-cart-expanded-card"'
    assert_includes sheet, "MODE_EXPANDED && count >= 2"
    refute_includes sheet, "FrequentSheetCategories",
      "сетка каталога в expanded убрана (заказчик 2026-07-23)"
    refute_includes sheet, "shop-sheet-frequent-categories"
  end

  test "empty sheet grows when frequent items exist (UX-1 / one-entity peek)" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, "frequentCount"
    assert_includes sheet, "peekSingleWithRepeat"
  end

  test "RepeatSection has per-card pay in full layout only (screenshot 06)" do
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))

    assert_includes section, 'data-testid="shop-repeat-card-pay"'
    assert_includes section, "оплатить в 1 клик"
    assert_includes store, "repeatPayOneClickItem"
    assert_includes section, "!embedded"
    refute_includes section, 'data-testid="shop-repeat-pay-one-click"',
      "глобальная кнопка оплаты заменена на per-card (скрин 06)"
    refute_includes section, 'data-testid="shop-repeat-one-click"'
    refute_includes section, 'data-testid="shop-repeat-more"'
    refute_includes section, "+ещё"
  end

  test "Checkout refreshes frequent products after email verify" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))

    assert_includes checkout, "refreshFrequentProducts"
    assert_match(/emailVerified = true[\s\S]*refreshFrequentProducts/, checkout)
  end
end
