# frozen_string_literal: true

require "test_helper"

# W1.4: сверка категорий/товаров — витрина (shop API) = barista (меню/POS).
class Platform::UkMenuW14CategorySyncTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "w14-org-#{SecureRandom.hex(3)}")
    @tenant = create_tenant!(organization: @org, name: "W14", slug: "w14-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @tenant,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-w14-#{SecureRandom.hex(3)}@test.local"
    )
    @barista = create_user!(
      tenant: @tenant,
      organization: @org,
      role_codes: %w[barista],
      email: "barista-w14-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(@uk)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "shop categories API matches Shop::Catalog tree and barista menu after UK publish" do
    suffix = SecureRandom.hex(3)

    post platform_menu_categories_path, params: {
      category: { name: "W14 Cat #{suffix}", slug: "w14-cat-#{suffix}", is_active: true, sort_order: 1 }
    }
    assert_response :redirect
    category = Category.find_by!(slug: "w14-cat-#{suffix}")

    post platform_menu_products_path, params: {
      product: {
        category_id: category.id,
        name: "W14 Visible #{suffix}",
        slug: "w14-vis-#{suffix}",
        base_price: 210,
        is_active: true,
        sort_order: 1
      }
    }
    assert_response :redirect
    visible = Product.find_by!(slug: "w14-vis-#{suffix}")

    post platform_menu_products_path, params: {
      product: {
        category_id: category.id,
        name: "W14 Hidden #{suffix}",
        slug: "w14-hid-#{suffix}",
        base_price: 190,
        is_active: true,
        sort_order: 2
      }
    }
    assert_response :redirect
    hidden = Product.find_by!(slug: "w14-hid-#{suffix}")

    pts = ProductTenantSetting.find_by!(tenant_id: @tenant.id, product_id: hidden.id)
    pts.update!(is_enabled: false)

    expected_tree = Shop::Catalog.category_product_ids(@tenant.id)
    assert_equal [ visible.id ], expected_tree[category.id]

    get "/shop/api/categories", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    shop_tree = shop_api_category_tree(response.parsed_body)
    assert_equal expected_tree, shop_tree

    login_as!(@barista)
    get barista_menu_path
    assert_response :success
    assert_includes response.body, "W14 Visible #{suffix}"
    refute_includes response.body, "W14 Hidden #{suffix}"
    assert_includes response.body, "W14 Cat #{suffix}"
  end

  test "inactive category hidden from vitrina and barista while UK still lists product" do
    suffix = SecureRandom.hex(3)

    post platform_menu_categories_path, params: {
      category: { name: "W14 Off #{suffix}", slug: "w14-off-#{suffix}", is_active: false, sort_order: 1 }
    }
    assert_response :redirect
    category = Category.find_by!(slug: "w14-off-#{suffix}")

    post platform_menu_products_path, params: {
      product: {
        category_id: category.id,
        name: "W14 Off Prod #{suffix}",
        slug: "w14-off-prod-#{suffix}",
        base_price: 150,
        is_active: true,
        sort_order: 1
      }
    }
    assert_response :redirect

    assert_empty Shop::Catalog.category_product_ids(@tenant.id).keys

    get "/shop/api/categories", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    refute response.parsed_body["data"].any? { |c| c["id"] == category.id }

    login_as!(@barista)
    get barista_menu_path
    assert_response :success
    refute_includes response.body, "W14 Off Prod #{suffix}"
  end

  test "sold out product excluded from vitrina and barista like products_scope" do
    suffix = SecureRandom.hex(3)

    post platform_menu_categories_path, params: {
      category: { name: "W14 SO #{suffix}", slug: "w14-so-#{suffix}", is_active: true, sort_order: 1 }
    }
    assert_response :redirect
    category = Category.find_by!(slug: "w14-so-#{suffix}")

    post platform_menu_products_path, params: {
      product: {
        category_id: category.id,
        name: "W14 SoldOut #{suffix}",
        slug: "w14-so-prod-#{suffix}",
        base_price: 170,
        is_active: true,
        sort_order: 1
      }
    }
    assert_response :redirect
    product = Product.find_by!(slug: "w14-so-prod-#{suffix}")

    ProductTenantSetting.find_by!(tenant_id: @tenant.id, product_id: product.id)
      .update!(is_sold_out: true, sold_out_reason: "manual")

    assert_empty Shop::Catalog.products_scope(@tenant.id).pluck(:id)

    get "/shop/api/categories", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    assert_empty shop_api_category_tree(response.parsed_body)

    login_as!(@barista)
    get barista_menu_path
    assert_response :success
    refute_includes response.body, "W14 SoldOut #{suffix}"
  end

  private

  def shop_api_category_tree(body)
    body.fetch("data").each_with_object({}) do |cat, acc|
      acc[cat["id"]] = cat.fetch("products").map { |p| p["id"] }
    end
  end
end
