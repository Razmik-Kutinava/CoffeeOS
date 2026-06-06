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

  test "uk admin gets session json with user_id" do
    login_as!(@uk)
    get platform_session_path
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal @uk.id, data["user_id"]
    assert_equal @uk.email, data["email"]
    assert data.key?("role_code")
    assert data.key?("logged_in_at")
  end
end
