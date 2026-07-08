# frozen_string_literal: true

require "test_helper"

# Отображение итоговой стоимости на кнопке корзины PWA
# Сценарии 2.1/2.2 + экстремально: 0₽/undo/error — структурная валидация по исходникам.
class Shop::CartCheckoutButtonTotalDynamicTest < ActionDispatch::IntegrationTest
  def sheet
    @sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def store
    @store ||= File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))
  end

  test "checkout button shows formatted +{total}₽ and does not contain Оформить" do
    assert_includes sheet, 'data-testid="shop-cart-sheet-checkout"'
    refute_includes sheet, ">Оформить</button>"
    assert_includes sheet, "formatCartButtonTotal(total)"
    assert_includes sheet, "disabled={checkoutDisabled}"
  end

  test "empty mode renders disabled checkout with +0₽" do
    assert_includes sheet, "mode === MODE_EMPTY || !count"
    assert_includes sheet, "shop-cart-empty-total"
    assert_includes sheet, "formatCartButtonTotal(total)"
    assert_includes sheet, "disabled={checkoutDisabled}"
  end

  test "cartTotal updates on bump/remove (button label is reactive to total)" do
    assert_includes store, "cartTotal.set(next.reduce"
    assert_includes store, "cartTotal.set(total)"
  end

  test "undo and error UI are wired in CartSheet" do
    assert_includes sheet, 'data-testid="shop-cart-undo"'
    assert_includes sheet, 'data-testid="shop-cart-undo-button"'
    assert_includes sheet, "onclick={() => undoRemoveCartLine()}"

    assert_includes sheet, 'data-testid="shop-cart-error"'
    assert_includes sheet, "role=\"status\""
  end

  test "undo/error stores exist and are set from cart actions" do
    assert_includes store, "export const cartUndoLine"
    assert_includes store, "export const cartSheetError"
    assert_includes store, "export async function undoRemoveCartLine"
    assert_includes store, "cartUndoLine.set"
    assert_includes store, "cartSheetError.set"
  end
end

