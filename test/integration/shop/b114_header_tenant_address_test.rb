# frozen_string_literal: true

require "test_helper"

# B1.14-3: адрес точки в шапке вместо CoffeeOS
class Shop::B114HeaderTenantAddressTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "b114-hdr-#{SecureRandom.hex(3)}")
    @tenant.update!(city: "Москва", address: "ул. Ленина, 10")
  end

  test "header source: tenant address replaces CoffeeOS brand" do
    header = File.read(Rails.root.join("app/frontend/components/Header.svelte"))
    lib = File.read(Rails.root.join("app/frontend/lib/shopTenantHeader.js"))
    app = File.read(Rails.root.join("app/frontend/App.svelte"))

    refute_includes header, ">CoffeeOS<"
    refute_includes header, "CoffeeOS</button>"
    assert_includes header, 'data-testid="shop-header-tenant-address"'
    assert_includes header, 'data-testid="shop-tenant-dropdown"'
    assert_includes header, "shopTenantHeader"
    assert_includes header, "shop-hours-display"
    assert_includes lib, "formatTenantDisplayAddress"
    assert_includes lib, "bootstrapShopTenant"
    assert_includes lib, "Адрес не указан"
    assert_includes app, "bootstrapShopTenant"
  end

  test "shop page shell loads with tenant meta" do
    get "/shop?tenant_id=#{@tenant.id}"
    assert_response :success
    assert_includes response.body, 'meta name="shop-tenant-id"'
    assert_includes response.body, @tenant.id.to_s
  end
end
