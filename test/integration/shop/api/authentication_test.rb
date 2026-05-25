# frozen_string_literal: true

require "test_helper"

class Shop::Api::AuthenticationTest < ActiveSupport::TestCase
  class FakeController < ActionController::Base
    include Shop::Api::Auth

    attr_accessor :rendered

    def render(json:, status:)
      @rendered = { json: json, status: status }
    end
  end

  setup do
    @controller = FakeController.new
    @controller.request = ActionDispatch::TestRequest.create
    @old_key = ENV["SHOP_API_KEY"]
    ENV["SHOP_API_KEY"] = "test-shop-api-key"
  end

  teardown do
    ENV["SHOP_API_KEY"] = @old_key
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

  test "valid api key passes" do
    @controller.request.headers["X-Shop-Api-Key"] = "test-shop-api-key"
    @controller.send(:authenticate_shop_api!)
    assert_nil @controller.rendered
  end

  test "browser shop session with csrf and referer passes without api key" do
    @controller.request.headers["X-CSRF-Token"] = "tok"
    @controller.request.headers["HTTP_REFERER"] = "http://example.com/shop?tenant_id=abc"
    @controller.request.host = "example.com"
    @controller.send(:authenticate_shop_api!)
    assert_nil @controller.rendered
  end
end
