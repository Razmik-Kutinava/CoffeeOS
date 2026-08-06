# frozen_string_literal: true

require "test_helper"

# Product card peek cart — S0 layout (reopen 2026-08-06)
# Канон: одна рабочая шторка CartSheet на #/product; peek/hidden/expanded —
# секции внутри неё. Запрещены параллельные fixed-слои (bottom-bar + ProductCartPeek).
#
# Красная зона (FAIL до GREEN): Product.svelte держит position:fixed bottom-bar
# и монтирует ProductCartPeek с position:fixed поверх CartSheet.
class Shop::ProductCardS0SingleSheetNoOverlapTest < ActionDispatch::IntegrationTest
  def product_src
    @product_src ||= File.read(Rails.root.join("app/frontend/routes/Product.svelte"))
  end

  def cart_sheet_src
    @cart_sheet_src ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def cta_store_src
    path = Rails.root.join("app/frontend/lib/productPageCtaStore.js")
    assert File.exist?(path), "Нужен productPageCtaStore.js — CTA карточки в шторку"
    File.read(path)
  end

  test "S0 Then: Product does not use fixed bottom-bar with peek offset" do
    src = product_src

    refute_match(/\.bottom-bar\s*\{[^}]*position:\s*fixed/m, src,
      "S0: Product bottom-bar не должен быть position:fixed (накладывается на CartSheet)")
    refute_includes src, "bottom-bar--peek",
      "S0: запрещён bottom-bar--peek (магический bottom:140px поверх шторки)"
  end

  test "S0 Then: Product does not mount parallel fixed ProductCartPeek" do
    src = product_src

    refute_match(/<ProductCartPeek/, src,
      "S0: Product не монтирует отдельный ProductCartPeek — peek внутри CartSheet")
  end

  test "S0 Then: Product publishes CTA into store for CartSheet" do
    src = product_src
    store = cta_store_src

    assert_includes src, "productPageCtaStore",
      "S0: Product публикует CTA через productPageCtaStore"
    assert_match(/publishProductPageCta|productPageCta/, src)
    assert_includes store, "publishProductPageCta"
    assert_includes store, "clearProductPageCta"
  end

  test "S0 Then: CartSheet renders product CTA inside sheet (not overlay)" do
    src = cart_sheet_src

    assert_includes src, "productPageCta",
      "S0: CartSheet читает productPageCta"
    assert_includes src, 'data-testid="shop-product-add-btn"',
      "S0: кнопка «добавить к заказу» внутри шторки"
    # CTA не position:fixed в CartSheet-секции продукта
    refute_match(/shop-product-sheet-cta[\s\S]{0,200}position:\s*fixed/, src)
  end

  test "S0 Then: CartSheet exposes product peek aliases inside modes" do
    src = cart_sheet_src

    assert_includes src, 'data-testid="shop-product-peek-list"',
      "S0: на #/product peek-list alias внутри CartSheet"
    assert_includes src, 'shop-product-peek-scroll',
      "S0: horizontal scroll alias внутри шторки"
    assert_includes src, 'shop-product-peek-minus',
      "S0: ± aliases внутри шторки"
  end

  test "S0 Then: sheet height grows for product CTA (seam, not overlap)" do
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))
    sheet = cart_sheet_src

    assert_match(/PRODUCT_CTA|productCta|PRODUCT_PAGE_CTA/i, thresholds + sheet,
      "S0: высота шторки учитывает CTA (vh), а не второй fixed слой")
  end
end
