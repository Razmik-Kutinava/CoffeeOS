# frozen_string_literal: true

require "test_helper"

class PrepKitchenLogoutTest < ActionDispatch::IntegrationTest
  WORKER_PATHS = %w[
    /prep_kitchen
    /prep_kitchen/queue
    /prep_kitchen/inventory
    /prep_kitchen/movements
    /prep_kitchen/stop_list
  ].freeze

  MANAGER_ONLY_PATHS = %w[
    /prep_kitchen/recipes
    /prep_kitchen/incidents
    /prep_kitchen/reports
  ].freeze

  PREP_KITCHEN_PATHS = (WORKER_PATHS + MANAGER_ONLY_PATHS).freeze

  def assert_logout_present!(paths)
    paths.each do |path|
      get path
      assert_response :success, "expected success for #{path}"
      assert_includes response.body, "Выйти", "expected logout control on #{path}"
    end
  end

  test "prep_kitchen_worker sees logout button and can logout" do
    tenant = create_prep_kitchen_tenant!(name: "Logout Kitchen Worker", slug: "logout-kw-#{SecureRandom.hex(4)}")
    worker = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_worker], email: "logout-kw@test.com", name: "LogoutWorker")

    login_as!(worker)
    assert_logout_present!(WORKER_PATHS)

    delete "/logout"
    assert_response :redirect

    get "/prep_kitchen"
    assert_response :redirect
    assert_includes response.headers["Location"].to_s, "/login"
  end

  test "prep_kitchen_manager sees logout button and can logout" do
    tenant = create_prep_kitchen_tenant!(name: "Logout Kitchen Manager", slug: "logout-km-#{SecureRandom.hex(4)}")
    manager = create_user!(tenant: tenant, role_codes: %w[prep_kitchen_manager], email: "logout-km@test.com", name: "LogoutManager")

    login_as!(manager)
    assert_logout_present!(PREP_KITCHEN_PATHS)

    delete "/logout"
    assert_response :redirect

    get "/prep_kitchen"
    assert_response :redirect
    assert_includes response.headers["Location"].to_s, "/login"
  end
end
