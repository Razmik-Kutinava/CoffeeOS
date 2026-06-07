# frozen_string_literal: true

require "test_helper"

# УК: форма товара — относительный /uploads/… в image_url не блокирует сохранение (не type="url").
class Platform::UkMenuProductImageUrlFormTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "img-url-org-#{SecureRandom.hex(3)}")
    @tenant = create_tenant!(organization: @org, name: "Img URL", slug: "img-url-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @tenant,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-img-url-#{SecureRandom.hex(3)}@test.local"
    )
    @category = create_category!(name: "Img URL Cat #{SecureRandom.hex(3)}")
    @product = create_product!(category: @category, name: "Test Coffee", slug: "test-coffee-#{SecureRandom.hex(3)}")
    @product.update!(base_price: 295, image_url: "/uploads/products/#{SecureRandom.hex(4)}.png")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 295)

    login_as!(@uk)
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "edit form uses text input for image_url not url type" do
    get platform_menu_path
    assert_response :success
    assert_no_match(/name="product\[image_url\]"[^>]*type="url"/, response.body)
    assert_match(/name="product\[image_url\]"[^>]*type="text"/, response.body)
  end

  test "update product keeps relative image_url and low base_price" do
    patch platform_menu_product_path(@product), params: {
      product: {
        category_id: @category.id,
        name: @product.name,
        slug: @product.slug,
        base_price: 2.95,
        image_url: @product.image_url,
        sort_order: 1,
        is_active: "1"
      }
    }
    assert_redirected_to platform_menu_path
    follow_redirect!
    assert_response :success

    @product.reload
    assert_in_delta 2.95, @product.base_price.to_f, 0.001
    assert @product.image_url.start_with?("/uploads/products/")
  end
end
