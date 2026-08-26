# frozen_string_literal: true

require "test_helper"

# #69 PWA ЛК — grep/API contract
class Shop::PwaPersonalAccountLkTest < ActiveSupport::TestCase
  test "LK hub Profile.svelte has history PLG and settings entry" do
    src = File.read(Rails.root.join("app/frontend/routes/Profile.svelte"))
    assert_includes src, "shop-lk-home"
    assert_includes src, "PlgBlockSection"
    assert_includes src, "fetchAccountOrderHistory"
    assert_includes src, "/profile/settings"
    assert_includes src, "повторить"
    assert_includes src, "shop-lk-history-error"
  end

  test "AccountSettings has contacts notifications about write-us logout" do
    src = File.read(Rails.root.join("app/frontend/routes/AccountSettings.svelte"))
    link = File.read(Rails.root.join("app/frontend/lib/shopProfileLink.js"))
    assert_includes src, "email_verified"
    assert_includes src, "phone_verified"
    assert_includes link, "link_email"
    assert_includes src, "shop-notifications-toggle"
    assert_includes src, "ContactSupportSheet"
    assert_includes src, "shop-logout"
    assert_includes src, "/about"
    assert_match(/Подтвердить/i, src)
  end

  test "AboutUs and OrderReceipt use config and OFD placeholder without OFD API" do
    about = File.read(Rails.root.join("app/frontend/routes/AboutUs.svelte"))
    receipt = File.read(Rails.root.join("app/frontend/routes/OrderReceipt.svelte"))
    config = File.read(Rails.root.join("app/frontend/lib/shopAboutConfig.js"))
    assert_includes about, "shopAboutLegalLinks"
    assert_includes about, "shop-about-copy"
    assert_includes receipt, "shop-order-ofd-placeholder"
    assert_includes receipt, "shop-order-repeat-stub"
    refute_match(/api\([^)]*ofd/i, receipt)
    assert_includes config, "VITE_SHOP_LEGAL_PRIVACY_URL"
  end

  test "App.svelte registers LK routes" do
    src = File.read(Rails.root.join("app/frontend/App.svelte"))
    assert_includes src, "/profile/settings"
    assert_includes src, "/about"
    assert_includes src, "/order/:id/receipt"
  end

  test "orders history includes order_number and title fields" do
    src = File.read(Rails.root.join("app/controllers/shop/api/orders_controller.rb"))
    assert_includes src, "order_number:"
    assert_includes src, "title:"
  end

  test "DELETE shop/api/session clears customer session" do
    src = File.read(Rails.root.join("app/controllers/shop/api/session_controller.rb"))
    routes = File.read(Rails.root.join("config/routes.rb"))
    assert_includes src, "def destroy"
    assert_includes src, "CustomerSession.clear!"
    assert_includes src, "PendingOrderSession.clear!"
    assert_includes routes, 'delete "session"'
  end
end
