# frozen_string_literal: true

require "test_helper"

# #65: связка TG/IG In-App → /shop?tenant_id= → meta / categories без silent fallback.
class Shop::ShopTenantLinkageTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!(slug: "linkage-org-#{SecureRandom.hex(2)}")
    @tenant_a = create_tenant!(name: "Point A", slug: "point-a-#{SecureRandom.hex(2)}", organization: @org)
    @tenant_b = create_tenant!(name: "Point B", slug: "point-b-#{SecureRandom.hex(2)}", organization: @org)
  end

  test "GET /shop?tenant_id= sets matching shop-tenant-id meta" do
    get "/shop", params: { tenant_id: @tenant_a.id }
    assert_response :success
    assert_includes response.body, %(name="shop-tenant-id" content="#{@tenant_a.id}")
    refute_includes response.body, %(content="#{@tenant_b.id}")
  end

  test "GET /shop?tenant_id= unknown does not render other tenant meta" do
    get "/shop", params: { tenant_id: "00000000-0000-0000-0000-000000000099" }
    assert_response :success
    refute_match(/name="shop-tenant-id"/, response.body)
  end

  test "GET /shop?tenant_id= blank does not silent-fallback to another tenant meta" do
    get "/shop", params: { tenant_id: "" }
    assert_response :success
    refute_match(/name="shop-tenant-id"/, response.body)
  end
end
