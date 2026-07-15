# frozen_string_literal: true

require "test_helper"

# Pay FSM 0–7 + 3DS overlay (UserCards extremes / Client Error)
class Shop::ShopPayFsm3dsTest < ActionDispatch::IntegrationTest
  FSM = Rails.root.join("app/frontend/lib/shopPayFsm.js")
  BTN = Rails.root.join("app/frontend/components/CheckoutPayButton.svelte")
  OVERLAY = Rails.root.join("app/frontend/components/ThreeDsOverlay.svelte")
  ENCRYPT = Rails.root.join("app/frontend/lib/tbankCardEncrypt.js")
  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")
  SHEET = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")

  test "shopPayFsm defines states 0-7 and Client/Net Error labels" do
    src = File.read(FSM)
    assert_includes src, "DEFAULT: 0"
    assert_includes src, "CONNECTING: 1"
    assert_includes src, "PROCESSING: 2"
    assert_includes src, "THREE_DS: 3"
    assert_includes src, "SUCCESS: 4"
    assert_includes src, "CLIENT_ERROR: 5"
    assert_includes src, "BANK_ERROR: 6"
    assert_includes src, "NET_ERROR: 7"
    assert_includes src, "Отказ: смените карту"
    assert_includes src, "Нет сети: повторить"
    assert_includes src, "Подтвердите по СМС"
    assert_includes src, "withMinLoaderMs"
    assert_includes src, "fsmFromPaymentError"
  end

  test "CheckoutPayButton renders FSM classes and shake on Client Error" do
    src = File.read(BTN)
    assert_includes src, "pay-fsm-btn--shake"
    assert_includes src, "pay-fsm-btn__loader"
    assert_includes src, 'data-testid="checkout-pay-fsm"'
    assert_includes src, "payFsmLabel"
  end

  test "ThreeDsOverlay iframe and close → Client Error wiring in Checkout" do
    overlay = File.read(OVERLAY)
    assert_includes overlay, 'data-testid="three-ds-overlay"'
    assert_includes overlay, 'data-testid="three-ds-frame"'
    assert_includes overlay, "THREE_DS_FRAME_NAME"

    enc = File.read(ENCRYPT)
    assert_includes enc, "THREE_DS_FRAME_NAME"
    assert_includes enc, "submitThreeDsChallenge"
    assert_includes enc, "PaReq"

    checkout = File.read(CHECKOUT)
    assert_includes checkout, "ThreeDsOverlay"
    assert_includes checkout, "onThreeDsClose"
    assert_includes checkout, "PAY_FSM.CLIENT_ERROR"
    assert_includes checkout, "PAY_FSM.THREE_DS"
    assert_includes checkout, "submitThreeDsChallenge"
    assert_includes checkout, "threeDsAborted"
  end

  test "PaymentMethodsSheet uses CheckoutPayButton FSM" do
    src = File.read(SHEET)
    assert_includes src, "CheckoutPayButton"
    assert_includes src, "fsmState"
    assert_includes src, "onRetry"
    refute_includes src, 'data-testid="payment-methods-pay"'
  end
end
