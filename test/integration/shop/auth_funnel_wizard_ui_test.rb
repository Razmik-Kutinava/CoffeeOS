# frozen_string_literal: true

require "test_helper"

# Auth funnel: Callcheck primary → SMS fallback (no FlashCall /code/call).
class Shop::AuthFunnelWizardUiTest < ActionDispatch::IntegrationTest
  test "checkout auth screen has phone wizard continue and no email radios" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    wizard = File.read(Rails.root.join("app/frontend/components/PhoneAuthWizard.svelte"))
    lib = File.read(Rails.root.join("app/frontend/lib/phoneAuthWizard.js"))

    assert_includes checkout, "PhoneAuthWizard"
    refute_includes checkout, 'type="email"'
    refute_includes checkout, 'type="radio"'
    refute_includes checkout, "phoneChannel"

    assert_includes wizard, "Продолжить"
    assert_includes wizard, "autofocus"
    assert_includes wizard, 'data-testid="phone-auth-wizard"'
    assert_includes wizard, "init_callcheck"
    assert_includes wizard, "PhoneAuthCodeStep"

    assert_includes lib, "buildInitCallcheckBody"
    assert_includes lib, "canContinuePhone"
    refute_includes lib, 'channel: "flash_call"'
  end

  test "screen 2 callcheck has tel link and no pin until sms" do
    step = File.read(Rails.root.join("app/frontend/components/PhoneAuthCodeStep.svelte"))
    pin = File.read(Rails.root.join("app/frontend/components/PhoneAuthPinInputs.svelte"))
    lib = File.read(Rails.root.join("app/frontend/lib/phoneAuthWizard.js"))

    assert_includes step, 'data-testid="phone-auth-screen-2"'
    assert_includes step, 'data-testid="phone-auth-change-number"'
    assert_includes step, "check_status"
    assert_includes step, "phone_otp/verify_sms"
    assert_includes step, 'data-testid="phone-auth-tel-link"'
    refute_includes step, "Подтвердить код"

    assert_includes pin, 'data-testid="phone-auth-pin"'
    assert_includes lib, "shouldAutoSubmitPin"
    assert_includes lib, "buildVerifySmsBody"
  end

  test "callcheck cascade timeout 40s and poll 3s" do
    step = File.read(Rails.root.join("app/frontend/components/PhoneAuthCodeStep.svelte"))
    cascade = File.read(Rails.root.join("app/frontend/lib/phoneAuthCascade.js"))

    assert_includes step, 'data-testid="phone-auth-callcheck-timer"'
    assert_includes step, 'data-testid="phone-auth-callcheck-hint"'
    assert_includes step, "tickCallcheck"
    assert_includes step, "CALLCHECK_POLL_MS"

    assert_match(/CALLCHECK_TIMEOUT_SEC\s*=\s*40/, cascade)
    assert_match(/CALLCHECK_POLL_MS\s*=\s*3000/, cascade)
    assert_includes cascade, "Ждем ваш звонок"
    refute_includes cascade, "FLASH_WAIT_SEC"
    refute_includes step, "tickFlashCascade"
  end

  test "sms fallback button and timings" do
    step = File.read(Rails.root.join("app/frontend/components/PhoneAuthCodeStep.svelte"))
    cascade = File.read(Rails.root.join("app/frontend/lib/phoneAuthCascade.js"))
    lib = File.read(Rails.root.join("app/frontend/lib/phoneAuthWizard.js"))

    assert_includes step, 'data-testid="phone-auth-sms"'
    assert_includes step, "send_sms"
    assert_includes step, "SMS_BTN_LABEL"

    assert_match(/SMS_COOLDOWN_SEC\s*=\s*60/, cascade)
    assert_includes cascade, "Отправить код в СМС"
    assert_includes cascade, "afterSmsSend"
    assert_includes lib, "buildSendSmsBody"
  end
end
