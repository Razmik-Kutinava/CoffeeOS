# frozen_string_literal: true

require "test_helper"

# Checkout payment method card — Шаги 1–7 + экстремалы (red zone)
# ТЗ: customer_tasks/Выбор способа оплаты и прикрепление банковской карты
#      на экране оформления заказа.md
# Макеты: artifacts/checkout_payment_method_card/screenshots/s01–s07
#
# Код UI пока НЕ реализован — ожидаем FAIL (красная зона).
# Паттерн: static asserts по исходникам (как product_card_s1 / cart_expanded_image).
# E1–E10: § «Экстремальные сценарии» того же ТЗ — в этом же файле.
class Shop::CheckoutPaymentSheetS1S7RedTest < ActionDispatch::IntegrationTest
  SHEET = "app/frontend/components/CheckoutPaymentSheet.svelte"
  STORE = "app/frontend/lib/checkoutPaymentSheetStore.js"
  THRESHOLDS = "app/frontend/lib/checkoutPaymentSheetThresholds.js"
  CHECKOUT = "app/frontend/routes/Checkout.svelte"

  def read_src(rel)
    path = Rails.root.join(rel)
    assert path.exist?, "Ожидается файл #{rel} (ещё нет — красная зона до реализации)"
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

  # --- Каркас: отдельные файлы checkout sheet (не CartSheet) -----------------

  test "S0 scaffold: Checkout mounts CheckoutPaymentSheet (not catalog CartSheet modes)" do
    src = checkout
    assert_includes src, "CheckoutPaymentSheet",
      "Шаг 1–7: Checkout.svelte должен монтировать CheckoutPaymentSheet"
    refute_includes src, "checkoutSheetStore",
      "Не использовать удалённый checkoutSheetStore — новый checkoutPaymentSheetStore"
  end

  # --- Шаг 1: Peek + footer disabled до email --------------------------------

  test "S1 peek: store has peek mode and cart sync; sheet has peek layouts 1/2/3+" do
    st = store
    sh = sheet

    assert_match(/peek|MODE_PEEK/i, st, "Шаг 1: store — режим peek")
    assert_includes sh, 'data-testid="checkout-payment-sheet"',
      "Шаг 1: корневой testid шторки"
    assert_includes sh, 'data-checkout-sheet-mode="peek"',
      "Шаг 1: атрибут mode=peek (или data-checkout-sheet-mode={mode} с peek)"

    # Layouts по числу позиций (s01–s03)
    assert_includes sh, 'data-testid="checkout-payment-peek-single"',
      "Шаг 1: peek 1 товар — полная карточка"
    assert_includes sh, 'data-testid="checkout-payment-peek-multi"',
      "Шаг 1: peek 3+ — горизонтальный скролл миниатюр"
    assert_match(/checkout-payment-peek-(minus|plus)/, sh,
      "Шаг 1: счётчики −/+ на миниатюрах peek")
  end

  test "S1 peek footer: SBP / Card+ / Pay disabled until emailVerified" do
    sh = sheet
    assert_includes sh, 'data-testid="checkout-payment-sbp"',
      "Шаг 1: кнопка СБП"
    assert_includes sh, 'data-testid="checkout-payment-card-plus"',
      "Шаг 1: кнопка Картой +"
    assert_includes sh, 'data-testid="checkout-payment-pay"',
      "Шаг 1: кнопка Оплатить"

    # Disabled gate от emailVerified (prop / derived)
    assert_match(/emailVerified/, sh,
      "Шаг 1: footer читает emailVerified")
    assert_match(/disabled[\s\S]{0,80}emailVerified|emailVerified[\s\S]{0,80}disabled/i, sh,
      "Шаг 1: до подтверждения email все три кнопки disabled")
  end

  test "S1 after verify: Card+ enabled; Pay only if saved card; SBP stays disabled" do
    sh = sheet
    assert_match(/savedCards|hasSavedCard|savedCard/, sh,
      "Шаг 1: Pay зависит от наличия сохранённой карты")
    # СБП всегда disabled
    sbp_block = sh[/\s*data-testid="checkout-payment-sbp"[\s\S]{0,200}/]
    assert sbp_block, "Шаг 1: блок СБП"
    assert_match(/disabled/, sbp_block,
      "Шаг 1: СБП остаётся disabled после verify")
  end

  # --- Шаг 2: Peek → Expanded ------------------------------------------------

  test "S2 expanded: store expandSheet / collapse; sheet expanded list + payment methods" do
    st = store
    sh = sheet
    th = thresholds

    assert_match(/export function expand|expandSheet|expandCheckout/i, st,
      "Шаг 2: store — переход peek→expanded")
    assert_match(/400|transition/i, th,
      "Шаг 2: thresholds — анимация ≤ 400 мс")
    assert_includes sh, 'data-testid="checkout-payment-expanded"',
      "Шаг 2: expanded layout"
    assert_match(/Картой|formatCardListLabel|cardLabel/, sh,
      "Шаг 2: в expanded видны методы оплаты (карта / СБП / Картой +)")
  end

  test "S2 Pay button active only when at least one saved card" do
    sh = sheet
    assert_match(
      /canPay|savedCards\.length|hasSavedCard/,
      sh,
      "Шаг 2: Оплатить enabled только при ≥1 карте"
    )
  end

  # --- Шаг 3: Expanded → Expanded+ payment list ------------------------------

  test "S3 expanded_plus: openPaymentList; payment-list with cards, SBP, Card+, X close" do
    st = store
    sh = sheet

    assert_match(/expanded_plus|MODE_EXPANDED_PLUS|expandedPlus/i, st,
      "Шаг 3: store — режим expanded+")
    assert_match(/openPaymentList|openCheckoutPayment/i, st,
      "Шаг 3: store — открытие списка способов оплаты")
    assert_includes sh, 'data-testid="checkout-payment-expanded-plus"',
      "Шаг 3: UI expanded+"
    assert_includes sh, 'data-testid="checkout-payment-list"',
      "Шаг 3: список сохранённых карт"
    assert_includes sh, 'data-testid="checkout-payment-close"',
      "Шаг 3: кнопка X закрытия"
  end

  # --- Шаг 4: Card form inside expanded+ -------------------------------------

  test "S4 card_form: openCardForm; NewCardSheet embedded; price bar; fields + save toggle" do
    st = store
    sh = sheet

    assert_match(/card_form|SUBVIEW_CARD_FORM|openCardForm/i, st,
      "Шаг 4: store — subView card_form")
    assert_includes sh, 'data-testid="checkout-payment-card-form"',
      "Шаг 4: форма карты внутри sheet"
    assert_includes sh, 'data-testid="checkout-payment-form-price-bar"',
      "Шаг 4: сверху цена + неактивная кнопка с ценой"
    assert_match(/NewCardSheet|Номер карты|embedded/, sh,
      "Шаг 4: форма карты (NewCardSheet embedded или поля PAN/expiry/CVV)")
    assert_match(/будущих заказов|saveCard|save_card/i, sh,
      "Шаг 4: свитч «Использовать карту для будущих заказов»")
  end

  # --- Шаг 5: 3D Secure inside expanded+ -------------------------------------

  test "S5 three_ds: keypad, timer 00:59, Allow button, backspace via >" do
    st = store
    sh = sheet

    assert_match(/three_ds|SUBVIEW_THREE_DS|openThreeDs/i, st,
      "Шаг 5: store — subView three_ds")
    assert_includes sh, 'data-testid="checkout-payment-three-ds"',
      "Шаг 5: экран 3DS внутри sheet"
    assert_match(/00:59|timer|countdown/i, sh,
      "Шаг 5: таймер обратного отсчёта от 00:59")
    assert_includes sh, 'data-testid="checkout-payment-three-ds-keypad"',
      "Шаг 5: цифровая клавиатура (не системная)"
    assert_match(/Разрешить|Allow/i, sh,
      "Шаг 5: кнопка Разрешить")
  end

  # --- Шаг 6: Pay ------------------------------------------------------------

  test "S6 pay: sheet onPay wired to Checkout payment handler" do
    co = checkout
    sh = sheet

    assert_match(/onPay|handlePay/, sh,
      "Шаг 6: sheet принимает onPay")
    assert_match(/CheckoutPaymentSheet[\s\S]{0,400}onPay|handlePayFromSheet|onPay=\{/, co,
      "Шаг 6: Checkout прокидывает pay handler в sheet")
  end

  # --- Шаг 7: X close, horizontal scroll, tap image → openEditCard -----------

  test "S7 close X: returns expanded_plus → expanded via store" do
    st = store
    assert_match(/closePaymentList|collapseFromPlus|closeExpandedPlus/i, st,
      "Шаг 7: store — X закрывает expanded+ → expanded")
  end

  test "S7 horizontal scroll: multi items overflow-x in expanded/expanded+" do
    sh = sheet
    assert_match(/overflow-x:\s*auto|overflow-x:\s*scroll/, sh,
      "Шаг 7: горизонтальный скролл при >3 товарах")
  end

  test "S7 expanded: click product image calls openEditCard with line modifiers" do
    sh = sheet
    store_cart = File.read(Rails.root.join("app/frontend/lib/cartSheetStore.js"))

    # openEditCard уже есть в catalog store — checkout sheet должен его вызвать.
    assert_includes store_cart, "export function openEditCard"

    assert_includes sh, 'data-testid="checkout-payment-expanded-product-image"',
      "Шаг 7: кликабельная картинка товара в expanded (не вся строка)"
    assert_includes sh, "openEditCard(line",
      "Шаг 7: клик по изображению вызывает openEditCard(line…)"
    assert_match(/selected_modifiers|cart_line/, sh,
      "Шаг 7: в openEditCard передаётся line с модификаторами / cart_line")
  end

  # --- Экстремальные сценарии (Error & Edge States) -------------------------

  test "E1 3DS timer 00:00: Allow disabled; restart add-card flow" do
    sh = sheet
    assert_match(/00:00|timerExpired|threeDsExpired|timer.*===.*0/i, sh,
      "E1: при истечении таймера 3DS есть состояние 00:00 / expired")
    assert_match(
      /Разрешить[\s\S]{0,120}disabled|disabled[\s\S]{0,120}Разрешить|allowDisabled|timerExpired/,
      sh,
      "E1: кнопка «Разрешить» блокируется при 00:00"
    )
    assert_match(/openCardForm|closeThreeDs|restart|заново|card_form/i, sh + store,
      "E1: после expiry — возврат к добавлению карты заново")
  end

  test "E2 wrong SMS code: error message, clear field, timer keeps running" do
    sh = sheet
    assert_includes sh, 'data-testid="checkout-payment-three-ds-error"',
      "E2: сообщение об ошибке неверного СМС"
    assert_match(/clear|otpCode\s*=\s*[\"']{2}|smsCode\s*=\s*[\"']{2}|resetCode/i, sh,
      "E2: поле СМС очищается после ошибки")
  end

  test "E3 network fail during 3DS: connection error + retry" do
    sh = sheet
    assert_match(/checkout-payment-three-ds-(network|connection)-error|threeDsNetworkError/i, sh,
      "E3: UI ошибки соединения при 3DS")
    assert_match(/Повторить|retry|onRetry/i, sh,
      "E3: возможность повторить попытку")
  end

  test "E4 close empty card form: back to payment_list; form data not persisted" do
    st = store
    sh = sheet
    assert_match(/closeCardForm/, st,
      "E4: store closeCardForm → payment_list")
    assert_match(/reset|clearForm|pan\s*=\s*[\"']{2}|resetFields/i, sh,
      "E4: при закрытии пустой формы поля сбрасываются")
  end

  test "E5 11th card: limit 10 — form does not open; limit message" do
    st = store
    sh = sheet
    assert_match(/MAX_.*CARD|maxCards|10/, st + sh,
      "E5: лимит 10 сохранённых карт")
    assert_match(/openCardForm[\s\S]{0,200}length|savedCards\.length[\s\S]{0,80}>=?\s*10|limitReached/i, st + sh,
      "E5: guard — не открывать форму при ≥10 картах")
    assert_includes sh, 'data-testid="checkout-payment-card-limit-error"',
      "E5: сообщение о достижении лимита карт"
  end

  test "E6 email verify network fail: footer stays disabled + err visible" do
    co = checkout
    sh = sheet
    assert_match(/emailVerified/, sh,
      "E6: footer завязан на emailVerified")
    assert_match(/err/, co,
      "E6: Checkout показывает ошибку сети при verify")
  end

  test "E7 delete all saved cards: Pay becomes disabled" do
    sh = sheet
    assert_match(/removeCard|deleteCard|onRemoveCard|Удалить.*карт/i, sh,
      "E7: возможность удалить сохранённую карту в expanded+")
    assert_match(/savedCards\.length|hasSavedCard|canPay/, sh,
      "E7: Оплатить зависит от наличия карт после удаления")
  end

  test "E8 invalid card form: Next stays disabled + field validation" do
    sh = sheet
    assert_match(/refreshFieldErrors|fieldErrors|invalid|disabled.*[Дд]алее|[Дд]алее[\s\S]{0,80}disabled/i, sh,
      "E8: «Далее» disabled при невалидных PAN/expiry/CVV")
    assert_match(/Номер карты|expiry|CVV|cvv/i, sh,
      "E8: валидация полей формы карты")
  end

  test "E9 peek before email: footer buttons no-op (disabled)" do
    sh = sheet
    %w[checkout-payment-sbp checkout-payment-card-plus checkout-payment-pay].each do |tid|
      block = sh[/data-testid="#{tid}"[\s\S]{0,180}/]
      assert block, "E9: кнопка #{tid}"
      assert_match(/disabled/, block,
        "E9: #{tid} disabled до подтверждения email")
    end
  end

  test "E10 empty cart: sheet hidden or empty state" do
    st = store
    sh = sheet
    assert_match(/items\.length|cartItems|MODE_EMPTY|hidden|empty/i, st,
      "E10: store — gate при 0 товаров")
    empty_gate =
      sh.match?(/items\.length\s*===?\s*0/) ||
      sh.match?(/!items\.length/) ||
      sh.include?("{#if items") ||
      sh.include?("checkout-payment-empty") ||
      sh.match?(/return null/)
    assert empty_gate,
      "E10: sheet не рендерится или empty state при пустой корзине"
  end
end
