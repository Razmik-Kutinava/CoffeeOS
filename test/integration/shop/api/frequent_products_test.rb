# frozen_string_literal: true

require "test_helper"

# Quick Repeat Bottom Sheet — Шаг B4 (ТЗ Шаг 4):
# GET /shop/api/frequent_products → { frequent_items: [...], categories: { "Имя" => [...] } }.
# Адаптация ТЗ: витрина гостевая (Shop::CustomerSession) — гость получает
# frequent_items: [] и HTTP 200, а не 401 (решение SPEC, вопрос владельцу №2).
class Shop::Api::FrequentProductsTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "freqapi-#{SecureRandom.hex(3)}")
    @category = create_category!(name: "Черный")
    @product = create_product!(category: @category, name: "Фильтр-кофе Бразилия")
    @product.update!(image_url: "https://cdn.example.com/brazil.png")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 250)
    Rails.cache.clear
  end

  test "guest without history gets 200 with empty frequent_items and categories" do
    get "/shop/api/frequent_products", headers: shop_headers, as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal [], body["frequent_items"]
    assert body["categories"].is_a?(Hash), "categories должен быть объектом { имя => товары }"
    assert body["categories"].key?("Черный")
  end

  test "categories contain product cards with id, name, price, image_url" do
    no_photo = create_product!(category: @category, name: "Матча тоник")
    enable_product_for_tenant!(tenant: @tenant, product: no_photo, price: 205)

    get "/shop/api/frequent_products", headers: shop_headers, as: :json

    assert_response :success
    cards = response.parsed_body["categories"]["Черный"]
    assert_equal 2, cards.length

    card = cards.find { |c| c["id"] == @product.id }
    assert_equal "Фильтр-кофе Бразилия", card["name"]
    assert_equal 250.0, card["price"]
    assert_equal "https://cdn.example.com/brazil.png", card["image_url"]

    placeholder_card = cards.find { |c| c["id"] == no_photo.id }
    assert_nil placeholder_card["image_url"], "товар без фото → image_url nil (заглушка «Нет фото» на фронте)"
  end

  test "customer with order history gets frequent_items after checkout" do
    email = "freqapi-#{SecureRandom.hex(4)}@example.com"
    place_order!(email: email)

    get "/shop/api/frequent_products", headers: shop_headers, as: :json

    assert_response :success
    items = response.parsed_body["frequent_items"]
    assert_equal 1, items.length

    item = items.first
    assert_equal @product.id, item["product_id"]
    assert_equal "Фильтр-кофе Бразилия", item["name"]
    assert_equal 250.0, item["price"]
    assert_equal "https://cdn.example.com/brazil.png", item["image_url"]
    assert item.key?("modifier_options"), "карточка повтора несёт полный сет кастомизаций"
  end

  test "frequent_items are isolated per tenant session" do
    email = "freqapi-iso-#{SecureRandom.hex(4)}@example.com"
    place_order!(email: email)

    other_tenant = create_tenant!(slug: "freqapi-oth-#{SecureRandom.hex(3)}")
    enable_product_for_tenant!(tenant: other_tenant, product: @product, price: 300)

    get "/shop/api/frequent_products", headers: { "X-Shop-Tenant" => other_tenant.id.to_s }, as: :json

    assert_response :success
    assert_equal [], response.parsed_body["frequent_items"],
      "заказы точки A не должны попадать в повтор точки B"
  end

  test "unknown tenant returns error payload" do
    get "/shop/api/frequent_products", headers: { "X-Shop-Tenant" => SecureRandom.uuid }, as: :json

    assert_response :not_found
    assert response.parsed_body["error"].present?
  end

  private

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  # Полный флоу заказа: корзина → верификация email → заказ (cash + SHOP_SIMULATE_PAYMENT=1 → accepted).
  # Привязывает customer_id к сессии — как у реального клиента витрины.
  def place_order!(email:)
    post "/shop/api/cart/add",
      headers: shop_headers,
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    assert_response :success

    verify_shop_email!(tenant_id: @tenant.id, email: email)

    post "/shop/api/orders",
      headers: shop_headers,
      params: shop_order_params(email: email, name: "Freq Customer", payment_method: "cash"),
      as: :json
    assert_response :success
  end
end
