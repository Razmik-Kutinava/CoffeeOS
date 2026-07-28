# frozen_string_literal: true

require "test_helper"

# Auth funnel cascade: checkout phone wizard Screens 1–4.
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
    assert_includes wizard, "PhoneAuthCodeStep"

    assert_includes lib, "flash_call"
    assert_includes lib, "canContinuePhone"
    assert_includes lib, "buildFlashCallSendBody"
  end

  test "screen 2 has four pin cells auto-verify and change number without confirm button" do
    step = File.read(Rails.root.join("app/frontend/components/PhoneAuthCodeStep.svelte"))
    pin = File.read(Rails.root.join("app/frontend/components/PhoneAuthPinInputs.svelte"))
    lib = File.read(Rails.root.join("app/frontend/lib/phoneAuthWizard.js"))

    assert_includes step, 'data-testid="phone-auth-screen-2"'
    assert_includes step, 'data-testid="phone-auth-change-number"'
    assert_includes step, "Изменить номер"
    assert_includes step, "phone_otp/verify"
    assert_includes step, "PhoneAuthPinInputs"
    refute_includes step, "Подтвердить код"
    refute_includes step, "Подтвердить телефон"

    assert_includes pin, 'data-testid="phone-auth-pin"'
    assert_includes pin, "phone-auth-pin-"
    assert_includes pin, 'maxlength="1"'
    assert_includes pin, "shouldAutoSubmitPin"

    assert_includes lib, "shouldAutoSubmitPin"
    assert_includes lib, "buildVerifyBody"
    assert_includes lib, "PIN_LENGTH"
    assert_match(/PIN_LENGTH\s*=\s*4/, lib)
  end

  test "flash cascade shows wait timer and retry button wiring" do
    step = File.read(Rails.root.join("app/frontend/components/PhoneAuthCodeStep.svelte"))
    cascade = File.read(Rails.root.join("app/frontend/lib/phoneAuthCascade.js"))

    assert_includes step, 'data-testid="phone-auth-flash-timer"'
    assert_includes step, 'data-testid="phone-auth-flash-hint"'
    assert_includes step, 'data-testid="phone-auth-retry-flash"'
    assert_includes step, "tickFlashCascade"
    assert_includes step, "RETRY_FLASH_LABEL"
    assert_includes step, "cascadeTimerLabel"

    assert_includes cascade, "FLASH_WAIT_SEC"
    assert_match(/FLASH_WAIT_SEC\s*=\s*20/, cascade)
    assert_includes cascade, "Ждем звонок..."
    assert_includes cascade, "Запросить звонок еще раз"
    assert_includes cascade, "tickFlashCascade"
    assert_includes cascade, "showRetryFlashButton"
  end

  test "messenger and sms fallback buttons and timings" do
    step = File.read(Rails.root.join("app/frontend/components/PhoneAuthCodeStep.svelte"))
    cascade = File.read(Rails.root.join("app/frontend/lib/phoneAuthCascade.js"))
    lib = File.read(Rails.root.join("app/frontend/lib/phoneAuthWizard.js"))

    assert_includes step, 'data-testid="phone-auth-messenger"'
    assert_includes step, 'data-testid="phone-auth-sms"'
    assert_includes step, "MESSENGER_BTN_LABEL"
    assert_includes step, "SMS_BTN_LABEL"
    assert_includes step, "afterMessengerDeliveryError"
    assert_includes step, 'sendChannel("messenger")'
    assert_includes step, 'sendChannel("sms")'

    assert_match(/MESSENGER_WAIT_SEC\s*=\s*30/, cascade)
    assert_match(/SMS_COOLDOWN_SEC\s*=\s*60/, cascade)
    assert_includes cascade, "WhatsApp / Telegram"
    assert_includes cascade, "Отправить код в СМС"
    assert_includes cascade, "afterMessengerSend"
    assert_includes cascade, "afterSmsSend"

    assert_includes lib, "buildOtpSendBody"
  end
end
