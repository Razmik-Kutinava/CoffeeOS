# frozen_string_literal: true

require "test_helper"

class ShopTenantSubdomainTest < ActionDispatch::IntegrationTest
  include TestFactories

  test "shop API resolves tenant from subdomain host" do
    org = create_organization!
    tenant = create_tenant!(organization: org, slug: "slug-shop-#{SecureRandom.hex(3)}")
    prev = ENV["SHOP_BASE_DOMAIN"]
    ENV["SHOP_BASE_DOMAIN"] = "example.org"
    host! "#{tenant.slug}.example.org"
    get "/shop/api/categories"
    assert_response :success
  ensure
    ENV["SHOP_BASE_DOMAIN"] = prev
  end
end
