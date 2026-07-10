# frozen_string_literal: true

require "test_helper"

# Product card peek cart — Сценарии 4–7 (экстремумы + скролл)
# ТЗ: customer_tasks/отображение набранных позиций и функциональность в режиме pee.md
class Shop::ProductCardS4S7PeekExtremesTest < ActionDispatch::IntegrationTest
  def peek
    @peek ||= File.read(Rails.root.join("app/frontend/components/ProductCartPeek.svelte"))
  end

  def product
    @product ||= File.read(Rails.root.join("app/frontend/routes/Product.svelte"))
  end

  def store
    @store ||= File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))
  end

  # --- S4: горизонтальный скролл ---------------------------------------------

  test "S4 Then: peek row has horizontal overflow scroll" do
    src = peek
    assert_includes src, 'data-testid="shop-product-peek-scroll"',
      "Сценарий 4: контейнер скролла должен иметь data-testid shop-product-peek-scroll"
    assert_match(/overflow-x:\s*auto|overflow-x-auto/, src,
      "Сценарий 4: контейнер должен иметь overflow-x: auto")
  end

  test "S4 Then: touch swipe enabled via touch-action pan-x" do
    src = peek
    assert_match(/touch-action:\s*pan-x|touch-action:\s*manipulation/, src,
      "Сценарий 4: touch-action должен разрешать горизонтальный свайп")
  end

  test "S4 Then: peek lines do not shrink so all items are scrollable" do
    src = peek
    assert_match(/flex:\s*0\s+0\s+auto|shrink-0|flex-shrink:\s*0/, src,
      "Сценарий 4: карточки не сжимаются — все позиции доступны при скролле")
  end

  # --- S5: пустая корзина ----------------------------------------------------

  test "S5 Then: peek list gated on non-empty cart (peek not shown when empty)" do
    src = peek
    assert_match(/\{#if\s+items\.length/, src,
      "Сценарий 5: peek-list не открывается при пустой корзине ({#if items.length})")
    # Явный empty-handler: либо else-ветка, либо отсутствие list без items
    has_empty_handling =
      src.include?('data-testid="shop-product-peek-empty"') ||
      src.match?(/\{#if\s+items\.length\}[\s\S]*\{\/if\}/)
    assert has_empty_handling,
      "Сценарий 5: обработчик пустой корзины (не показывать list / empty testid)"
  end

  # --- S6: ошибка при изменении количества -----------------------------------

  test "S6 Then: peek shows cartSheetError message" do
    src = peek
    assert_includes src, "cartSheetError",
      "Сценарий 6: peek должен читать cartSheetError"
    assert_includes src, 'data-testid="shop-product-peek-error"',
      "Сценарий 6: пользователь видит сообщение об ошибке (testid)"
  end

  test "S6 Then: bump failure sets error and refreshes cart (rollback)" do
    src = store
    assert_includes src, "export async function bumpCartLine"
    assert_match(/enqueueBump|bumpChain/, src)
    # catch-ветка: refreshCartSheet (откат) + cartSheetError.set (сообщение)
    catch_block = src[/\.catch\(async \(err\) => \{[\s\S]*?\n    \}\)/m]
    assert catch_block, "Сценарий 6: ожидается .catch(async (err) => …) в enqueueBump"
    assert_includes catch_block, "refreshCartSheet",
      "Сценарий 6: при ошибке API — refresh (откат optimistic qty)"
    assert_includes catch_block, "cartSheetError.set",
      "Сценарий 6: при ошибке API — сообщение пользователю"
  end

  # --- S7: товар закончился --------------------------------------------------

  test "S7 Then: Product shows out-of-stock indicator when stock <= 0" do
    src = product
    assert_includes src, 'data-testid="shop-product-out-of-stock"',
      "Сценарий 7: на карточке индикатор «нет в наличии»"
    assert_match(/нет в наличии/i, src)
    assert_match(/stock\s*<=\s*0|stock\s*<\s*1/, src)
  end

  test "S7 Then: peek disables qty buttons for out-of-stock product line" do
    src = peek
    assert_match(/outOfStock|unavailable|нет в наличии/i, src,
      "Сценарий 7: в peek есть индикатор/флаг отсутствия")
    assert_match(/disabled=\{[^}]*outOfStock|disabled=\{[^}]*unavailable|lineUnavailable/, src,
      "Сценарий 7: кнопки ± заблокированы для недоступного товара")
  end

  test "S7 Then: Product passes out-of-stock id into ProductCartPeek" do
    src = product
    assert_match(/ProductCartPeek[\s\S]{0,120}stock|outOfStockProductId|unavailableProductId/, src,
      "Сценарий 7: Product передаёт stock/outOfStock в peek")
  end
end
