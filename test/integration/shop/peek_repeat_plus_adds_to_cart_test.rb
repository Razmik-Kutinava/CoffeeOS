# frozen_string_literal: true

require "test_helper"

# Peek + «повторить»: плюс на карточке должен добавить товар в текущий заказ
# (не только крутить локальный счётчик qty).
class Shop::PeekRepeatPlusAddsToCartTest < ActionDispatch::IntegrationTest
  test "repeatEmbeddedCart exports bump that calls addToCart" do
    lib = File.read(Rails.root.join("app/frontend/lib/repeatEmbeddedCart.js"))

    assert_includes lib, "export async function repeatBumpEmbeddedToCart"
    assert_includes lib, "addToCart("
    assert_includes lib, "bumpCartLine("
    assert_includes lib, "refreshCartSheet("
    assert_includes lib, "selected_modifiers: selectedMods(item)"
  end

  test "embedded RepeatSection wires plus to cart bump not only setFrequentQty" do
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))

    assert_includes section, "repeatBumpEmbeddedToCart"
    assert_includes section, "from \"../lib/repeatEmbeddedCart.js\""
    assert_includes section, "await repeatBumpEmbeddedToCart(item, delta)"
    assert_includes section, "if (embedded)"
    # full (empty cart): по-прежнему только локальный qty под «оплатить в 1 клик»
    assert_includes section, "setFrequentQty(key, qtyOf(key) + delta)"
  end

  test "cart sheet build bumped for peek repeat plus fix" do
    thresholds = File.read(Rails.root.join("app/frontend/lib/cartSheetThresholds.js"))
    assert_includes thresholds, 'CART_SHEET_BUILD = "prog38"'
  end
end
