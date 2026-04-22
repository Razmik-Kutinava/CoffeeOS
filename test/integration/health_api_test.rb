# frozen_string_literal: true

require "test_helper"

class HealthApiTest < ActionDispatch::IntegrationTest
  test "GET /health/tenants returns JSON with tenants" do
    admin = create_uk_admin!(email: "health-admin@test.local")
    tenant = create_tenant!(name: "Health Point", slug: "health-point")
    login_as!(admin)
    get "/health/tenants"
    assert_response :success
    assert_equal "application/json", response.media_type
    data = response.parsed_body
    assert data.key?("tenants")
    assert data.key?("generated_at")
    tenant_data = data["tenants"].find { |t| t["id"] == tenant.id }
    assert tenant_data, "tenant should be in response"
    assert tenant_data.key?("checks")
  end

  test "GET /health/tenants/:id returns JSON for single tenant" do
    admin = create_uk_admin!(email: "health-admin2@test.local")
    tenant = create_tenant!(name: "Single Point", slug: "single-point")
    login_as!(admin)
    get "/health/tenants/#{tenant.id}"
    assert_response :success
    data = response.parsed_body
    assert_equal tenant.id, data.dig("tenant", "id")
    assert data.key?("checks")
    assert data.key?("overall")
  end
end
