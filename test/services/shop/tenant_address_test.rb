# frozen_string_literal: true

require "test_helper"

class Shop::TenantAddressTest < ActiveSupport::TestCase
  test "display joins city and address" do
    assert_equal "Москва, ул. Ленина, 10", Shop::TenantAddress.display(city: "Москва", address: "ул. Ленина, 10")
  end

  test "display shows partial fields" do
    assert_equal "Москва", Shop::TenantAddress.display(city: "Москва", address: nil)
    assert_equal "ул. Пушкина, 5", Shop::TenantAddress.display(city: "", address: "ул. Пушкина, 5")
  end

  test "display stub when both empty" do
    assert_equal "Адрес не указан", Shop::TenantAddress.display(city: nil, address: nil)
  end
end
