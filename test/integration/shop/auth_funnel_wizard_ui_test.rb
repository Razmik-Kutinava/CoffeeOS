# frozen_string_literal: true

require "test_helper"

# Auth funnel cascade: checkout phone wizard Screens 1–2.
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

  test "screen 2 has four pin cells auto-verify and change number without confirm button" do
    wizard = File.read(Rails.root.join("app/frontend/components/PhoneAuthWizard.svelte"))
    lib = File.read(Rails.root.join("app/frontend/lib/phoneAuthWizard.js"))

    assert_includes wizard, 'data-testid="phone-auth-screen-2"'
    assert_includes wizard, 'data-testid="phone-auth-pin"'
    assert_includes wizard, 'data-testid="phone-auth-change-number"'
    assert_includes wizard, "Изменить номер"
    assert_includes wizard, "phone_otp/verify"
    assert_includes wizard, "shouldAutoSubmitPin"
    assert_includes wizard, "phone-auth-pin-"
    assert_includes wizard, 'maxlength="1"'
    assert_includes wizard, "{#each pinIndexes"
    refute_includes wizard, "Подтвердить код"
    refute_includes wizard, "Подтвердить телефон"

    assert_includes lib, "shouldAutoSubmitPin"
    assert_includes lib, "buildVerifyBody"
    assert_includes lib, "PIN_LENGTH"
    assert_match(/PIN_LENGTH\s*=\s*4/, lib)
  end
end
