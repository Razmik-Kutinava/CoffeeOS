# frozen_string_literal: true

require "test_helper"

class Platform::TenantOnboarding::ProvisionShopApiKeyTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = create_organization!
    @actor = create_user!(
      tenant: create_tenant!(organization: @org, slug: "prov-actor-#{SecureRandom.hex(3)}"),
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "prov-#{SecureRandom.hex(4)}@test.local",
      password: "pass123"
    )
  end

  test "sales_point provision issues tenant shop api key once" do
    tenant = create_tenant!(organization: @org, slug: "prov-sp-#{SecureRandom.hex(3)}")

    result = nil
    assert_difference -> { ShopApiKey.where(tenant_id: tenant.id).count }, +1 do
      result = Platform::TenantOnboarding::Provision.call(
        tenant: tenant,
        actor_user_id: @actor.id,
        module_params: {}
      )
    end

    assert result[:ok]
    assert result[:shop_api_key][:raw].present?
    assert result[:shop_api_key][:prefix].present?
    assert_equal result[:shop_api_key][:raw][0, 8], result[:shop_api_key][:prefix]

    second = Platform::TenantOnboarding::Provision.call(
      tenant: tenant,
      actor_user_id: @actor.id,
      module_params: {}
    )
    assert second[:ok]
    assert_nil second[:shop_api_key]
    assert_equal 1, ShopApiKey.usable.where(tenant_id: tenant.id, global_ops: false).count
  end

  test "production_kitchen provision does not issue shop api key" do
    tenant = create_tenant!(
      organization: @org,
      slug: "prov-pk-#{SecureRandom.hex(3)}",
      type: "production_kitchen"
    )

    assert_no_difference -> { ShopApiKey.count } do
      result = Platform::TenantOnboarding::Provision.call(
        tenant: tenant,
        actor_user_id: @actor.id,
        module_params: {}
      )
      assert result[:ok]
      assert_nil result[:shop_api_key]
    end
  end
end
