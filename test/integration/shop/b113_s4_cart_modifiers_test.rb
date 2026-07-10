# frozen_string_literal: true

require "test_helper"

# B1.13-S4 блок 4 — итоговая приёмка S4.
# Охватывает: S4-b1 (tap), S4-b2 (edit modifiers + API PATCH), S4-b3 (dots), пересчёт цены.
class Shop::B113S4CartModifiersTest < ActionDispatch::IntegrationTest
  include TestFactories

  # ===========================================================================
  # Вспомогательные методы для структурных тестов
  # ===========================================================================

  def sheet
    @sheet ||= File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
  end

  def product_svelte
    @product_svelte ||= File.read(Rails.root.join("app/frontend/routes/Product.svelte"))
  end

  # ===========================================================================
  # S4-b1 — tapToProduct в CartSheet (структура)
  # ===========================================================================

  test "S4-b1: tapToProduct функция определена" do
    assert_includes sheet, "function tapToProduct"
    assert_includes sheet, "push(`/product/"
  end

  test "S4-b1: tap игнорируется если клик по кнопке" do
    assert_includes sheet, 'e.target.closest("button")'
  end

  test "S4-b1: peek-карточки имеют cursor-pointer и onclick tapToProduct" do
    assert_includes sheet, "cursor-pointer"
    assert_includes sheet, "onclick={(e) => tapToProduct(line, e)"
  end

  test "S4-b1: peek и expanded карточки получают role=button и tabindex" do
    assert_includes sheet, 'role="button"'
    assert_includes sheet, 'tabindex="0"'
  end

  test "S4-b1: cart_line параметр передаётся в URL" do
    assert_includes sheet, "cart_line=${line.index}"
  end

  # ===========================================================================
  # S4-b2 — edit mode в Product.svelte (структура)
  # ===========================================================================

  test "S4-b2: Product содержит parseCartLine и cartLineIndex" do
    assert_includes product_svelte, "function parseCartLine()"
    assert_includes product_svelte, "cartLineIndex = $state(null)"
    assert_includes product_svelte, "editMode = $derived"
  end

  test "S4-b2: Product инициализирует модификаторы из кэша корзины" do
    assert_includes product_svelte, "readCartCache()"
    assert_includes product_svelte, "initSelectedFromCartLine"
  end

  test "S4-b2: Product отправляет PATCH /cart/items в editMode" do
    assert_includes product_svelte, 'method: "PATCH"'
    assert_includes product_svelte, "/cart/items/${cartLineIndex}"
    assert_includes product_svelte, "selected_modifiers, quantity: qty"
  end

  test "S4-b2: кнопка показывает Сохранить в editMode" do
    assert_includes product_svelte, "Сохранить"
    assert_includes product_svelte, "editMode"
    assert_includes product_svelte, "добавить к заказу"
  end

  test "S4-b2: stores обновляются после PATCH" do
    assert_includes product_svelte, "cartItems.set(data.items)"
    assert_includes product_svelte, "cartTotal.set"
    assert_includes product_svelte, "writeCartCache"
  end

  # ===========================================================================
  # S4-b3 — scroll dots в peek 4+ (структура)
  # ===========================================================================

  test "S4-b3: peekScrollIndex state и onPeekScroll функция" do
    assert_includes sheet, "peekScrollIndex = $state(0)"
    assert_includes sheet, "function onPeekScroll(e)"
  end

  test "S4-b3: контейнер имеет onscroll обработчик" do
    assert_includes sheet, "onscroll={onPeekScroll}"
  end

  test "S4-b3: dots рендерятся только при count >= 4" do
    assert_includes sheet, "count >= 4"
    assert_includes sheet, 'data-testid="shop-cart-peek-dots"'
    assert_includes sheet, 'aria-hidden="true"'
  end

  test "S4-b3: активная точка оранжевая (ff8c42), неактивная серая (555)" do
    assert_includes sheet, "bg-[#ff8c42]"
    assert_includes sheet, "bg-[#555]"
    assert_includes sheet, "transition-colors"
  end

  # ===========================================================================
  # S4-b2 — CartController API тесты (с реальной БД)
  # ===========================================================================

  setup do
    @tenant  = create_tenant!
    cat      = create_category!
    @product = create_product!(category: cat)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 250)
    host! "www.example.com"
  end

  def add_to_cart(qty = 1)
    post "/shop/api/cart/add",
      params: { product_id: @product.id, quantity: qty, tenant_id: @tenant.id },
      as: :json
    assert_response :success
    JSON.parse(response.body)
  end

  # --- Базовое добавление и пересчёт цены ---

  test "POST /cart/add: unit_total = цена за единицу, total = цена × qty" do
    body = add_to_cart(3)
    line = body["cart"].first
    assert_equal 3,     line["quantity"]
    assert_in_delta 250.0, line["unit_total"].to_f, 0.01  # unit price per item
    assert_in_delta 750.0, body["total"].to_f,      0.01  # total = 250 * 3
  end

  test "POST /cart/add: ответ содержит cart и total" do
    body = add_to_cart(1)
    assert body.key?("cart"), "должен быть ключ cart"
    assert body.key?("total"), "должен быть ключ total"
    assert_instance_of Array, body["cart"]
  end

  # --- PATCH с delta (регрессия S4-b2) ---

  test "PATCH /cart/items/:index delta: quantity увеличивается" do
    add_to_cart(2)
    patch "/shop/api/cart/items/0",
      params: { delta: 1, tenant_id: @tenant.id }, as: :json
    assert_response :success
    body  = JSON.parse(response.body)
    line  = body["items"].find { |l| l["index"] == 0 }
    assert_equal 3, line["quantity"]
  end

  test "PATCH /cart/items/:index delta: total пересчитывается" do
    add_to_cart(2)
    patch "/shop/api/cart/items/0",
      params: { delta: 1, tenant_id: @tenant.id }, as: :json
    body = JSON.parse(response.body)
    assert_in_delta 750.0, body["total"].to_f, 0.01
  end

  # --- PATCH с selected_modifiers (S4-b2 основная ветка) ---

  test "PATCH /cart/items/:index selected_modifiers: строка обновляется" do
    add_to_cart(2)
    patch "/shop/api/cart/items/0",
      params: { selected_modifiers: [], quantity: 4, tenant_id: @tenant.id },
      as: :json
    assert_response :success
    body = JSON.parse(response.body)
    line = body["items"].find { |l| l["index"] == 0 }
    assert_equal 4, line["quantity"]
  end

  test "PATCH /cart/items/:index selected_modifiers: total пересчитывается" do
    add_to_cart(1)
    patch "/shop/api/cart/items/0",
      params: { selected_modifiers: [], quantity: 4, tenant_id: @tenant.id },
      as: :json
    body = JSON.parse(response.body)
    assert_in_delta 1000.0, body["total"].to_f, 0.01
  end

  test "PATCH /cart/items/:index selected_modifiers: ответ содержит items и total" do
    add_to_cart(1)
    patch "/shop/api/cart/items/0",
      params: { selected_modifiers: [], tenant_id: @tenant.id }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("items"), "ожидается ключ items"
    assert body.key?("total"), "ожидается ключ total"
  end

  test "PATCH /cart/items/-1: возвращает 422" do
    patch "/shop/api/cart/items/-1",
      params: { selected_modifiers: [], tenant_id: @tenant.id }, as: :json
    assert_response :unprocessable_entity
  end

  test "PATCH /cart/items/99: возвращает 404 для несуществующего индекса" do
    add_to_cart(1)
    patch "/shop/api/cart/items/99",
      params: { selected_modifiers: [], tenant_id: @tenant.id }, as: :json
    assert_response :not_found
  end

  # --- Полный флоу S4: add → PATCH → проверка корзины ---

  test "S4 полный флоу: add → PATCH modifier → GET cart итого" do
    add_to_cart(2)

    patch "/shop/api/cart/items/0",
      params: { selected_modifiers: [], quantity: 3, tenant_id: @tenant.id },
      as: :json
    assert_response :success

    get "/shop/api/cart", params: { tenant_id: @tenant.id }, as: :json
    assert_response :success
    cart_body = JSON.parse(response.body)
    line = cart_body["items"].find { |l| l["index"] == 0 }
    assert_equal 3, line["quantity"]
    assert_in_delta 750.0, cart_body["total"].to_f, 0.01
  end
end
