# frozen_string_literal: true

require "test_helper"

# W1.2: УК → категория + 2 товара + фото + модификаторы → витрина A/B (shop API).
class Platform::UkMenuW12VitrinaTest < ActionDispatch::IntegrationTest
  include TestFactories

  MINIMAL_PNG = Base64.strict_decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "w12-org-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "W12 A", slug: "w12-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(organization: @org, name: "W12 B", slug: "w12-b-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @tenant_a,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-w12-#{SecureRandom.hex(3)}@test.local"
    )
    login_as!(@uk)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "uk creates category two products photo modifiers and both vitrinas see them" do
    suffix = SecureRandom.hex(3)
    cat_name = "W12 Cat #{suffix}"

    post platform_menu_categories_path, params: {
      category: { name: cat_name, slug: "w12-cat-#{suffix}", is_active: true, sort_order: 0 }
    }
    assert_response :redirect
    category = Category.find_by!(slug: "w12-cat-#{suffix}")

    png = Rack::Test::UploadedFile.new(
      StringIO.new(MINIMAL_PNG.dup),
      "image/png",
      original_filename: "w12-photo.png"
    )
    post platform_menu_products_path, params: {
      product: {
        category_id: category.id,
        name: "W12 Photo #{suffix}",
        slug: "w12-photo-#{suffix}",
        base_price: 320,
        is_active: true,
        sort_order: 1,
        image: png
      }
    }
    assert_response :redirect
    product_photo = Product.find_by!(slug: "w12-photo-#{suffix}")
    assert product_photo.image_url.present?, "uploaded photo must set image_url"

    post platform_menu_products_path, params: {
      product: {
        category_id: category.id,
        name: "W12 Plain #{suffix}",
        slug: "w12-plain-#{suffix}",
        base_price: 180,
        is_active: true,
        sort_order: 2
      }
    }
    assert_response :redirect
    product_plain = Product.find_by!(slug: "w12-plain-#{suffix}")

    post platform_menu_modifier_groups_path, params: {
      product_modifier_group: {
        product_id: product_photo.id,
        name: "W12 Size",
        is_required: false,
        sort_order: 1
      }
    }
    assert_response :redirect
    group = ProductModifierGroup.find_by!(product_id: product_photo.id, name: "W12 Size")

    post platform_menu_modifier_options_path, params: {
      product_modifier_option: { group_id: group.id, name: "Small", price_delta: 0, is_active: true, sort_order: 1 }
    }
    assert_response :redirect
    post platform_menu_modifier_options_path, params: {
      product_modifier_option: { group_id: group.id, name: "Large", price_delta: 50, is_active: true, sort_order: 2 }
    }
    assert_response :redirect

    [@tenant_a, @tenant_b].each do |tenant|
      assert_vitrina_catalog!(
        tenant_id: tenant.id,
        category_id: category.id,
        products: [
          { id: product_photo.id, name: "W12 Photo #{suffix}", price: 320.0, image: true },
          { id: product_plain.id, name: "W12 Plain #{suffix}", price: 180.0, image: false }
        ]
      )
    end

    get "/shop/api/products/#{product_photo.id}", headers: { "X-Shop-Tenant" => @tenant_a.id.to_s }
    assert_response :success
    detail = response.parsed_body
    assert detail["image_url"].present?
    groups = detail["modifier_groups"]
    assert_equal 1, groups.size
    assert_equal "W12 Size", groups.first["name"]
    assert_equal 2, groups.first["modifiers"].size
    assert_includes groups.first["modifiers"].map { |m| m["name"] }, "Large"
  end

  private

  def assert_vitrina_catalog!(tenant_id:, category_id:, products:)
    get "/shop/api/categories", headers: { "X-Shop-Tenant" => tenant_id.to_s }
    assert_response :success
    cat = response.parsed_body["data"].find { |c| c["id"] == category_id }
    assert cat, "category must appear on vitrina tenant=#{tenant_id}"

    products.each do |expected|
      row = cat["products"].find { |p| p["id"] == expected[:id] }
      assert row, "product #{expected[:id]} on tenant #{tenant_id}"
      assert_equal expected[:name], row["name"]
      assert_in_delta expected[:price], row["price"].to_f, 0.01
      if expected[:image]
        assert row["image_url"].present?, "photo product must have image_url on categories API"
      end
    end
  end
end
