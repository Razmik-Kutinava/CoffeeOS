# frozen_string_literal: true

require "test_helper"

class Platform::SessionControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    org = create_organization!
    anchor = create_tenant!(organization: org, slug: "sess-anchor-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: anchor,
      organization: org,
      role_codes: %w[ук_global_admin],
      email: "uk-sess-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
  end

  test "redirects guest to login" do
    get platform_session_path
    assert_redirected_to login_path
  end

  test "uk admin gets session html page" do
    login_as!(@uk)
    get platform_session_path
    assert_response :success
    assert_equal "text/html", response.media_type
    assert_includes response.body, "Моя сессия"
    assert_includes response.body, @uk.email
    assert_includes response.body, "JSON"
  end

  test "uk admin gets session json via format" do
    login_as!(@uk)
    get platform_session_path(format: :json)
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal @uk.id, data["user_id"]
  end
end
