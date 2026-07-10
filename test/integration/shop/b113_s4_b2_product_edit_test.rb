# frozen_string_literal: true

require "test_helper"

# B1.13-S4 блок 2 — редактирование модификаторов из поп-апа.
# 1. Структурные тесты Product.svelte: edit-mode, PATCH-ветка, кнопка «Сохранить».
# 2. Интеграционные тесты CartController#update с selected_modifiers.
class Shop::B113S4B2ProductEditTest < ActionDispatch::IntegrationTest
  include TestFactories

  # ---------------------------------------------------------------------------
  # Product.svelte — структура (проверка кода компонента)
  # ---------------------------------------------------------------------------

  def svelte
    @svelte ||= File.read(Rails.root.join("app/frontend/routes/Product.svelte"))
  end

  test "Product: parseCartLine функция присутствует" do
    assert_includes svelte, "function parseCartLine()"
    assert_includes svelte, "cart_line"
  end

  test "Product: cartLineIndex state-переменная" do
    assert_includes svelte, "cartLineIndex = $state(null)"
    assert_includes svelte, "editMode = $derived"
  end

  test "Product: initSelectedFromCartLine функция присутствует" do
    assert_includes svelte, "function initSelectedFromCartLine"
    assert_includes svelte, "modifierGroups"
  end

  test "Product: инициализация из кэша после loadProduct" do
    assert_includes svelte, "readCartCache()"
    assert_includes svelte, "initSelectedFromCartLine"
    assert_includes svelte, "line.quantity"
  end

  test "Product: PATCH вызывается в editMode" do
    assert_includes svelte, 'method: "PATCH"'
    assert_includes svelte, "/cart/items/${cartLineIndex}"
    assert_includes svelte, "selected_modifiers, quantity: qty"
  end

  test "Product: PATCH НЕ зовёт shopAddToCart" do
    assert_includes svelte, "if (editMode)"
    assert_includes svelte, "shopAddToCart"
  end

  test "Product: обновляет cartItems и cartTotal stores после PATCH" do
    assert_includes svelte, "cartItems.set(data.items)"
    assert_includes svelte, "cartTotal.set"
  end

  test "Product: кнопка Сохранить в editMode" do
    assert_includes svelte, "Сохранить"
    assert_includes svelte, "editMode"
  end

  test "Product: кнопка добавить к заказу в обычном режиме" do
    assert_includes svelte, "добавить к заказу"
  end

  test "Product: data-testid на кнопке добавления" do
    assert_includes svelte, 'data-testid="shop-product-add-btn"'
  end

  test "Product: writeCartCache вызывается после PATCH" do
    assert_includes svelte, "writeCartCache(data)"
  end

  # ---------------------------------------------------------------------------
  # CartController#update — API тесты
  # ---------------------------------------------------------------------------

  setup do
    @tenant  = create_tenant!
    cat      = create_category!
    @product = create_product!(category: cat)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 150)
    host! "www.example.com"
  end

  def cart_session
    Shop::CartService.new(session, @tenant.id)
  end

  def add_product_to_cart(qty = 1)
    post "/shop/api/cart/add",
      params: { product_id: @product.id, quantity: qty, tenant_id: @tenant.id },
      as: :json
    assert_response :success
  end

  test "PATCH /cart/items/:index с delta работает как раньше (регрессия)" do
    add_product_to_cart(2)

    patch "/shop/api/cart/items/0",
      params: { delta: 1, tenant_id: @tenant.id },
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["items"].is_a?(Array)
    line = body["items"].find { |l| l["index"] == 0 }
    assert_equal 3, line["quantity"]
  end

  test "PATCH /cart/items/:index с selected_modifiers заменяет модификаторы" do
    add_product_to_cart(2)

    patch "/shop/api/cart/items/0",
      params: { selected_modifiers: [], quantity: 3, tenant_id: @tenant.id },
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["items"].is_a?(Array)
    line = body["items"].find { |l| l["index"] == 0 }
    assert_equal 3, line["quantity"]
  end

  test "PATCH /cart/items/:index несуществующий индекс → 422" do
    patch "/shop/api/cart/items/-1",
      params: { selected_modifiers: [], tenant_id: @tenant.id },
      as: :json

    assert_response :unprocessable_entity
  end

  test "PATCH /cart/items/:index с selected_modifiers возвращает items и total" do
    add_product_to_cart(1)

    patch "/shop/api/cart/items/0",
      params: { selected_modifiers: [], tenant_id: @tenant.id },
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("items"), "response must have items"
    assert body.key?("total"), "response must have total"
  end
end
