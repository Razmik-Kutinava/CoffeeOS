# frozen_string_literal: true

require "test_helper"

class Platform::TenantsMapPinsTest < ActiveSupport::TestCase
  include TestFactories

  def url_helper
    @url_helper ||= Class.new do
      include Rails.application.routes.url_helpers
    end.new
  end

  test "build includes only sales points with coordinates" do
    org = create_organization!
    with_coords = create_tenant!(
      organization: org,
      slug: "map-pin-a-#{SecureRandom.hex(3)}",
      city: "Москва",
      address: "ул. А, 1",
      latitude: 55.75,
      longitude: 37.62
    )
    without_coords = create_tenant!(
      organization: org,
      slug: "map-pin-b-#{SecureRandom.hex(3)}",
      city: "Москва",
      address: "ул. Б, 2"
    )
    kitchen = Tenant.create!(
      organization: org,
      name: "Kitchen",
      slug: "map-kitchen-#{SecureRandom.hex(3)}",
      type: "production_kitchen",
      status: "active",
      currency: "RUB",
      country: "RU",
      timezone: "Europe/Moscow",
      latitude: 55.76,
      longitude: 37.63
    )

    pins = Platform::TenantsMapPins.build([ with_coords, without_coords, kitchen ], url_helpers: url_helper)

    assert_equal 1, pins.size
    assert_equal with_coords.id.to_s, pins.first[:id]
    assert_in_delta 55.75, pins.first[:lat], 0.001
    assert_equal "/admin/tenants/#{with_coords.id}", pins.first[:card_url]
  end
end
