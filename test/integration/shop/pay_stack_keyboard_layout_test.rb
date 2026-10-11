# frozen_string_literal: true

require "test_helper"

# TASK_105: форма оплаты под цифровой клавиатурой — без карточки товара в pay-стеке,
# шторка оплаты от visual viewport (над клавиатурой), внутренняя прокрутка, «Оплатить» не перекрыта.
class Shop::PayStackKeyboardLayoutTest < ActionDispatch::IntegrationTest
  SHEET = Rails.root.join("app/frontend/components/CartSheet.svelte")
  PAY = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")

  def stacked_css
    File.read(PAY)[/\.pm-sheet--stacked\s*\{[^}]*\}/m].to_s
  end

  test "Subtask 6: в pay-стеке CartSheet (карточка товара) не рендерится" do
    src = File.read(SHEET)
    assert_match(/\{#if showSheet && !payStackActive\}/, src)
  end

  test "Subtask 6: каталог/товар/phone-auth — шторка по-прежнему по showSheet" do
    src = File.read(SHEET)
    assert_includes src, "let showSheet = $derived(isCartSheetRoute(hash))"
    assert_includes src, "let phoneAuthSlim = $derived(onCheckout && phoneAuthActive && !payStackOpen)"
  end

  test "Subtask 5/8: высота и низ шторки оплаты — от visual viewport, не vh минус peek" do
    css = stacked_css
    refute_empty css
    refute_includes css, "--checkout-cart-peek-h"
    assert_includes css, "var(--shop-pay-stack-h"
    assert_includes css, "var(--shop-pay-stack-bottom"
  end

  test "Subtask 7/11: внутренняя прокрутка, «Оплатить» вне прокручиваемой части" do
    pay = File.read(PAY)
    assert_includes pay, 'class="pm-sheet__body"'
    body_at = pay.index('class="pm-sheet__body"')
    pay_at = pay.index('<div class="pm-sheet__pay">')
    total_at = pay.index('data-testid="payment-methods-order-total"')
    assert body_at < total_at, "«Итого» внутри тела шторки, порядок TASK_101 сохранён"
    assert pay.index("</div>", pay.index("payment-method-inline-error")) < pay_at,
      "тело закрыто до кнопки оплаты"
    assert_match(/\.pm-sheet--stacked\s+\.pm-sheet__body\s*\{[^}]*overflow-y:\s*auto/m, pay)
    assert_match(/\.pm-sheet--stacked\s*\{[^}]*display:\s*flex/m, pay)
    assert_match(/\.pm-sheet--stacked\s+\.pm-sheet__pay\s*\{[^}]*flex-shrink:\s*0/m, pay)
  end

  test "не тронуто: «Итого», NewCardForm, autocomplete карты" do
    pay = File.read(PAY)
    assert_includes pay, "labelOrderTotal()"
    assert_includes pay, "<NewCardForm bind:state={newCardState} />"
    form = File.read(Rails.root.join("app/frontend/components/NewCardForm.svelte"))
    assert_includes form, 'autocomplete="cc-number"'
  end
end
