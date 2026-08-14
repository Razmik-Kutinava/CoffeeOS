# frozen_string_literal: true

require "test_helper"

# #64: /shop bootstrap — skeleton + classic watchdog (не type=module).
class Shop::ShopBootSkeletonTest < ActiveSupport::TestCase
  test "shop layout has classic boot watchdog; home has skeleton" do
    layout = File.read(Rails.root.join("app/views/layouts/shop.html.erb"))
    home = File.read(Rails.root.join("app/views/shop/pages/home.html.erb"))
    assert_includes home, "shop-boot-skeleton"
    assert_includes home, "Загрузка меню"
    assert_includes layout, 'id="shop-boot-watchdog"'
    refute_match(/id="shop-boot-watchdog"[^>]*\btype=["']module["']/, layout)
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
