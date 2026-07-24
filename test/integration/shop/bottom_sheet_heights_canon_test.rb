# frozen_string_literal: true

require "test_helper"

# ТЗ «Bottom Sheet expanded mode…» — закрытие 2026-07-21 (решение владельца):
# текущий UX принят как канон, код не менялся. Тесты фиксируют канон, чтобы
# случайная правка высот/раскладки не прошла незамеченной.
# Канон: expanded — верх у 1-го ряда сетки каталога · peek — до 2-го ряда · hidden — половина.
class Shop::BottomSheetHeightsCanonTest < ActionDispatch::IntegrationTest
  SHEET = Rails.root.join("app/frontend/components/CartSheet.svelte")
  THRESHOLDS = Rails.root.join("app/frontend/lib/cartSheetThresholds.js")
  CATALOG = Rails.root.join("app/frontend/components/CategorySection.svelte")

  test "sheet heights match accepted canon (expanded 1st row, peek 2nd row, hidden half)" do
    thresholds = File.read(THRESHOLDS)

    assert_match(/expandedSingle:\s*52/, thresholds)
    assert_match(/expandedMulti:\s*56/, thresholds)
    assert_match(/peekSingle:\s*34/, thresholds)
    assert_match(/peekMulti:\s*38/, thresholds)
    assert_match(/hidden:\s*24/, thresholds)
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog35"',
      "канон шторки — prog31 (без кнопки Отменить undo); менять только с UX-решением"
  end

  test "sheet internals stay untouched (expanded rows list, no grid inside sheet)" do
    sheet = File.read(SHEET)

    # Expanded — горизонтальные строки вертикальным списком (канон S2)
    assert_includes sheet, 'data-testid="shop-cart-expanded-horizontal"'
    assert_includes sheet, 'data-cart-layout="vertical"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-card"'
    assert_includes sheet, 'data-testid="shop-cart-expanded-delete"'
    # Сетки внутри шторки быть не должно (решение владельца 2026-07-21)
    refute_includes sheet, 'data-cart-layout="grid"'
    refute_includes sheet, 'data-testid="shop-cart-expanded-grid"'
  end

  test "catalog grid keeps accepted card size" do
    catalog = File.read(CATALOG)

    assert_includes catalog, "w-[8.5rem]",
      "карточки каталога — принятый размер 8.5rem (канон −15% от 2026-07-20)"
    assert_includes catalog, "overflow-x-auto"
  end
end
