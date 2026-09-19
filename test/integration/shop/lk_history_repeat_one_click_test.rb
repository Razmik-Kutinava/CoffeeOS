# frozen_string_literal: true

require "test_helper"

# TASK_94: ЛК history repeat → new Order + existing Quick Repeat one-click
class Shop::LkHistoryRepeatOneClickTest < ActiveSupport::TestCase
  test "Profile repeat button wires history pay flow (not only openReceipt)" do
    src = File.read(Rails.root.join("app/frontend/routes/Profile.svelte"))
    assert_includes src, 'data-testid="shop-lk-repeat-btn"'
    assert_match(/runHistoryRepeatPayFlow|startHistoryRepeat/, src)
    refute_match(
      /data-testid="shop-lk-repeat-btn"[^>]*onclick=\{\(\) => openReceipt\(order\.id\)\}/,
      src
    )
  end

  test "OrderReceipt ПОВТОРИТЬ wires history pay flow (not Subtask 12 stub)" do
    src = File.read(Rails.root.join("app/frontend/routes/OrderReceipt.svelte"))
    assert_includes src, 'data-testid="shop-order-repeat-stub"'
    assert_match(/runHistoryRepeatPayFlow|startHistoryRepeat/, src)
    refute_match(/Subtask 12: без бизнес-логики повтора/, src)
  end

  test "historyRepeatAdapter reuses widget pay flow (no second payment stack)" do
    src = File.read(Rails.root.join("app/frontend/lib/historyRepeatAdapter.js"))
    assert_includes src, "runRepeatWidgetPayFlow"
    assert_match(/createOrderFromHistoryOrder|createRepeatInlineOrder|addToCart/, src)
    refute_match(/Tinkoff|Stripe|new Tbank/i, src)
  end

  test "order_json exposes product_id for history repeat cart rebuild" do
    ctrl = File.read(Rails.root.join("app/controllers/shop/api/orders_controller.rb"))
    assert_match(/product_id:\s*item\.product_id/, ctrl)
  end

  test "checkout regression guard: Checkout still owns standard autopay flag" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    assert_includes checkout, "REPEAT_AUTOPAY_KEY"
    assert_includes checkout, "sessionStorage.removeItem(REPEAT_AUTOPAY_KEY)"
  end
end
