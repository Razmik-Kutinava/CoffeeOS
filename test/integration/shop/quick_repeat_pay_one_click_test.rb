# frozen_string_literal: true

require "test_helper"

# Quick Repeat Bottom Sheet — Шаг F5 (скрин 06, «в клик оплата»):
# кнопка «оплатить в 1 клик» на секции повтора: позиции повтора в корзину →
# переход на /checkout → автооткрытие шита оплаты с преселектнутой
# сохранённой картой. Списание — существующий канон one_click
# (подтверждение «Оплатить» за пользователем, молча деньги не снимаем).
class Shop::QuickRepeatPayOneClickTest < ActionDispatch::IntegrationTest
  test "store exposes per-card pay-one-click flow via checkout autopay flag" do
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))

    assert_includes store, "export async function repeatPayOneClickItem"
    assert_includes store, 'REPEAT_AUTOPAY_KEY = "shop_repeat_autopay"'
    assert_includes store, "sessionStorage.setItem(REPEAT_AUTOPAY_KEY"
    assert_includes store, 'push("/checkout")'
    assert_includes store, "svelte-spa-router"
  end

  test "RepeatSection renders per-card pay-one-click button" do
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))

    assert_includes section, 'data-testid="shop-repeat-card-pay"'
    assert_includes section, "оплатить в 1 клик"
    assert_includes section, "onPayCardClick"
    assert_includes section, "createRepeatInlineOrder"
    assert_includes section, "runRepeatWidgetPayFlow"
  end

  test "Checkout consumes autopay flag and opens payment sheet" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))

    # onMount: флаг повтора → снять флаг → открыть шит оплаты (канон Шага 3/4)
    assert_includes checkout, "REPEAT_AUTOPAY_KEY"
    assert_includes checkout, "sessionStorage.removeItem(REPEAT_AUTOPAY_KEY)"
  end

  # Зеркало контракта (как mirror-тесты F1–F4)
  test "pay mirror: success navigates to checkout autopay, error stays" do
    assert_equal [ :checkout, :autopay ], pay_outcome(repeat_ok: true)
    assert_equal [ :stay, :error ], pay_outcome(repeat_ok: false)
  end

  private

  # Ошибка добавления в корзину: error-тост уже показан repeatAllToCart,
  # навигации на checkout нет — пользователь остаётся в текущем режиме
  def pay_outcome(repeat_ok:)
    repeat_ok ? [ :checkout, :autopay ] : [ :stay, :error ]
  end
end
