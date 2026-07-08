# frozen_string_literal: true

require "test_helper"

# Displaying the total price — Шаг 1 / Сценарий 1 (картинка в Expanded открывает edit-карточку)
# По проекту сейчас ожидаем красную зону: в CartSheet нет openEditCard и отдельного обработчика клика по img.
class Shop::CartExpandedImageOpenEditCardTest < ActionDispatch::IntegrationTest
  def cart_sheet_svelte
    @cart_sheet_svelte ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def cart_sheet_store_js
    @cart_sheet_store_js ||= File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))
  end

  test "expanded mode: click on product image should call openEditCard with current selected modifiers" do
    sheet = cart_sheet_svelte
    store = cart_sheet_store_js

    # 1) openEditCard как публичная функция/экспорт должен существовать.
    assert_includes store, "export function openEditCard"

    # 2) В Expanded должна быть отдельная кликабельная цель именно для картинки (не для всей строки).
    assert_includes sheet, 'data-testid="shop-cart-expanded-product-image"'

    # 3) Клик по картинке должен вызывать openEditCard с line (с cart_line и выбранными модификаторами).
    assert_includes sheet, "openEditCard(line"
    assert_includes sheet, "cart_line"
    assert_includes sheet, "selected_modifiers"
  end
end

