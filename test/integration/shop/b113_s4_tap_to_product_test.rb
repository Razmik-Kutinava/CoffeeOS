# frozen_string_literal: true

require "test_helper"

# B1.13-S4 блок 1 — tap на карточку в поп-апе открывает Product.
# Проверяем структуру CartSheet.svelte: функция tapToProduct, onclick на всех трёх видах карточек.
class Shop::B113S4TapToProductTest < ActionDispatch::IntegrationTest
  def sheet
    @sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  # --- tapToProduct ---------------------------------------------------------

  test "tapToProduct function is present" do
    assert_includes sheet, "function tapToProduct(line, e)"
  end

  test "tapToProduct skips button clicks" do
    assert_includes sheet, 'e.target.closest("button")'
  end

  test "tapToProduct navigates to product with cart_line" do
    assert_includes sheet, "/product/${line.product_id}?cart_line=${line.index}"
  end

  # --- peek 2+ карточка ------------------------------------------------------

  test "peek card has tapToProduct onclick" do
    assert_includes sheet, 'data-testid="shop-cart-peek-line"'
    assert_includes sheet, "tapToProduct(line, e)"
  end

  test "peek card has cursor-pointer" do
    assert_includes sheet, "cursor-pointer"
  end

  test "peek card has role button" do
    assert_includes sheet, 'role="button"'
  end

  # --- expanded 2+ строка ----------------------------------------------------

  test "expanded card has tapToProduct onclick" do
    assert_includes sheet, 'data-testid="shop-cart-expanded-card"'
    assert_includes sheet, "tapToProduct(line, e)"
  end

  test "expanded card has cursor-pointer class" do
    # cursor-pointer присутствует в файле как минимум дважды (peek + expanded + single)
    assert_operator sheet.scan("cursor-pointer").length, :>=, 2
  end

  # --- single-item карточка --------------------------------------------------

  test "single card has tapToProduct onclick" do
    assert_includes sheet, 'data-testid="shop-cart-expanded-single"'
    assert_includes sheet, "tapToProduct(singleItem, e)"
  end

  test "single card has cursor-pointer class" do
    assert_operator sheet.scan("cursor-pointer").length, :>=, 3
  end

  # --- кнопки ± НЕ вызывают Product -----------------------------------------

  test "minus buttons call decrementLine" do
    assert_includes sheet, "onclick={() => decrementLine(line)}"
  end

  test "plus buttons call bumpCartLine" do
    assert_includes sheet, "onclick={() => bumpCartLine(line.index, 1)"
  end

  test "delete button calls removeCartLine" do
    assert_includes sheet, "onclick={() => removeCartLine(line.index)"
  end

  # --- режимы поп-апа не изменены -------------------------------------------

  test "gesture zone is unchanged" do
    assert_includes sheet, 'data-testid="shop-cart-sheet-gesture-zone"'
    assert_includes sheet, "handleSheetGestureDelta"
  end

  test "swipe handler imports unchanged" do
    assert_includes sheet, "handleSheetGestureDelta"
    assert_includes sheet, "cartSheetStore"
  end

  test "hidden chip not tappable to peek — no tapToProduct in hidden block" do
    # В скрытом режиме (chip) нет onclick на tapToProduct — ищем по HTML-комментарию
    hidden_block = sheet[/<!-- HIDDEN.*?<!-- PEEK/m] || ""
    refute_includes hidden_block, "tapToProduct"
  end
end
