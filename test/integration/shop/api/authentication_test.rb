# frozen_string_literal: true

require "test_helper"

class Shop::Api::AuthenticationTest < ActionDispatch::IntegrationTest
  class FakeController < ApplicationController
    include Shop::Api::Auth

    attr_accessor :rendered

    def render(json:, status:)
      @rendered = { json: json, status: status }
    end
  end

  setup do
    @controller = FakeController.new
    @controller.request = ActionDispatch::TestRequest.create
    @controller.response = ActionDispatch::TestResponse.new
    @old_key = ENV["SHOP_API_KEY"]
    @old_fallback = ENV["SHOP_API_KEY_FALLBACK"]
    ENV.delete("SHOP_API_KEY")
    ENV.delete("SHOP_API_KEY_FALLBACK")

    @tenant_a = create_tenant!(name: "Auth A", slug: "shop-auth-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(name: "Auth B", slug: "shop-auth-b-#{SecureRandom.hex(3)}")
    @raw_a = "sk_int_a_#{SecureRandom.hex(8)}"
    ShopApiKey.create!(
      tenant_id: @tenant_a.id,
      name: "int-a",
      token_digest: ShopApiKey.digest(@raw_a),
      token_prefix: @raw_a[0, 8],
      active: true,
      global_ops: false
    )
    Current.tenant_id = @tenant_a.id
  end

  teardown do
    ENV["SHOP_API_KEY"] = @old_key
    ENV["SHOP_API_KEY_FALLBACK"] = @old_fallback
    Current.tenant_id = nil
  end

  test "missing api key returns unauthorized" do
    @controller.send(:authenticate_shop_api!)
    assert_equal :unauthorized, @controller.rendered[:status]
    assert_match(/авторизац/i, @controller.rendered[:json][:error].to_s)
  end

  test "invalid api key returns unauthorized" do
    @controller.request.headers["X-Shop-Api-Key"] = "wrong"
    @controller.send(:authenticate_shop_api!)
    assert_equal :unauthorized, @controller.rendered[:status]
  end

  test "valid tenant key for matching tenant passes" do
    @controller.request.headers["X-Shop-Api-Key"] = @raw_a
    Current.tenant_id = @tenant_a.id
    @controller.send(:authenticate_shop_api!)
    assert_nil @controller.rendered
  end

  test "valid tenant key for other tenant returns unauthorized" do
    @controller.request.headers["X-Shop-Api-Key"] = @raw_a
    Current.tenant_id = @tenant_b.id
    @controller.send(:authenticate_shop_api!)
    assert_equal :unauthorized, @controller.rendered[:status]
  end

  test "query api_key is rejected even when value is valid" do
    @controller.request = ActionDispatch::TestRequest.create(
      "QUERY_STRING" => "api_key=#{@raw_a}"
    )
    @controller.response = ActionDispatch::TestResponse.new
    Current.tenant_id = @tenant_a.id
    @controller.send(:authenticate_shop_api!)
    assert_equal :unauthorized, @controller.rendered[:status]
  end

  test "browser shop session with valid csrf and referer passes without api key" do
    token = @controller.send(:form_authenticity_token)
    @controller.request.headers["X-CSRF-Token"] = token
    @controller.request.headers["HTTP_REFERER"] = "#{@controller.request.base_url}/shop?tenant_id=abc"
    @controller.send(:authenticate_shop_api!)
    assert_nil @controller.rendered
  end

  test "browser shop session with forged csrf token is rejected" do
    @controller.request.headers["X-CSRF-Token"] = "forged-token"
    @controller.request.headers["HTTP_REFERER"] = "#{@controller.request.base_url}/shop?tenant_id=abc"
    @controller.send(:authenticate_shop_api!)
    assert_equal :unauthorized, @controller.rendered[:status]
  end

  test "browser shop session without referer is rejected" do
    token = @controller.send(:form_authenticity_token)
    @controller.request.headers["X-CSRF-Token"] = token
    @controller.send(:authenticate_shop_api!)
    assert_equal :unauthorized, @controller.rendered[:status]
  end
end
