# frozen_string_literal: true

require "test_helper"

# Владелец франшизы — роль на уровне организации (tenant_id NULL), не на «первую точку».
class Platform::FranchiseOwnersControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @uk_point = create_tenant!(slug: "uk-home-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @uk_point,
      role_codes: %w[ук_global_admin],
      email: "uk-fo-#{SecureRandom.hex(4)}@test.local"
    )
    login_as!(@uk)
  end

  def owner_params(org, email)
    { user: { organization_id: org.id, name: "Владелец", email: email, password: "secret123" } }
  end

  def with_rails_env(name)
    old = Rails.env
    Rails.env = name
    yield
  ensure
    Rails.env = old
  end

  test "owner can be created for organization without points" do
    org = create_organization!(name: "Новая франшиза")
    email = "owner-#{SecureRandom.hex(3)}@test.local"

    assert_difference -> { User.count }, +1 do
      post platform_franchise_owners_path, params: owner_params(org, email)
    end

    owner = User.find_by!(email: email)
    assert_equal org.id, owner.organization_id
    assert_nil owner.tenant_id
    role = UserRole.joins(:role).find_by!(user_id: owner.id, roles: { code: "franchise_manager" })
    assert_nil role.tenant_id
  end

  test "owner role is organization-wide even when organization has points" do
    org = create_organization!
    first = create_tenant!(organization: org)
    second = create_tenant!(organization: org)
    email = "owner-#{SecureRandom.hex(3)}@test.local"

    post platform_franchise_owners_path, params: owner_params(org, email)

    owner = User.find_by!(email: email)
    role = UserRole.joins(:role).find_by!(user_id: owner.id, roles: { code: "franchise_manager" })
    assert_nil role.tenant_id
    assert_equal [ first.id, second.id ].sort, owner.accessible_manager_tenants.pluck(:id).sort
  end

  test "owner creation works under production tenant guard" do
    org = create_organization!
    email = "owner-prod-#{SecureRandom.hex(3)}@test.local"

    with_rails_env("production") do
      post platform_franchise_owners_path, params: owner_params(org, email)
    end

    assert User.exists?(email: email)
  end

  test "UK global role can be granted without tenant under production guard" do
    user = create_user!(tenant: @uk_point, role_codes: [], email: "plain-#{SecureRandom.hex(3)}@test.local")
    role = create_role!(code: "ук_global_admin")

    with_rails_env("production") do
      UserRole.create!(user: user, role: role, tenant_id: nil)
    end

    assert user.reload.uk_global_admin?
  end
end
