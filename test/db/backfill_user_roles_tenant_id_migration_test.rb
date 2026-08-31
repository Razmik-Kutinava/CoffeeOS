# frozen_string_literal: true

require "test_helper"

class BackfillUserRolesTenantIdMigrationTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    require Rails.root.join("db/migrate/20260831140000_backfill_user_roles_tenant_id.rb")
    @migration = BackfillUserRolesTenantId.new
    @tenant = create_tenant!(slug: "mig-ur-#{SecureRandom.hex(3)}")
    @other_tenant = create_tenant!(slug: "mig-ur-other-#{SecureRandom.hex(3)}")
    @user = create_user!(tenant: @tenant, role_codes: [], email: "mig-ur-#{SecureRandom.hex(3)}@test.local")
    @barista_role = create_role!(code: "barista")
  end

  test "backfill sets tenant_id from user for legacy null point staff grant" do
    ur = UserRole.create!(user: @user, role: @barista_role, tenant_id: @tenant.id)
    ur.update_column(:tenant_id, nil)

    @migration.up
    ur.reload

    assert_equal @tenant.id, ur.tenant_id
    assert @user.has_role_in_context?("barista", tenant_id: @tenant.id)
    assert_not @user.has_role_in_context?("barista", tenant_id: @other_tenant.id)
  end

  test "backfill drops redundant null grant when scoped grant already exists" do
    UserRole.create!(user: @user, role: @barista_role, tenant_id: @tenant.id)
    legacy = UserRole.new(user: @user, role: @barista_role, tenant_id: nil)
    legacy.save!(validate: false)

    assert_equal 2, UserRole.where(user_id: @user.id, role_id: @barista_role.id).count

    @migration.up

    assert_equal 1, UserRole.where(user_id: @user.id, role_id: @barista_role.id).count
    assert UserRole.exists?(user_id: @user.id, role_id: @barista_role.id, tenant_id: @tenant.id)
  end

  test "backfill removes orphan null point staff grant when user has no tenant" do
    orphan = User.create!(
      tenant: nil,
      name: "Orphan",
      email: "orphan-#{SecureRandom.hex(3)}@test.local",
      status: "active",
      password: "pass123"
    )
    ur = UserRole.new(user: orphan, role: @barista_role, tenant_id: nil)
    ur.save!(validate: false)

    @migration.up

    assert_not UserRole.exists?(id: ur.id)
  end
end
