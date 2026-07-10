# frozen_string_literal: true

require "test_helper"

# Product card peek cart — Шаг 3 / Сценарий 2
# ТЗ: customer_tasks/отображение набранных позиций и функциональность в режиме pee.md
#
# Gherkin:
#   Given: пользователь добавил несколько позиций в корзину
#   When:  пользователь открывает корзину в режиме peek (на карточке товара)
#   Then:  отображаются все набранные позиции с возможностью просмотра
#
# Тест-критерии ТЗ:
#   1) В режиме peek отображается список всех позиций из корзины
#   2) Каждая позиция содержит название, количество и цену
#
# Красная зона (ожидаемо FAIL до реализации): на Product нет peek-списка
# (CartSheet на каталоге не считается — ТЗ про карточку товара + peek).
class Shop::ProductCardS2PeekListTest < ActionDispatch::IntegrationTest
  def product_svelte
    @product_svelte ||= File.read(Rails.root.join("app/frontend/routes/Product.svelte"))
  end

  def product_peek_sources
    paths = [
      Rails.root.join("app/frontend/routes/Product.svelte"),
      Rails.root.join("app/frontend/components/ProductCartPeek.svelte")
    ]
    paths.select { |p| File.exist?(p) }.map { |p| File.read(p) }.join("\n")
  end

  # --- Тест-критерий 1: список всех позиций из корзины -----------------------

  test "S2 Then: Product peek list DOM exists and iterates cart items" do
    src = product_peek_sources

    assert_includes src, 'data-testid="shop-product-peek-list"',
      "Сценарий 2: на карточке товара должен быть data-testid списка peek"

    # Список строится из cartItems (все позиции), не хардкод.
    assert_includes src, "cartItems",
      "Сценарий 2: peek должен читать cartItems"

    assert_match(
      /shop-product-peek-list[\s\S]{0,400}\{#each|\{#each[\s\S]{0,200}shop-product-peek/,
      src,
      "Сценарий 2: peek-list должен рендерить позиции через {#each} по корзине"
    )
  end

  test "S2 Then: Product mounts peek UI (inline or ProductCartPeek component)" do
    product = product_svelte

    has_peek =
      product.include?('data-testid="shop-product-peek-list"') ||
      product.include?("ProductCartPeek") ||
      product.include?("product-cart-peek")

    assert has_peek,
      "Сценарий 2: Product.svelte должен монтировать peek (разметка или <ProductCartPeek />)"
  end

  # --- Тест-критерий 2: название, количество, цена ---------------------------

  test "S2 Then: each peek line shows name, quantity and price" do
    src = product_peek_sources

    assert_includes src, 'data-testid="shop-product-peek-line"',
      "Сценарий 2: каждая позиция peek должна иметь data-testid строки"

    # Название товара из линии корзины.
    assert_match(/product_name/, src,
      "Сценарий 2: в peek-строке должно быть название (product_name)")

    # Количество.
    assert_match(/quantity/, src,
      "Сценарий 2: в peek-строке должно быть количество (quantity)")

    # Цена (unit_total / line_total / price).
    has_price =
      src.match?(/unit_total|line_total/) ||
      src.match?(/roundPrice|₽/)

    assert has_price,
      "Сценарий 2: в peek-строке должна отображаться цена позиции"
  end

  test "S2 Given: peek is shown only when cart has items" do
    src = product_peek_sources

    # Пустая корзина → peek не показываем (или empty-state отдельно в S5).
    gated =
      src.match?(/cartItems[\s\S]{0,120}\.length|items\.length/) ||
      src.match?(/\{#if[\s\S]{0,80}(items|cartItems|peekItems)/)

    assert gated,
      "Сценарий 2: peek должен показываться при непустой корзине (gate по length / {#if})"
  end
end
