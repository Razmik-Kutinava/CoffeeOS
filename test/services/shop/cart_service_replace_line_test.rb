# frozen_string_literal: true

require "test_helper"

# B1.13-S4 блок 2 — CartService#replace_line! (замена/слияние модификаторов)
class Shop::CartServiceReplaceLineTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant  = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 150)
    @session = {}
  end

  def cart
    Shop::CartService.new(@session, @tenant.id)
  end

  def add_line!(qty = 1, mods = [])
    cart.add!(product_id: @product.id, quantity: qty, selected_modifiers: mods)
  end

  # --- replace без слияния (другая сигнатура) ---------------------------------

  test "replace_line! обновляет selected_modifiers строки на месте" do
    add_line!(2)
    cart.replace_line!(0, selected_modifiers: [], quantity: 2)
    assert_equal 1, @session[:shop_cart].size
    assert_equal @product.id, @session[:shop_cart][0]["product_id"]
    assert_equal 2, @session[:shop_cart][0]["quantity"]
  end

  test "replace_line! меняет количество если передан quantity" do
    add_line!(3)
    cart.replace_line!(0, selected_modifiers: [], quantity: 5)
    assert_equal 5, @session[:shop_cart][0]["quantity"]
  end

  test "replace_line! сохраняет старое количество если quantity не передан" do
    add_line!(3)
    cart.replace_line!(0, selected_modifiers: [])
    assert_equal 3, @session[:shop_cart][0]["quantity"]
  end

  # --- replace_line! с несуществующим индексом --------------------------------

  test "replace_line! бросает RecordNotFound если строки нет" do
    add_line!(1)
    assert_raises(ActiveRecord::RecordNotFound) do
      cart.replace_line!(99, selected_modifiers: [])
    end
  end

  # --- слияние при совпадении сигнатуры ---------------------------------------

  test "replace_line! объединяет строки если новая сигнатура совпадает с другой" do
    # Добавляем два разных товара (один продукт, разное количество — но у нас нет двух продуктов, используем линии с разными qty)
    # Проще: добавляем продукт дважды с разными mods, потом делаем replace без мода
    svc = cart
    svc.add!(product_id: @product.id, quantity: 2, selected_modifiers: [])
    # Добавляем "второй" продукт с теми же mods — это объединится add!
    # Для теста слияния нам нужен второй продукт
    category2  = create_category!
    product2   = create_product!(category: category2)
    enable_product_for_tenant!(tenant: @tenant, product: product2, price: 200)
    svc.add!(product_id: product2.id, quantity: 3, selected_modifiers: [])

    # Корзина: [product@qty2, product2@qty3]
    assert_equal 2, @session[:shop_cart].size

    # Меняем product2 (index 1) → product_id остаётся, mods те же → теперь оба product+no_mods одинаковые?
    # Нет, product_id разные. Слияние происходит только при одинаковом product_id + mods.
    # Проверяем: добавляем product ещё раз с разными mods, потом replace удаляем моды → слияние

    # Заново: один продукт, 2 строки с разными mods (нужны реальные модификаторы)
    # Без реальных модификаторов в тесте — имитируем compact_modifiers через session напрямую
    @session[:shop_cart] = [
      { "product_id" => @product.id, "quantity" => 2, "selected_modifiers" => [] },
      { "product_id" => @product.id, "quantity" => 3, "selected_modifiers" => [] }
    ]
    # Обе строки имеют одинаковую сигнатуру (product_id + []) — не должны существовать одновременно в норме.
    # Но проверяем, что replace_line! на индексе 0 при совпадении с индексом 1 → слияние.
    cart.replace_line!(0, selected_modifiers: [], quantity: 2)
    # После слияния: одна строка с qty = 3 + 2 = 5
    assert_equal 1, @session[:shop_cart].size
    assert_equal 5, @session[:shop_cart][0]["quantity"]
  end

  # --- pmax quantity clamp при слиянии ----------------------------------------

  test "replace_line! не превышает MAX_ITEM_QUANTITY при слиянии" do
    max = Shop::CartService::MAX_ITEM_QUANTITY
    @session[:shop_cart] = [
      { "product_id" => @product.id, "quantity" => max, "selected_modifiers" => [] },
      { "product_id" => @product.id, "quantity" => max, "selected_modifiers" => [] }
    ]
    cart.replace_line!(0, selected_modifiers: [], quantity: max)
    assert_equal 1, @session[:shop_cart].size
    assert_equal max, @session[:shop_cart][0]["quantity"]
  end
end
