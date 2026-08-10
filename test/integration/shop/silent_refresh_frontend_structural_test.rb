# frozen_string_literal: true

require "test_helper"

# Шаг 5 (structural): фронт вызывает silent refresh и хранит shop_refresh_token.
class Shop::SilentRefreshFrontendStructuralTest < ActiveSupport::TestCase
  test "restoreGuestSession uses silentRefreshSession helper" do
    src = File.read(Rails.root.join("app/frontend/lib/restoreGuestSession.js"))
    assert_includes src, "silentRefreshSession"
  end

  test "silentRefreshSession posts to session refresh endpoint" do
    src = File.read(Rails.root.join("app/frontend/lib/silentRefreshSession.js"))
    assert_includes src, "/session/refresh"
    assert_includes src, "shop_refresh_token"
  end

  test "shopLocalStorage exports refresh token helpers without 24h hard burn default" do
    src = File.read(Rails.root.join("app/frontend/lib/shopLocalStorage.js"))
    assert_includes src, "shop_refresh_token"
    assert_includes src, "saveShopRefreshToken"
    assert_includes src, "loadShopRefreshToken"
    assert_includes src, "clearShopRefreshToken"
    refute_match(/Date\.now\(\)\s*-\s*savedAt\s*>\s*ttlMs/, src)
  end

  test "Checkout saves refresh token after phone OTP verify" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    assert_includes checkout, "saveShopRefreshToken"
    assert_match(/onWizardVerified\(\{\s*refreshToken/, checkout)
    assert_match(/if \(refreshToken\) saveShopRefreshToken\(refreshToken\)/, checkout)

    code_step = File.read(Rails.root.join("app/frontend/components/PhoneAuthCodeStep.svelte"))
    assert_includes code_step, "refresh_token"
    assert_match(/refreshToken:\s*res\?\.refresh_token/, code_step)
  end
end
