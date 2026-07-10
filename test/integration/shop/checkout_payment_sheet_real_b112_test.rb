# frozen_string_literal: true

require "test_helper"

# Checkout payment sheet → реальный B1.12 (NewCardSheet + ACS), без mock 3DS.
# ТЗ: customer_tasks/Выбор способа оплаты… (wiring до деплоя).
class Shop::CheckoutPaymentSheetRealB112Test < ActionDispatch::IntegrationTest
  SHEET = "app/frontend/components/CheckoutPaymentSheet.svelte"
  STORE = "app/frontend/lib/checkoutPaymentSheetStore.js"
  THRESHOLDS = "app/frontend/lib/checkoutPaymentSheetThresholds.js"
  CHECKOUT = "app/frontend/routes/Checkout.svelte"
  NEW_CARD = "app/frontend/components/NewCardSheet.svelte"
  THREE_DS = "app/frontend/components/ThreeDsOverlay.svelte"

  def read_src(rel)
    path = Rails.root.join(rel)
    assert path.exist?, "Ожидается файл #{rel}"
    File.read(path)
  end

  def sheet
    @sheet ||= read_src(SHEET)
  end

  def store
    @store ||= read_src(STORE)
  end

  def thresholds
    @thresholds ||= read_src(THRESHOLDS)
  end

  def checkout
    @checkout ||= read_src(CHECKOUT)
  end

  def new_card
    @new_card ||= read_src(NEW_CARD)
  end

  def three_ds
    @three_ds ||= read_src(THREE_DS)
  end

  # --- Шаг 1: Card+ → NewCardSheet (не mock form) -----------------------------

  test "S1 Card+: sheet calls onAddCard; no embedded card_form / keypad 3DS" do
    sh = sheet
    assert_match(/onAddCard/, sh, "Card+ должен вызывать onAddCard → NewCardSheet")
    refute_includes sh, 'data-testid="checkout-payment-card-form"',
      "Embedded mock-форма карты запрещена — только NewCardSheet"
    refute_includes sh, 'data-testid="checkout-payment-three-ds-keypad"',
      "Mock SMS-keypad 3DS запрещён — только ACS ThreeDsOverlay"
    refute_match(/openThreeDs|SUBVIEW_THREE_DS|threeDsTimer/, sh,
      "Локальный mock-таймер 3DS не должен жить в sheet")
  end

  test "S1 Checkout wires onAddCard to openNewCardSheet; mounts NewCardSheet + ThreeDsOverlay" do
    co = checkout
    assert_match(/CheckoutPaymentSheet[\s\S]{0,600}onAddCard/, co,
      "Checkout прокидывает onAddCard в sheet")
    assert_match(/onAddCard=\{[^}]*openNewCardSheet|function handleAddCard|openNewCardSheet/, co,
      "onAddCard открывает NewCardSheet")
    assert_includes co, "NewCardSheet", "NewCardSheet смонтирован"
    assert_includes co, "ThreeDsOverlay", "ThreeDsOverlay смонтирован для ACS"
  end

  # --- Шаг 2: Pay = one-click only -------------------------------------------

  test "S2 Pay: handlePayFromSheet only one-click; does not openNewCardSheet" do
    co = checkout
    pay_fn = co[/async function handlePayFromSheet\(\) \{[\s\S]*?\n  \}/]
    assert pay_fn, "handlePayFromSheet должен существовать"
    assert_match(/submitOneClick/, pay_fn, "Pay → one-click")
    refute_match(/openNewCardSheet/, pay_fn,
      "Pay без карты не должен открывать NewCardSheet — только Card+")
  end

  test "S2 Pay disabled without saved card" do
    sh = sheet
    assert_match(/hasSavedCard|savedCards\.length/, sh,
      "Pay зависит от наличия сохранённой карты")
  end

  # --- Шаг 3: Dual UI off ----------------------------------------------------

  test "S3 no dual payment UI: payment-method-summary and PaymentMethodsSheet gone" do
    co = checkout
    refute_includes co, 'data-testid="payment-method-summary"',
      "Legacy summary-кнопка убрана — одна шторка"
    refute_match(/<PaymentMethodsSheet/, co,
      "PaymentMethodsSheet не монтируется рядом с CheckoutPaymentSheet")
  end

  # --- Шаг 4: Delete card — no fake button -----------------------------------

  test "S4 no fake Удалить карту; Pay still gated by cards" do
    sh = sheet
    refute_match(/Удалить карту/, sh,
      "Кнопка удаления без API — запрещена (обман UX)")
    assert_match(/hasSavedCard|savedCards\.length|canPay/, sh,
      "Pay остаётся завязан на наличие карт")
  end

  # --- Шаг 5: Real B1.12 card + ACS ------------------------------------------

  test "S5 NewCardSheet: RSA encrypt + save_card + 3DS_CHECKING" do
    nc = new_card
    assert_match(/encryptCardPayload|tbankCardEncrypt/, nc, "RSA encrypt обязателен")
    assert_match(/save_card|saveCard/, nc, "Флаг save_card")
    assert_match(/3DS_CHECKING|three_ds|onThreeDs/, nc, "ACS 3DS path")
    assert_includes nc, 'data-testid="new-card-sheet"'
  end

  test "S5 ThreeDsOverlay present for ACS iframe" do
    assert_match(/acs|iframe|three.?ds/i, three_ds, "ACS overlay")
  end

  test "S5 limit 10 cards before opening NewCardSheet" do
    st = store
    sh = sheet
    assert_match(/MAX_SAVED_CARDS|MAX_.*CARD|10/, st + thresholds,
      "Лимит 10 карт")
    assert_match(/assertCanAddCard|canAddCard|openCardForm/, st,
      "Guard лимита в store")
    assert_includes sh, 'data-testid="checkout-payment-card-limit-error"'
  end

  # --- Peek / modes scaffold still intact ------------------------------------

  test "S0 peek/expanded/expanded_plus scaffold remains" do
    st = store
    sh = sheet
    assert_match(/MODE_PEEK|peek/, st)
    assert_match(/expandSheet/, st)
    assert_match(/openPaymentList/, st)
    assert_includes sh, 'data-testid="checkout-payment-sheet"'
    assert_includes sh, 'data-testid="checkout-payment-peek-single"'
    assert_includes sh, 'data-testid="checkout-payment-sbp"'
    assert_match(/emailVerified/, sh)
  end

  test "S0 empty cart gate" do
    sh = sheet
    assert(
      sh.include?("checkout-payment-empty") || sh.match?(/!items\.length/),
      "Пустая корзина — sheet скрыт"
    )
  end

  test "S0 expanded+ shows at most 2 product thumbs" do
    sh = sheet
    assert_match(/items\.slice\(0,\s*2\)/, sh,
      "ТЗ: в expanded+ видны 2 миниатюры")
  end
end
