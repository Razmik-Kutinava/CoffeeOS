# frozen_string_literal: true

require "test_helper"

class Platform::TenantsControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!
    @anchor = create_tenant!(organization: @org, slug: "anchor-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-#{SecureRandom.hex(4)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)
  end

  test "create rolls back tenant if Provision raises an error" do
    slug = "rollback-point-#{SecureRandom.hex(4)}"

    original = Platform::TenantOnboarding::Provision.method(:call)
    Platform::TenantOnboarding::Provision.define_singleton_method(:call) { |**| raise "provision failed" }

    begin
      assert_no_difference "Tenant.count" do
        post "/admin/tenants", params: {
          tenant: {
            organization_id: @org.id,
            name: "Откат точки",
            slug: slug,
            type: "sales_point",
            status: "active",
            country: "RU",
            currency: "RUB",
            timezone: "Europe/Moscow"
          }
        }
      end
      assert_response :unprocessable_entity
      assert_nil Tenant.find_by(slug: slug)
    ensure
      Platform::TenantOnboarding::Provision.define_singleton_method(:call, original)
    end
  end

  test "create provisions PTS for catalog products" do
    cat = create_category!
    product = create_product!(category: cat, slug: "shop-item-#{SecureRandom.hex(4)}")
    product.update!(base_price: 220)

    slug = "new-point-#{SecureRandom.hex(4)}"
    assert_difference -> { Tenant.count }, +1 do
      post "/admin/tenants", params: {
        tenant: {
          organization_id: @org.id,
          name: "Новая точка",
          slug: slug,
          type: "sales_point",
          status: "active",
          country: "RU",
          currency: "RUB",
          timezone: "Europe/Moscow"
        },
        modules: { "kiosk" => "1", "barista" => "1" }
      }
    end

    assert_response :redirect
    tenant = Tenant.find_by!(slug: slug)
    pts = ProductTenantSetting.find_by(tenant_id: tenant.id, product_id: product.id)
    assert pts
    assert_equal BigDecimal("220"), pts.price
  end
end
