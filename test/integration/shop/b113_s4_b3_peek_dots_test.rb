# frozen_string_literal: true

require "test_helper"

# B1.13-S4 блок 3 — точки-индикаторы под горизонтальным скроллом в peek 4+.
class Shop::B113S4B3PeekDotsTest < ActionDispatch::IntegrationTest
  def sheet
    @sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  test "peekScrollIndex state-переменная присутствует" do
    assert_includes sheet, "peekScrollIndex = $state(0)"
  end

  test "onPeekScroll функция присутствует" do
    assert_includes sheet, "function onPeekScroll(e)"
    assert_includes sheet, "scrollWidth - el.clientWidth"
  end

  test "onPeekScroll вычисляет индекс пропорционально scrollLeft" do
    assert_includes sheet, "el.scrollLeft / maxScroll"
    assert_includes sheet, "count - 1"
  end

  test "контейнер скролла имеет onscroll обработчик" do
    assert_includes sheet, "onscroll={onPeekScroll}"
  end

  test "точки показываются только при count >= 4" do
    assert_includes sheet, "count >= 4"
    assert_includes sheet, 'data-testid="shop-cart-peek-dots"'
  end

  test "точки рендерятся через each по items" do
    assert_match(/shop-cart-peek-dots[\s\S]{0,400}each items/, sheet)
  end

  test "активная точка выделена оранжевым (ff8c42)" do
    assert_includes sheet, "bg-[#ff8c42]"
    assert_includes sheet, "peekScrollIndex"
  end

  test "неактивные точки серые (555)" do
    assert_includes sheet, "bg-[#555]"
  end

  test "точки имеют transition анимацию" do
    assert_includes sheet, "transition-colors"
  end

  test "dots блок не нарушает checkout bar" do
    # checkoutBar с testid shop-cart-peek-total должен остаться
    assert_includes sheet, '"shop-cart-peek-total"'
  end

  test "у S2-регрессии: peek 2+ mode и карточки не тронуты" do
    assert_includes sheet, "MODE_PEEK && count >= 2"
    assert_includes sheet, 'data-testid="shop-cart-peek-line"'
    assert_includes sheet, "tapToProduct(line, e)"
  end

  test "aria-hidden на dots (не мешает accessibility)" do
    assert_includes sheet, 'aria-hidden="true"'
  end
end
