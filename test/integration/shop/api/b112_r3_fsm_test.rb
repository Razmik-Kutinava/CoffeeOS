# frozen_string_literal: true

require "test_helper"

# B1.12-R3 фаза 2 — FSM кнопки оплаты 0–7.
class Shop::Api::B112R3FsmTest < ActionDispatch::IntegrationTest
  test "shopPayFsm defines states 0-7 and error mapping" do
    fsm = File.read(Rails.root.join("app/frontend/lib/shopPayFsm.js"))

    assert_includes fsm, "DEFAULT: 0"
    assert_includes fsm, "CONNECTING: 1"
    assert_includes fsm, "PROCESSING: 2"
    assert_includes fsm, "THREE_DS: 3"
    assert_includes fsm, "SUCCESS: 4"
    assert_includes fsm, "CLIENT_ERROR: 5"
    assert_includes fsm, "BANK_ERROR: 6"
    assert_includes fsm, "NET_ERROR: 7"
    assert_includes fsm, "Установка соединения"
    assert_includes fsm, "Обработка банком"
    assert_includes fsm, "Отказ: смените карту"
    assert_includes fsm, "withMinLoaderMs"
    assert_includes fsm, "MIN_LOADER_MS = 600"
    assert_includes fsm, "fsmFromPaymentError"
    assert_includes fsm, '"1051"'
    assert_includes fsm, '"1014"'
  end

  test "CheckoutPayButton renders FSM labels and shake" do
    btn = File.read(Rails.root.join("app/frontend/components/CheckoutPayButton.svelte"))

    assert_includes btn, "fsmState"
    assert_includes btn, "payFsmLabel"
    assert_includes btn, "pay-fsm-btn--shake"
    assert_includes btn, "pay-fsm-btn__loader"
    assert_includes btn, "pay-fsm-btn--4"
    refute_includes btn, "errorInfo"
    refute_includes btn, "role=\"alert\""
  end

  test "Checkout one-click uses payments/one_click API" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))

    assert_includes checkout, '"/payments/one_click"'
    assert_includes checkout, "payFsmState"
    assert_includes checkout, "ThreeDsOverlay"
    assert_includes checkout, "withMinLoaderMs"
    refute_includes checkout, "classifyCheckoutPayError"
    refute_includes checkout, 'api("/orders"'
    refute_includes checkout, "payError"
  end

  test "NewCardSheet uses shared CheckoutPayButton FSM" do
    sheet = File.read(Rails.root.join("app/frontend/components/NewCardSheet.svelte"))
    encrypt = File.read(Rails.root.join("app/frontend/lib/tbankCardEncrypt.js"))

    assert_includes sheet, "CheckoutPayButton"
    assert_includes sheet, "onFsmChange"
    assert_includes sheet, "withMinLoaderMs"
    assert_includes sheet, 'apiWithPayTimeout(api, "/payments/new_card"'
    refute_includes sheet, "classifyCheckoutPayError"
    refute_includes sheet, "onError"
    assert_includes encrypt, "THREE_DS_FRAME_NAME"
    assert_includes encrypt, "coffeeos-three-ds-frame"
  end

  test "ThreeDsOverlay provides iframe target for ACS" do
    overlay = File.read(Rails.root.join("app/frontend/components/ThreeDsOverlay.svelte"))
    assert_includes overlay, "three-ds-frame"
    assert_includes overlay, "THREE_DS_FRAME_NAME"
  end
end
