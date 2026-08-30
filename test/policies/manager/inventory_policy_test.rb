# frozen_string_literal: true

require "test_helper"

class Manager::InventoryPolicyTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @gm = create_user!(tenant: @tenant, role_codes: %w[general_manager], email: "gm-inv-#{SecureRandom.hex(3)}@test.local")
    @shift_manager = create_user!(tenant: @tenant, role_codes: %w[shift_manager], email: "sm-inv-#{SecureRandom.hex(3)}@test.local")
    @org = create_organization!
    @franchise = create_user!(
      tenant: @tenant,
      organization: @org,
      role_codes: %w[franchise_manager],
      email: "fr-inv-#{SecureRandom.hex(3)}@test.local"
    )
  end

  def ctx(user, role_code:)
    PolicyContext.build(user: user, tenant_id: @tenant.id, role_code: role_code, tenant: @tenant)
  end

  test "general_manager and franchise_manager can view manager inventory" do
    assert Manager::InventoryPolicy.new(ctx(@gm, role_code: "general_manager"), IngredientTenantStock).index?
    assert Manager::InventoryPolicy.new(ctx(@franchise, role_code: "franchise_manager"), IngredientTenantStock).index?
  end

  test "shift_manager cannot view manager inventory" do
    policy = Manager::InventoryPolicy.new(ctx(@shift_manager, role_code: "shift_manager"), IngredientTenantStock)
    assert_not policy.index?
  end
end
