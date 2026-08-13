# frozen_string_literal: true

require "test_helper"

class Shop::Api::B114TenantAddressApiTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!
    @org_alt = create_organization!(slug: "b114-alt-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(
      name: "Point A",
      slug: "b114-a-#{SecureRandom.hex(3)}",
      organization: @org,
      city: "Москва",
      address: "ул. Ленина, 10",
      latitude: 55.7558,
      longitude: 37.6173
    )
    @tenant_b = create_tenant!(
      name: "Point B",
      slug: "b114-b-#{SecureRandom.hex(3)}",
      organization: @org,
      city: "Москва",
      address: "ул. Пушкина, 5",
      latitude: 55.7619,
      longitude: 37.6056
    )
    @tenant_c = create_tenant!(
      name: "Point C",
      slug: "b114-c-#{SecureRandom.hex(3)}",
      organization: @org_alt,
      city: "Москва",
      address: "ул. Тверская, 12",
      latitude: 55.7568,
      longitude: 37.6158
    )
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

  test "GET tenants lists same-city points for guest ordered by proximity" do
    get "/shop/api/tenants", headers: { "X-Shop-Tenant" => @tenant_a.id.to_s }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal true, json["switchable"]
    assert_equal 3, json["tenants"].size
    ids = json["tenants"].map { |t| t["id"] }
    assert_equal [ @tenant_a.id, @tenant_c.id, @tenant_b.id ], ids
    assert json["tenants"].first["is_current"]
    assert_nil json["last_ordered_tenant_id"]
  end

  private
end
