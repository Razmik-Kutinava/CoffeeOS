# frozen_string_literal: true

require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @user = create_user!(tenant: @tenant, role_codes: [], email: "ur-test@local")
    @barista_role = create_role!(code: "barista")
  end

  test "point staff role requires tenant_id on new grant" do
    ur = UserRole.new(user: @user, role: @barista_role, tenant_id: nil)
    assert_not ur.valid?
    assert_includes ur.errors[:tenant_id].join, "обязателен"
  end

  test "point staff role valid with tenant_id" do
    ur = UserRole.new(user: @user, role: @barista_role, tenant_id: @tenant.id)
    assert ur.valid?
  end

  test "uk_global_admin role may omit tenant_id" do
    uk_role = create_role!(code: "ук_global_admin")
    ur = UserRole.new(user: @user, role: uk_role, tenant_id: nil)
    assert ur.valid?
  end
end
