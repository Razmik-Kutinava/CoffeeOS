# frozen_string_literal: true

require "test_helper"

# Веха 1 / блок C: session-login для всех панелей (barista, manager, prep_kitchen, platform/УК).
class Auth::PanelLoginTest < ActionDispatch::IntegrationTest
  PANEL_ROOTS = [
    [ :barista, :barista_dashboard_path ],
    [ :manager, :manager_dashboard_path ],
    [ :prep_kitchen, :prep_kitchen_dashboard_path ],
    [ :platform, :platform_root_path ]
  ].freeze

  setup do
    @rack_attack_was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false

    @org = create_organization!(slug: "auth-org-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(organization: @org, name: "Auth A", slug: "auth-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(organization: @org, name: "Auth B", slug: "auth-b-#{SecureRandom.hex(3)}")
    @kitchen_tenant = create_tenant!(organization: @org, name: "Auth Kitchen", slug: "auth-k-#{SecureRandom.hex(3)}")
  end

  teardown do
    Rack::Attack.enabled = @rack_attack_was_enabled
  end

  test "unauthenticated access to each panel root redirects to login" do
    PANEL_ROOTS.each do |_name, path_helper|
      get send(path_helper)
      assert_redirected_to login_path, "ожидался редирект на login для #{path_helper}"
    end
  end

  test "login barista sets session and opens barista dashboard" do
    user = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "auth-bar-#{SecureRandom.hex(3)}@test.local")

    assert_login_redirects_to!(user, barista_dashboard_path, role_code: "barista")
    get barista_new_order_path
    assert_response :success
  end

  test "login shift_manager sets session and opens manager dashboard" do
    user = create_user!(tenant: @tenant_a, role_codes: %w[shift_manager], email: "auth-sm-#{SecureRandom.hex(3)}@test.local")

    assert_login_redirects_to!(user, manager_dashboard_path, role_code: "shift_manager")
    get manager_orders_path
    assert_response :success
  end

  test "login general_manager sets session and opens manager dashboard" do
    user = create_user!(tenant: @tenant_a, role_codes: %w[general_manager], email: "auth-gm-#{SecureRandom.hex(3)}@test.local")

    assert_login_redirects_to!(user, manager_dashboard_path, role_code: "general_manager")
    get manager_menu_path
    assert_response :success
  end

  test "login franchise_manager sets session tenant context and opens manager dashboard" do
    user = create_user!(
      tenant: @tenant_a,
      organization: @org,
      role_codes: %w[franchise_manager],
      email: "auth-fm-#{SecureRandom.hex(3)}@test.local"
    )

    assert_login_redirects_to!(user, manager_dashboard_path, role_code: "franchise_manager")
    assert session[:manager_tenant_id].present?, "franchise_manager должен получить manager_tenant_id"
    assert_includes [ @tenant_a.id.to_s, @tenant_b.id.to_s ], session[:manager_tenant_id].to_s
    get manager_dashboard_path
    assert_response :success
  end

  test "login prep_kitchen_manager sets session and opens prep kitchen dashboard" do
    user = create_user!(
      tenant: @kitchen_tenant,
      role_codes: %w[prep_kitchen_manager],
      email: "auth-pkm-#{SecureRandom.hex(3)}@test.local"
    )

    assert_login_redirects_to!(user, prep_kitchen_dashboard_path, role_code: "prep_kitchen_manager")
    get prep_kitchen_movements_path
    assert_response :success
  end

  test "login prep_kitchen_worker sets session and opens prep kitchen dashboard" do
    user = create_user!(
      tenant: @kitchen_tenant,
      role_codes: %w[prep_kitchen_worker],
      email: "auth-pkw-#{SecureRandom.hex(3)}@test.local"
    )

    assert_login_redirects_to!(user, prep_kitchen_dashboard_path, role_code: "prep_kitchen_worker")
    get prep_kitchen_inventory_path
    assert_response :success
  end

  test "login uk_global_admin sets session and opens platform admin" do
    user = create_uk_admin!(email: "auth-uk-#{SecureRandom.hex(3)}@test.local")

    assert_login_redirects_to!(user, platform_root_path, role_code: "ук_global_admin")
    get platform_menu_path
    assert_response :success
  end

  test "login accepts nested user params like login form" do
    user = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "auth-nested-#{SecureRandom.hex(3)}@test.local")

    post "/login", params: { user: { email: user.email, password: "pass123" } }
    assert_redirected_to barista_dashboard_path
    assert_equal user.id, session[:user_id]
  end

  test "login without roles is denied and does not set session" do
    user = User.create!(
      tenant: @tenant_a,
      name: "No Roles",
      email: "auth-noroles-#{SecureRandom.hex(3)}@test.local",
      status: "active",
      password: "pass123"
    )

    post "/login", params: { email: user.email, password: "pass123" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_match "нет назначенных ролей", flash.now[:alert].to_s
  end

  test "logout from barista clears session and blocks dashboard" do
    user = create_user!(tenant: @tenant_a, role_codes: %w[barista], email: "auth-logout-#{SecureRandom.hex(3)}@test.local")
    login_as!(user)

    delete logout_path
    assert_redirected_to login_path
    assert_nil session[:user_id]

    get barista_dashboard_path
    assert_redirected_to login_path
  end

  private

  def assert_login_redirects_to!(user, expected_path, role_code:, password: "pass123")
    post "/login", params: { email: user.email, password: password }
    assert_redirected_to expected_path, "ожидался редирект после логина #{role_code}"
    assert_equal user.id, session[:user_id]
    assert_equal user.tenant_id.to_s, session[:tenant_id].to_s
    assert_equal role_code, session[:role_code]

    follow_redirect!
    assert_response :success
  end
end
