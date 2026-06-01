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
