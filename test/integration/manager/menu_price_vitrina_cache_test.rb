# frozen_string_literal: true

require "test_helper"

# W1.1: цена из manager/menu должна сразу попадать на витрину (сброс кэша categories API).
class Manager::MenuPriceVitrinaCacheTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category, name: "Cache Price Product")
    @pts = enable_product_for_tenant!(tenant: @tenant, product: @product, price: 100)

    @manager = create_user!(
      tenant: @tenant,
      role_codes: %w[general_manager],
      email: "gm-cache-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(@manager)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "manager price update busts shop categories cache so vitrina shows new price" do
    cache_key = "shop/categories/#{@tenant.id}//"
    stale = {
      "data" => [ {
        "id" => @product.category_id,
        "name" => "Stale",
        "products" => [ { "id" => @product.id, "name" => @product.name, "price" => 100.0 } ]
      } ],
      "meta" => { "page" => 1, "per_page" => 50 }
    }
    Rails.cache.write(cache_key, stale, expires_in: 5.minutes)

    patch manager_menu_setting_price_path(@pts), params: { product_tenant_setting: { price: 199 } }
    assert_redirected_to manager_menu_path
    assert_equal 199.to_d, @pts.reload.price.to_d

    get "/shop/api/categories", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success

    json = JSON.parse(response.body)
    product_json = json["data"].flat_map { |c| c["products"] }.find { |p| p["id"] == @product.id }
    assert product_json, "product must appear in categories API"
    assert_in_delta 199.0, product_json["price"].to_f, 0.01
  end
end
