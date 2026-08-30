# frozen_string_literal: true

require "test_helper"

class PrepKitchen::FeatureFlagsTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(type: "production_kitchen", slug: "ff-prep-#{SecureRandom.hex(3)}")
    @manager = create_user!(
      tenant: @tenant,
      role_codes: %w[prep_kitchen_manager],
      email: "ff-prep-mgr@test.local"
    )
    TenantModuleFlags.sync!(@tenant, { "prep_kitchen" => "1" })
  end

  test "prep manager can access panel when module enabled" do
    login_as!(@manager)
    get "/prep_kitchen"
    assert_response :success
  end

  test "prep manager redirected when prep_kitchen module disabled" do
    TenantModuleFlags.sync!(@tenant, { "prep_kitchen" => "0" })

    login_as!(@manager)
    get "/prep_kitchen"
    assert_response :redirect
    assert_redirected_to root_path
  end
end
