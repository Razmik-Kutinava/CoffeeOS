# frozen_string_literal: true

require "test_helper"

class Shop::PwaManifestTest < ActionDispatch::IntegrationTest
  include TestFactories
  test "manifest.webmanifest returns install metadata" do
    get "/shop/manifest.webmanifest", as: :json
    assert_response :success
    assert_includes response.content_type, "manifest"

    body = JSON.parse(response.body)
    assert_equal "CoffeeOS", body["name"]
    assert_equal "standalone", body["display"]
    assert_equal "/shop", body["scope"]
    assert_equal "#ff8c42", body["theme_color"]
    assert body["icons"].any? { |i| i["sizes"] == "192x192" }
    assert body["icons"].any? { |i| i["sizes"] == "512x512" }
  end

  test "service worker is served for shop scope" do
    get "/shop/service-worker.js"
    assert_response :success
    assert_includes response.content_type, "javascript"
    assert_match(/coffeeos-shop-shell/, response.body)
  end

  test "shop layout links manifest" do
    tenant = create_tenant!
    get "/shop?tenant_id=#{tenant.id}"
    assert_response :success
    assert_match %r{rel="manifest" href="/shop/manifest\.webmanifest}, response.body
    assert_match %r{apple-touch-icon}, response.body
  end
end
