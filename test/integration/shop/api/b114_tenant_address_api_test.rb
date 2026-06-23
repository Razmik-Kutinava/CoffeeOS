# frozen_string_literal: true

require "test_helper"

class Shop::Api::B114TenantAddressApiTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!
    @tenant_a = create_tenant!(name: "Point A", slug: "b114-a-#{SecureRandom.hex(3)}", organization: @org)
    @tenant_b = create_tenant!(name: "Point B", slug: "b114-b-#{SecureRandom.hex(3)}", organization: @org)
    @tenant_a.update!(city: "Москва", address: "ул. Ленина, 10")
    @tenant_b.update!(city: "Москва", address: "ул. Пушкина, 5")
    @customer = create_mobile_customer!(email: "b114-#{SecureRandom.hex(4)}@example.com")
  end

  test "GET config exposes tenant address block" do
    get "/shop/api/config", headers: { "X-Shop-Tenant" => @tenant_a.id.to_s }
    assert_response :success

    json = JSON.parse(response.body)
    tenant = json.fetch("tenant")
    assert_equal @tenant_a.id.to_s, tenant["id"]
    assert_equal "Москва", tenant["city"]
    assert_equal "ул. Ленина, 10", tenant["address"]
    assert_equal "Москва, ул. Ленина, 10", tenant["display_address"]
    assert_nil json["last_ordered_tenant_id"]
  end

  test "GET config uses address stub when fields empty" do
    @tenant_a.update!(city: nil, address: nil)
    get "/shop/api/config", headers: { "X-Shop-Tenant" => @tenant_a.id.to_s }
    assert_response :success

    tenant = JSON.parse(response.body).fetch("tenant")
    assert_equal "Адрес не указан", tenant["display_address"]
  end

  test "GET tenants for guest returns current tenant only" do
    get "/shop/api/tenants", headers: { "X-Shop-Tenant" => @tenant_a.id.to_s }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal false, json["switchable"]
    assert_equal 1, json["tenants"].size
    assert_equal "Москва, ул. Ленина, 10", json["tenants"].first["display_address"]
    assert_nil json["last_ordered_tenant_id"]
  end

  private
end
