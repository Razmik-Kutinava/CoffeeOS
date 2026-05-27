# frozen_string_literal: true

require "test_helper"

# В2 CHECKLIST §B — feature flags отключают доступ к панели.
class Barista::FeatureFlagsTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant  = create_tenant!(name: "FF Point", slug: "ff-barista-#{SecureRandom.hex(3)}")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "ff-barista@test.local", name: "FF")
    TenantModuleFlags.sync!(@tenant, { "barista" => "1" })
  end

  test "barista can access dashboard when module enabled" do
    login_as!(@barista)
    get "/barista"
    assert_response :success
  end

  test "barista is redirected when barista module disabled" do
    TenantModuleFlags.sync!(@tenant, { "barista" => "0" })

    login_as!(@barista)
    get "/barista"
    assert_response :redirect
    assert_redirected_to root_path
  end
end
