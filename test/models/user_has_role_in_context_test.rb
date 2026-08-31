# frozen_string_literal: true

require "test_helper"

class UserHasRoleInContextTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant_a = create_tenant!(slug: "ctx-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(slug: "ctx-b-#{SecureRandom.hex(3)}")
    @user = create_user!(tenant: @tenant_a, role_codes: [], email: "ctx-user-#{SecureRandom.hex(3)}@test.local")
    @barista_role = create_role!(code: "barista")
  end

  test "point staff role scoped to tenant_id grants only matching tenant" do
    UserRole.create!(user: @user, role: @barista_role, tenant_id: @tenant_a.id)

    assert @user.has_role_in_context?("barista", tenant_id: @tenant_a.id)
    assert_not @user.has_role_in_context?("barista", tenant_id: @tenant_b.id)
  end

  test "legacy nil tenant_id point staff role does not leak across tenants" do
    ur = UserRole.create!(user: @user, role: @barista_role, tenant_id: @tenant_a.id)
    ur.update_column(:tenant_id, nil)

    assert_not @user.has_role_in_context?("barista", tenant_id: @tenant_a.id)
    assert_not @user.has_role_in_context?("barista", tenant_id: @tenant_b.id)
  end

  test "uk_global_admin remains global without tenant_id on user_role" do
    uk_role = create_role!(code: "ук_global_admin")
    UserRole.create!(user: @user, role: uk_role, tenant_id: nil)

    assert @user.has_role_in_context?("ук_global_admin", tenant_id: @tenant_a.id)
    assert @user.has_role_in_context?("ук_global_admin", tenant_id: @tenant_b.id)
  end

  test "blog_editor is global CMS role via has_role_in_context" do
    editor_role = create_role!(code: "blog_editor")
    UserRole.create!(user: @user, role: editor_role, tenant_id: nil)

    assert @user.has_role_in_context?("blog_editor", tenant_id: @tenant_a.id)
    assert @user.has_role_in_context?("blog_editor", tenant_id: @tenant_b.id)
  end

  test "unknown role code does not grant global access via else branch" do
    custom_role = create_role!(code: "custom_legacy_role")
    UserRole.create!(user: @user, role: custom_role, tenant_id: nil)

    assert_not @user.has_role_in_context?("custom_legacy_role", tenant_id: @tenant_a.id)
  end
end
