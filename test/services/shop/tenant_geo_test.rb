# frozen_string_literal: true

require "test_helper"

class Shop::TenantGeoTest < ActiveSupport::TestCase
  test "normalize_city strips and folds ё" do
    assert_equal "москва", Shop::TenantGeo.normalize_city("  Москва ")
    assert_equal "орел", Shop::TenantGeo.normalize_city("Орёл")
  end

  test "haversine returns zero for same point" do
    km = Shop::TenantGeo.haversine_km(55.75, 37.62, 55.75, 37.62)
    assert_in_delta 0.0, km, 0.001
  end

  test "distance_km nil when coordinates missing" do
    a = Tenant.new(latitude: 55.75, longitude: 37.62)
    b = Tenant.new(latitude: nil, longitude: 37.62)
    assert_nil Shop::TenantGeo.distance_km(a, b)
  end
end
