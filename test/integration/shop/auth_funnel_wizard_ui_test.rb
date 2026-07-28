# frozen_string_literal: true

require "test_helper"

# Auth funnel cascade Шаг 1: checkout auth = phone wizard, без Email/radio.
class Shop::AuthFunnelWizardUiTest < ActionDispatch::IntegrationTest
  test "checkout auth screen has phone wizard continue and no email radios" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    wizard = File.read(Rails.root.join("app/frontend/components/PhoneAuthWizard.svelte"))
    lib = File.read(Rails.root.join("app/frontend/lib/phoneAuthWizard.js"))

    assert_includes checkout, "PhoneAuthWizard"
    refute_includes checkout, 'type="email"'
    refute_includes checkout, 'type="radio"'
    refute_includes checkout, "phoneChannel"
    refute_includes checkout, "Подтвердить телефон"
    refute_includes checkout, "Подтвердить email"

    assert_includes wizard, "Продолжить"
    assert_includes wizard, "autofocus"
    assert_includes wizard, 'data-testid="phone-auth-wizard"'
    assert_includes wizard, 'data-testid="phone-auth-screen-1"'
    assert_includes wizard, 'data-testid="phone-auth-continue"'

    assert_includes lib, "flash_call"
    assert_includes lib, "canContinuePhone"
    assert_includes lib, "buildFlashCallSendBody"
  end
end
