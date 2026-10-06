# frozen_string_literal: true

require "test_helper"

# УК и владелец франшизы живут без tenant_id (уровень выше точки) — вход не должен падать
# на prod-guard ApplicationRecord#ensure_tenant_id.
class Auth::LoginWithoutTenantTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = false
    @anchor = create_tenant!
  end

  def with_rails_env(name)
    old = Rails.env
    Rails.env = name
    yield
  ensure
    Rails.env = old
  end

  def user_without_tenant!(role_code)
    user = create_user!(tenant: @anchor, role_codes: [], email: "nt-#{SecureRandom.hex(4)}@test.local", password: "pass123")
    user.update_column(:tenant_id, nil)
    UserRole.create!(user: user, role: Role.find_by(code: role_code) || create_role!(code: role_code), tenant_id: nil)
    user
  end

  test "UK admin without tenant logs in under production guard" do
    user = user_without_tenant!("ук_global_admin")

    with_rails_env("production") do
      post "/login", params: { email: user.email, password: "pass123" }
    end

    assert_response :redirect
    assert_equal user.id.to_s, session[:user_id].to_s
    db_session = Session.find(session[:db_session_id])
    assert_nil db_session.tenant_id
  end

  test "franchise owner of organization without points logs in under production guard" do
    org = create_organization!
    user = user_without_tenant!("franchise_manager")
    user.update_column(:organization_id, org.id)

    with_rails_env("production") do
      post "/login", params: { email: user.email, password: "pass123" }
    end

    assert_response :redirect
    assert_equal user.id.to_s, session[:user_id].to_s
  end

  test "logout without tenant does not raise" do
    user = user_without_tenant!("ук_global_admin")
    post "/login", params: { email: user.email, password: "pass123" }

    with_rails_env("production") do
      delete "/logout"
    end

    assert_response :redirect
  end
end
