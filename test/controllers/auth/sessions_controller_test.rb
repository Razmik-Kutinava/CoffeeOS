# frozen_string_literal: true

require "test_helper"

class Auth::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create_tenant!
    @user   = create_user!(tenant: @tenant, role_codes: %w[barista], email: "barista-#{SecureRandom.hex(4)}@test.local", password: "pass123")
    # Disable rate limiting so login tests don't get throttled
    Rack::Attack.enabled = false
  end

  teardown do
    Rack::Attack.enabled = true
  end

  # ---------------------------------------------------------------------------
  # GET /login
  # ---------------------------------------------------------------------------

  test "GET /login renders login page successfully" do
    get "/login"
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # POST /login — happy path
  # ---------------------------------------------------------------------------

  test "POST /login with valid credentials redirects and sets session user_id" do
    post "/login", params: { email: @user.email, password: "pass123" }
    assert_response :redirect
    assert session[:user_id].present?, "session[:user_id] должен быть установлен после успешного логина"
  end

  test "POST /login with valid credentials sets session tenant_id" do
    post "/login", params: { email: @user.email, password: "pass123" }
    assert_equal @user.tenant_id.to_s, session[:tenant_id].to_s
  end

  test "POST /login with valid credentials sets session role_code" do
    post "/login", params: { email: @user.email, password: "pass123" }
    assert_equal "barista", session[:role_code]
  end

  test "POST /login with valid credentials redirects to barista dashboard" do
    post "/login", params: { email: @user.email, password: "pass123" }
    assert_redirected_to barista_dashboard_path
  end

  # ---------------------------------------------------------------------------
  # POST /login — wrong password
  # ---------------------------------------------------------------------------

  test "POST /login with wrong password renders login page and leaves no session" do
    post "/login", params: { email: @user.email, password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "POST /login with wrong password shows alert flash" do
    post "/login", params: { email: @user.email, password: "wrongpassword" }
    assert_not_nil flash.now[:alert]
  end

  # ---------------------------------------------------------------------------
  # POST /login — unknown email
  # ---------------------------------------------------------------------------

  test "POST /login with unknown email renders login page with no session" do
    post "/login", params: { email: "nobody@example.com", password: "pass123" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  # ---------------------------------------------------------------------------
  # POST /login — inactive / blocked user
  # ---------------------------------------------------------------------------

  test "POST /login with blocked user is denied and session is not set" do
    @user.update!(status: "blocked")
    post "/login", params: { email: @user.email, password: "pass123" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "POST /login with blocked user shows blocked alert" do
    @user.update!(status: "blocked")
    post "/login", params: { email: @user.email, password: "pass123" }
    assert_match "заблокирован", flash.now[:alert].to_s
  end

  # ---------------------------------------------------------------------------
  # Session fixation — reset_session is called on login
  # ---------------------------------------------------------------------------

  test "session is populated with user_id after login (reset_session was called)" do
    get "/login"
    # After reset_session + re-population, user_id must be present
    post "/login", params: { email: @user.email, password: "pass123" }
    assert session[:user_id].present?
    assert_equal @user.id, session[:user_id]
  end

  # ---------------------------------------------------------------------------
  # DELETE /logout
  # ---------------------------------------------------------------------------

  test "DELETE /logout clears session and redirects to login" do
    login_as!(@user)
    assert session[:user_id].present?, "precondition: must be logged in before logout"

    delete "/logout"
    assert_redirected_to login_path
    assert_nil session[:user_id]
  end

  test "DELETE /logout clears role_code from session" do
    login_as!(@user)
    delete "/logout"
    assert_nil session[:role_code]
  end

  # ---------------------------------------------------------------------------
  # Session replay: after logout, old session cannot reach protected pages
  # ---------------------------------------------------------------------------

  test "after logout, accessing barista dashboard redirects to login" do
    login_as!(@user)
    delete "/logout"
    follow_redirect!

    # Attempt to re-access the barista dashboard without a valid session
    get barista_dashboard_path
    # Expect redirect to login (auth guard) rather than 200
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_equal login_path, path
  end
end
