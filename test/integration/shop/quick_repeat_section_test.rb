# frozen_string_literal: true

require "test_helper"

# Quick Repeat Bottom Sheet — Шаг F2 (ТЗ Шаги 6–8, скрины 01–05):
# секция «повторить» (RepeatSection.svelte) с 1–3 мини-карточками в шторке
# корзины: видима в empty/peek/expanded, в hidden — существующие чипы корзины.
# Канон высот шторки (bottom_sheet_heights_canon) не меняется.
class Shop::QuickRepeatSectionTest < ActionDispatch::IntegrationTest
  test "RepeatSection component renders label and mini-cards with counter" do
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))

    # Секция и курсивный заголовок «повторить» (скрины 01–03)
    assert_includes section, 'data-testid="shop-repeat-section"'
    assert_includes section, "повторить"
    assert_includes section, "italic"

    # Мини-карточка: фото (или заглушка), название с обрезкой, цена, счётчик −1+
    assert_includes section, 'data-testid="shop-repeat-card"'
    assert_includes section, 'data-testid="shop-repeat-thumb"'
    assert_includes section, "Нет фото"
    assert_includes section, "line-clamp"
    assert_includes section, "₽"
    assert_includes section, 'data-testid="shop-repeat-minus"'
    assert_includes section, 'data-testid="shop-repeat-plus"'
    assert_includes section, 'data-testid="shop-repeat-qty"'

    # Не больше 3 карточек на клиенте (лимит и на бэке MAX_REPEAT_ITEMS)
    assert_includes section, "slice(0, 3)"

    # Данные — из frequentRepeatStore (F1)
    assert_includes section, "frequentItems"
  end

  test "CartSheet mounts repeat section in empty, peek and expanded but not hidden" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, "RepeatSection"
    assert_includes sheet, "initFrequentFromCache"

    # Встройка через снippet/рендер в ветках сценариев (маркер на ветку)
    assert_includes sheet, "shop-repeat-slot-empty"
    assert_includes sheet, "shop-repeat-slot-peek"
    assert_includes sheet, "shop-repeat-slot-expanded"
    refute_includes sheet, "shop-repeat-slot-hidden",
      "в hidden свои чипы корзины — секция «повторить» не рендерится"
  end

  # --- Ревизия 2026-07-31: F2 hide when hasActiveOrder ---

  test "CartSheet gates RepeatSection on hasActiveOrder" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))

    assert_includes sheet, "hasActiveOrder",
      "CartSheet подписывается на hasActiveOrder из frequentRepeatStore"
    # Не монтировать повтор при активном заказе (даже если stale items в сторе)
    assert_match(/!hasActiveOrder|hasActiveOrder\s*===\s*false|!\$?hasActiveOrder/, sheet)
  end

  test "sheet keeps single drag-handle gesture zone" do
    sheet = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))

    assert_equal 1, sheet.scan("shop-cart-sheet-gesture-zone").length
    refute_includes section, "gesture-zone", "drag-handle остаётся один — в CartSheet"
  end

  # Зеркало видимости секции (как mirror-тесты b113)
  test "repeat visibility mirror: modes and item count" do
    assert repeat_visible?(mode: "empty", frequent: 3)
    assert repeat_visible?(mode: "peek", frequent: 1)
    assert repeat_visible?(mode: "expanded", frequent: 2)
    refute repeat_visible?(mode: "hidden", frequent: 3), "hidden — чипы корзины, не секция"
    refute repeat_visible?(mode: "peek", frequent: 0), "нет частых заказов — секции нет"
  end

  test "repeat visibility mirror: has_active_order hides section" do
    refute repeat_visible?(mode: "peek", frequent: 3, has_active_order: true)
    refute repeat_visible?(mode: "empty", frequent: 2, has_active_order: true)
    refute repeat_visible?(mode: "expanded", frequent: 1, has_active_order: true)
    assert repeat_visible?(mode: "peek", frequent: 2, has_active_order: false)
  end

  private

  def repeat_visible?(mode:, frequent:, has_active_order: false)
    return false if has_active_order
    return false if frequent.zero?

    %w[empty peek expanded].include?(mode)
  end
end
