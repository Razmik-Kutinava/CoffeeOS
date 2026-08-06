# frozen_string_literal: true

require "test_helper"

# Product card peek cart — Шаг 3 / Сценарий 2
# Канон #44: peek на карточке = секция внутри CartSheet (не ProductCartPeek overlay).
class Shop::ProductCardS2PeekListTest < ActionDispatch::IntegrationTest
  def product_svelte
    @product_svelte ||= File.read(Rails.root.join("app/frontend/routes/Product.svelte"))
  end

  def peek_sources
    paths = [
      Rails.root.join("app/frontend/components/CartSheet.svelte"),
      Rails.root.join("app/frontend/lib/productPageCtaStore.js"),
      Rails.root.join("app/frontend/routes/Product.svelte")
    ]
    paths.select { |p| File.exist?(p) }.map { |p| File.read(p) }.join("\n")
  end

  test "S2 Then: Product peek list DOM exists and iterates cart items" do
    src = peek_sources

    assert_match(/shop-product-peek-list/, src,
      "Сценарий 2: на карточке товара должен быть data-testid списка peek")

    assert_includes src, "cartItems",
      "Сценарий 2: peek должен читать cartItems"

    assert_match(
      /shop-product-peek-list[\s\S]{0,800}\{#each|\{#each[\s\S]{0,400}shop-product-peek/,
      src,
      "Сценарий 2: peek-list должен рендерить позиции через {#each} по корзине"
    )
  end

  test "S2 Then: Product wires peek via CartSheet CTA store (not parallel overlay)" do
    product = product_svelte

    has_peek =
      product.include?("productPageCtaStore") ||
      product.include?("publishProductPageCta")

    assert has_peek,
      "Сценарий 2: Product публикует CTA/peek через store → CartSheet"
  end

  test "S2 Then: each peek line shows name, quantity and price" do
    src = peek_sources

    assert_match(/shop-product-peek-line/, src,
      "Сценарий 2: каждая позиция peek должна иметь data-testid строки")

    assert_match(/product_name/, src,
      "Сценарий 2: в peek-строке должно быть название (product_name)")

    assert_match(/quantity/, src,
      "Сценарий 2: в peek-строке должно быть количество (quantity)")

    has_price =
      src.match?(/unit_total|line_total/) ||
      src.match?(/roundPrice|₽/)

    assert has_price,
      "Сценарий 2: в peek-строке должна отображаться цена позиции"
  end

  test "S2 Given: peek is shown only when cart has items" do
    src = peek_sources

    # CartSheet: ветки peek/single только при count > 0; empty отдельно
    gated =
      src.match?(/count\s*>=\s*2|singleItem|!count/) ||
      src.match?(/\{#if[\s\S]{0,80}(items|cartItems|peekItems|count)/)

    assert gated,
      "Сценарий 2: peek должен показываться при непустой корзине (gate по count)"
  end
end
