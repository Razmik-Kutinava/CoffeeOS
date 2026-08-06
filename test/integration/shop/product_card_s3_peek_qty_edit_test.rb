# frozen_string_literal: true

require "test_helper"

# Product card peek cart — Сценарий 3
# Канон #44: ±1 внутри CartSheet на #/product (shop-product-peek-*).
class Shop::ProductCardS3PeekQtyEditTest < ActionDispatch::IntegrationTest
  def peek_svelte
    @peek_svelte ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def store_js
    @store_js ||= File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))
  end

  test "S3 Then: peek has minus and plus buttons with testids" do
    src = peek_svelte

    assert_match(/["']shop-product-peek-minus["']/, src,
      "Сценарий 3: кнопка − должна иметь data-testid shop-product-peek-minus")
    assert_match(/["']shop-product-peek-plus["']/, src,
      "Сценарий 3: кнопка + должна иметь data-testid shop-product-peek-plus")
  end

  test "S3 Then: plus calls bumpCartLine with +1" do
    src = peek_svelte

    assert_includes src, "bumpCartLine",
      "Сценарий 3: CartSheet peek должен вызывать bumpCartLine"
    assert_match(/bumpCartLine\([^)]*,\s*1\)/, src,
      "Сценарий 3: +1 должен вызывать bumpCartLine(index, 1)")
  end

  test "S3 Then: minus decreases qty or removes at min" do
    src = peek_svelte

    has_minus =
      src.match?(/bumpCartLine\([^)]*,\s*-1\)/) ||
      (src.include?("removeCartLine") && src.include?("atMinQty"))

    assert has_minus,
      "Сценарий 3: − должен уменьшать qty (bump -1) или удалять строку при qty=1"
  end

  test "S3 Then: qty edit uses cart store (total recalculates via bump/refresh)" do
    peek = peek_svelte
    store = store_js

    assert_includes peek, 'from "../lib/cartSheetStore.js"',
      "Сценарий 3: peek должен брать операции из cartSheetStore"
    assert_includes store, "export async function bumpCartLine",
      "Сценарий 3: bumpCartLine в store пересчитывает total (optimistic + refresh)"
    assert_includes store, "cartTotal.set",
      "Сценарий 3: store обновляет cartTotal после изменения qty"
  end

  test "S3 Then: button clicks do not open product card" do
    src = peek_svelte

    guards_nav =
      src.include?("stopPropagation") ||
      src.include?('closest("button")') ||
      src.match?(/onclick=\{\(e\)\s*=>\s*\{[\s\S]{0,80}e\.stop/)

    assert guards_nav,
      "Сценарий 3: клик по −/+ не должен открывать карточку товара"
  end
end
