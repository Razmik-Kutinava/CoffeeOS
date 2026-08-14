# frozen_string_literal: true

require "test_helper"

# #65: целостность tenant_id связки без рендера Vite layout (CI: нет vite-test manifest).
class Shop::ShopTenantLinkageTest < ActiveSupport::TestCase
  include TestFactories

  class ResolveProbe
    include Shop::Concerns::TenantResolution

    attr_reader :params, :request

    def initialize(params_hash, host: "www.example.com")
      @params = ActionController::Parameters.new(params_hash)
      @request = ActionDispatch::TestRequest.create
      @request.host = host
    end

    public :resolved_shop_tenant_id
  end

  setup do
    @org = create_organization!(slug: "linkage-org-#{SecureRandom.hex(2)}")
    @tenant_a = create_tenant!(name: "Point A", slug: "point-a-#{SecureRandom.hex(2)}", organization: @org)
    @tenant_b = create_tenant!(name: "Point B", slug: "point-b-#{SecureRandom.hex(2)}", organization: @org)
  end

  test "layout renders shop-tenant-id meta when @shop_tenant set" do
    layout = File.read(Rails.root.join("app/views/layouts/shop.html.erb"))
    assert_includes layout, 'name="shop-tenant-id"'
    assert_includes layout, "@shop_tenant.id"
  end

  test "explicit tenant_id resolves to that tenant for pages home logic" do
    tid = ResolveProbe.new({ tenant_id: @tenant_a.id.to_s }).resolved_shop_tenant_id
    assert_equal @tenant_a.id, tid
    tenant = Tenant.find_by(id: tid)
    assert_equal @tenant_a.id, tenant.id
    assert_not_equal @tenant_b.id, tenant.id
  end

  test "unknown tenant_id does not resolve to another tenant" do
    tid = ResolveProbe.new({ tenant_id: "00000000-0000-0000-0000-000000000099" }).resolved_shop_tenant_id
    assert_equal "00000000-0000-0000-0000-000000000099", tid
    assert_nil Tenant.find_by(id: tid)
  end

  test "blank tenant_id key does not silent-fallback to another tenant" do
    tid = ResolveProbe.new({ tenant_id: "" }).resolved_shop_tenant_id
    assert_nil tid
  end
end
