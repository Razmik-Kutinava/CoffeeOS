# frozen_string_literal: true

require "test_helper"

# Product card peek cart — Шаг 1 / Сценарий 1
# ТЗ: customer_tasks/отображение набранных позиций и функциональность в режиме pee.md
#
# Gherkin:
#   Given: пользователь добавил товар в корзину (1+ шт.)
#   When:  пользователь переходит в карточку этого товара
#   Then:  в карточке отображается индикатор количества («уже в заказе: N»)
#
# Тест-критерии ТЗ:
#   1) В DOM присутствует элемент с количеством товара в корзине
#   2) При изменении количества в корзине индикатор обновляется реактивно
#
# Красная зона (ожидаемо FAIL до реализации): в Product.svelte нет индикатора
# и нет derived из cartItems для текущего product_id.
class Shop::ProductCardS1InOrderIndicatorTest < ActionDispatch::IntegrationTest
  def product_svelte
    @product_svelte ||= File.read(Rails.root.join("app/frontend/routes/Product.svelte"))
  end

  # --- Then: DOM-элемент с количеством в корзине -----------------------------

  test "S1 Then: Product DOM has in-order indicator testid with cart quantity" do
    src = product_svelte

    # Элемент индикатора должен быть в разметке карточки (не в CartSheet).
    assert_includes src, 'data-testid="shop-product-in-order"',
      "Сценарий 1: в Product.svelte должен быть data-testid индикатора «уже в заказе»"

    # Текст/формат из ТЗ и макета.
    assert_match(/уже в заказе/i, src,
      "Сценарий 1: индикатор должен содержать текст «уже в заказе»")
  end

  test "S1 Then: indicator shows quantity derived from cart lines for this product" do
    src = product_svelte

    # Given→When→Then: qty берётся из строк корзины текущего product_id, не хардкод.
    assert_match(/inOrder|in_order|alreadyInOrder|cartQtyForProduct/i, src,
      "Сценарий 1: нужна derived/переменная количества позиций текущего товара из корзины")

    # Количество должно попадать в разметку индикатора (не мёртвый store-import).
    assert_match(
      /shop-product-in-order[\s\S]{0,200}\{[^}]*\}/,
      src,
      "Сценарий 1: testid индикатора должен интерполировать количество в DOM"
    )
  end

  # --- Тест-критерий 2: реактивность при изменении корзины -------------------

  test "S1 Then: indicator reacts to cartItems store changes" do
    src = product_svelte

    # Импорт store уже может быть — но без подписки/derived индикатор не реактивен.
    assert_includes src, "cartItems",
      "Сценарий 1: Product должен читать cartItems для индикатора"

    # Реактивная связь: subscribe / $effect / $derived от cartItems.
    reactive =
      src.include?("cartItems.subscribe") ||
      src.match?(/\$derived[\s\S]{0,120}cartItems/) ||
      src.match?(/\$effect[\s\S]{0,200}cartItems/)

    assert reactive,
      "Сценарий 1: индикатор обязан обновляться реактивно при изменении cartItems " \
      "(subscribe / $derived / $effect) — иначе критерий «обновляется реактивно» не выполнен"
  end

  test "S1 Given/When: indicator is gated on current product_id matching cart line" do
    src = product_svelte

    # Given: в корзине есть товар; When: открыта его карточка —
    # индикатор считает только линии с product_id === params.id / product.id.
    asserts_product_match =
      src.match?(/product_id[\s\S]{0,80}params\.id|params\.id[\s\S]{0,80}product_id/) ||
      src.match?(/product_id[\s\S]{0,80}product\.id|product\.id[\s\S]{0,80}product_id/) ||
      src.match?(/String\(.*product_id.*\).*===.*String\(/)

    assert asserts_product_match,
      "Сценарий 1: qty индикатора должен фильтровать cartItems по product_id текущей карточки"
  end
end
