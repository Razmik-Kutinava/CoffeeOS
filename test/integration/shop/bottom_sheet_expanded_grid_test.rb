# frozen_string_literal: true

require "test_helper"

# ТЗ «Bottom Sheet expanded mode и внутренняя сетка 4 в ряд» (2026-07-21):
# expanded — сетка товаров 4 в ряд с внутренним вертикальным скроллом.
# Стиль — file-content asserts, как в b113_s2a_cart_sheet_acceptance_test.rb.
class Shop::BottomSheetExpandedGridTest < ActionDispatch::IntegrationTest
  SHEET = Rails.root.join("app/frontend/components/CartSheet.svelte")
  THRESHOLDS = Rails.root.join("app/frontend/lib/cartSheetThresholds.js")

  test "expanded renders 4-per-row grid with internal vertical scroll" do
    sheet = File.read(SHEET)

    assert_includes sheet, 'data-testid="shop-cart-expanded-grid"',
      "expanded-ветка должна иметь grid-контейнер с testid shop-cart-expanded-grid"
    assert_includes sheet, "grid-cols-4",
      "сетка товаров — фиксированно 4 в ряд"
    assert_includes sheet, 'data-cart-layout="grid"',
      "маркер layout expanded — grid (вместо vertical)"
    refute_includes sheet, 'data-cart-layout="vertical"',
      "старый вертикальный список в expanded должен быть заменён сеткой"
  end

  test "expanded grid card follows peek card canon" do
    sheet = File.read(SHEET)

    assert_includes sheet, 'data-testid="shop-cart-grid-card"',
      "карточка сетки — testid shop-cart-grid-card"
    # Канон peek: фото сверху, название 1 строка ellipsis, цена × кол-во, кнопки −/+
    assert_includes sheet, 'data-testid="shop-cart-grid-minus"'
    assert_includes sheet, 'data-testid="shop-cart-grid-plus"'
    refute_includes sheet, 'data-testid="shop-cart-grid-delete"',
      "решение владельца 2026-07-21: «Удалить» в карточках сетки нет («−» при кол-ве 1 удаляет)"
  end

  test "expanded height pinned and build marker bumped" do
    thresholds = File.read(THRESHOLDS)

    # Шаг 1 ТЗ: expanded до первого ряда каталога — текущие 52/56 vh приняты по скрину заказчика
    assert_match(/expandedSingle:\s*52/, thresholds)
    assert_match(/expandedMulti:\s*56/, thresholds)
    # Маркер сборки обязан меняться при каждом UX-фиксе (верификация на Fly)
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog27"',
      "bump CART_SHEET_BUILD до prog27 для этой фичи"
  end
end
