# frozen_string_literal: true

require "test_helper"

# #64: /shop bootstrap — skeleton + classic watchdog (не type=module).
class Shop::ShopBootSkeletonTest < ActionDispatch::IntegrationTest
  include TestFactories

  test "GET /shop renders boot skeleton and classic watchdog script" do
    tenant = create_tenant!
    get "/shop?tenant_id=#{tenant.id}"
    assert_response :success
    assert_includes response.body, "shop-boot-skeleton"
    assert_includes response.body, "Загрузка меню"
    assert_includes response.body, 'id="shop-boot-watchdog"'
    refute_match(/id="shop-boot-watchdog"[^>]*\btype=["']module["']/, response.body)
  end

  test "application entrypoint catches mount failure" do
    src = File.read(Rails.root.join("app/frontend/entrypoints/application.js"))
    assert_includes src, "mount(App"
    assert_includes src, "shop-boot-error"
    assert_match(/\btry\b/, src)
  end

  test "Catalog error state has retry button" do
    src = File.read(Rails.root.join("app/frontend/routes/Catalog.svelte"))
    assert_includes src, "Не удалось загрузить меню"
    assert_includes src, "Повторить"
  end
end
