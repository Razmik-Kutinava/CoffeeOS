# frozen_string_literal: true

require "test_helper"

class Platform::Menu::PublishProductServiceTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = create_organization!
    @tenant_a = create_tenant!(organization: @org, name: "A", slug: "pub-a-#{SecureRandom.hex(2)}")
    @tenant_b = create_tenant!(organization: @org, name: "B", slug: "pub-b-#{SecureRandom.hex(2)}")
    @uk_user = create_user!(
      tenant: @tenant_a,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-pub-#{SecureRandom.hex(3)}@test.local"
    )
    @category = create_category!
  end

  test "creates product and product tenant settings for all tenants" do
    product = Product.new(
      category: @category,
      name: "Publish Test",
      slug: "publish-test-#{SecureRandom.hex(2)}",
      base_price: 150,
      sort_order: 1,
      is_active: true,
      created_by: @uk_user
    )

    assert_difference "Product.count", 1 do
      Platform::Menu::PublishProductService.new(product: product, user: @uk_user).call!
    end

    pts = ProductTenantSetting.where(product_id: product.id)
    assert_equal 2, pts.where(tenant_id: [@tenant_a.id, @tenant_b.id]).count
    assert pts.all? { |row| row.is_enabled? && row.price.to_d == 150.to_d }
    assert_equal Tenant.count, pts.count
  end
end
