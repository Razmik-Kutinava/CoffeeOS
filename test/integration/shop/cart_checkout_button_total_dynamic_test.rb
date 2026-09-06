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

  # Правка 5: явная общая сумма («Итого»), не только +N₽ на кнопке
  test "checkoutBar shows visible order total Итого next to checkout button" do
    assert_includes sheet, 'data-testid="shop-cart-order-total"'
    assert_includes sheet, ">Итого<"
    assert_match(
      /data-testid="shop-cart-order-total"[\s\S]*?\{formatThousands\(roundPrice\(total\)\)\}₽/,
      sheet
    )
    # Кнопка +N₽ остаётся; старый серый span без подписи «Итого» не возвращаем
    refute_match(
      /checkoutBar[\s\S]*?<span class="text-sm text-\[#a0a0a0\]"[^>]*>\{roundPrice\(total\)\}₽<\/span>/,
      sheet
    )
  end

  test "hidden mode order total is visible not sr-only" do
    assert_includes sheet, 'data-testid="shop-cart-hidden-total"'
    refute_match(
      /data-testid="shop-cart-hidden-total"[^>]*class="[^"]*sr-only/,
      sheet
    )
    assert_match(
      /data-testid="shop-cart-hidden-total"[^>]*>\{roundPrice\(total\)\}₽/,
      sheet
    )
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

  test "undo cancel button removed from CartSheet; error UI remains" do
    refute_includes sheet, 'data-testid="shop-cart-undo"'
    refute_includes sheet, 'data-testid="shop-cart-undo-button"'
    refute_includes sheet, "Удаление можно отменить"
    refute_includes sheet, "undoRemoveCartLine"

    assert_includes sheet, 'data-testid="shop-cart-error"'
    assert_includes sheet, "role=\"status\""
  end

  test "error store remains; undo store may exist without sheet UI" do
    assert_includes store, "export const cartSheetError"
    assert_includes store, "cartSheetError.set"
  end

  test "checkout button auto font shrinking helper is present" do
    assert_includes sheet, "function checkoutButtonFontSizePx"
    assert_includes sheet, "checkoutButtonFontSizePx(total)"
  end

  test "unavailable cart error clears cached cart and shows normalized message" do
    assert_includes store, "function isUnavailableCartError"
    assert_includes store, "isUnavailableCartError"
    assert_includes store, "Товар недоступен. Корзина обновлена."
  end
end
