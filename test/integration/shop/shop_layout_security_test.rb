# frozen_string_literal: true

require "test_helper"

class Shop::LayoutSecurityTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "shop-sec-#{SecureRandom.hex(3)}")
  end

  test "shop layout does not expose shop-api-key meta" do
    get "/shop?tenant_id=#{@tenant.id}"
    assert_response :success
    assert_no_match(/shop-api-key/, response.body)
  end
end
