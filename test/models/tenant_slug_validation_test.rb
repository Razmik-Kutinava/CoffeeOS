# frozen_string_literal: true

require "test_helper"

class TenantSlugValidationTest < ActiveSupport::TestCase
  include TestFactories

  test "rejects reserved slug admin" do
    tenant = Tenant.new(
      organization: create_organization!,
      name: "Bad",
      slug: "admin",
      type: "sales_point",
      status: "active",
      country: "RU",
      currency: "RUB"
    )

    assert_not tenant.valid?
    assert_includes tenant.errors[:slug].join, "зарезервирован"
  end

  test "accepts normal slug" do
    tenant = Tenant.new(
      organization: create_organization!,
      name: "OK",
      slug: "cafe-arbat-#{SecureRandom.hex(2)}",
      type: "sales_point",
      status: "active",
      country: "RU",
      currency: "RUB"
    )

    assert tenant.valid?, tenant.errors.full_messages.to_sentence
  end
end
