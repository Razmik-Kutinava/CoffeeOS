# frozen_string_literal: true

require "test_helper"

# #66: Telegram In-App Browser / WebView — structural gates (not bot).
class Shop::ShopTelegramWebviewTest < ActiveSupport::TestCase
  test "shop layout viewport-fit cover for Telegram WebView chrome" do
    layout = File.read(Rails.root.join("app/views/layouts/shop.html.erb"))
    assert_match(/viewport-fit=cover/, layout)
    assert_includes layout, "csp_meta_tag"
    assert_includes layout, 'id="shop-boot-watchdog"'
  end

  test "App installs isolated WebView compatibility layer" do
    app = File.read(Rails.root.join("app/frontend/App.svelte"))
    assert_includes app, "installShopWebViewCompat"
    refute_match(/telegram\.org/, app)
  end

  test "compatibility module is isolated from Telegram Bot" do
    path = Rails.root.join("app/frontend/lib/shopWebView.js")
    assert path.exist?, "expected shopWebView.js compatibility layer"
    src = File.read(path)
    refute_match(/TELEGRAM_BOT_TOKEN/, src)
    refute_match(/sendMessage/, src)
    assert_includes src, "isTelegramInAppBrowser"
  end

  test "CSP keeps connect-src self and does not add telegram.org" do
    src = File.read(Rails.root.join("config/initializers/content_security_policy.rb"))
    assert_match(/connect_src/, src)
    refute_match(/telegram\.org/, src)
    frame = File.read(Rails.root.join("app/views/layouts/shop.html.erb"))
    assert_includes frame, "csp_meta_tag"
  end

  test "shop-api documents Telegram WebView runtime contract" do
    src = File.read(Rails.root.join("docs/integrations/shop-api.md"))
    assert_match(/WebView runtime/i, src)
    assert_match(/same-origin/, src)
  end

  test "App installs WebView layout layer" do
    app = File.read(Rails.root.join("app/frontend/App.svelte"))
    assert_includes app, "installShopWebViewLayout"
  end

  test "CartSheet height uses visual viewport px helper" do
    src = File.read(Rails.root.join("app/frontend/components/CartSheet.svelte"))
    assert_includes src, "shopWebViewLayout"
    assert_includes src, "sheetHeightPx"
  end

  test "shop-api documents Telegram WebView UI contract" do
    src = File.read(Rails.root.join("docs/integrations/shop-api.md"))
    assert_match(/WebView UI/i, src)
  end
end
