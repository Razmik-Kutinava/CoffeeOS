# frozen_string_literal: true

require "test_helper"

class Shop::Api::ConfigControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
  end

  test "GET /shop/api/config returns payment flags" do
    get "/shop/api/config", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "simulate"
    assert_includes json.keys, "iframe"
    assert_includes json.keys, "integration_script_url"
    assert_includes json.keys, "operating_hours"
    assert_includes json.keys, "tenant"
    assert json.dig("operating_hours", "is_open").in?([ true, false ])
    assert json.dig("tenant", "display_address").present?
  end
end
