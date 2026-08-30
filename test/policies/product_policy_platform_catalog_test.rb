# frozen_string_literal: true

require "test_helper"

class ProductPolicyPlatformCatalogTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @uk = create_uk_admin!(email: "uk-prod-pol-#{SecureRandom.hex(3)}@test.local")
    @gm = create_user!(tenant: @tenant, role_codes: %w[general_manager], email: "gm-prod-#{SecureRandom.hex(3)}@test.local")
    @product = Product.create!(
      category: Category.create!(name: "Cat", slug: "cat-#{SecureRandom.hex(3)}", sort_order: 1, is_active: true),
      name: "Latte",
      slug: "latte-#{SecureRandom.hex(3)}",
      base_price: 100,
      sort_order: 1,
      is_active: true
    )
  end

  test "uk_global_admin can manage platform catalog products" do
    policy = ProductPolicy.new(@uk, @product)
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "general_manager cannot mutate global catalog via ProductPolicy" do
    policy = ProductPolicy.new(@gm, @product)
    assert policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end
end
