# frozen_string_literal: true

require "test_helper"

# W1.3: обязательные модификаторы — УК is_required → shop API + корзина только с выбором.
class Platform::UkMenuW13RequiredModifiersTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "w13-org-#{SecureRandom.hex(3)}")
    @tenant = create_tenant!(organization: @org, name: "W13", slug: "w13-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @tenant,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-w13-#{SecureRandom.hex(3)}@test.local"
    )
    @category = create_category!(name: "W13 Cat", slug: "w13-cat-#{SecureRandom.hex(3)}")
    login_as!(@uk)

    post platform_menu_products_path, params: {
      product: {
        category_id: @category.id,
        name: "W13-REQ-001",
        slug: "w13-req-#{SecureRandom.hex(3)}",
        base_price: 220,
        is_active: true,
        sort_order: 1
      }
    }
    assert_response :redirect
    @product = Product.order(created_at: :desc).first

    post platform_menu_modifier_groups_path, params: {
      product_modifier_group: {
        product_id: @product.id,
        name: "W13 Taste",
        is_required: true,
        sort_order: 1
      }
    }
    assert_response :redirect
    @group = ProductModifierGroup.find_by!(product_id: @product.id, name: "W13 Taste")

    post platform_menu_modifier_options_path, params: {
      product_modifier_option: { group_id: @group.id, name: "Vanilla", price_delta: 30, is_active: true, sort_order: 1 }
    }
    assert_response :redirect
    @option = ProductModifierOption.find_by!(group_id: @group.id, name: "Vanilla")
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "required modifier group exposed on shop product API as required" do
    get "/shop/api/products/#{@product.id}", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    groups = response.parsed_body["modifier_groups"]
    assert_equal 1, groups.size
    assert_equal "required", groups.first["modifier_type"]
    assert_equal "W13 Taste", groups.first["name"]
    assert_equal @option.id, groups.first["modifiers"].first["id"]
  end

  test "cart add with required modifier selection succeeds and prices modifier delta" do
    mods = [{ id: @option.id, name: "Vanilla", price: 30.0 }]
    post "/shop/api/cart/add",
      params: { product_id: @product.id, quantity: 1, selected_modifiers: mods },
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      as: :json
    assert_response :success

    get "/shop/api/cart", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    item = response.parsed_body["items"].first
    assert_equal 250.0, item["unit_total"].to_f
    assert_equal 1, item["selected_modifiers"].size
  end
end
