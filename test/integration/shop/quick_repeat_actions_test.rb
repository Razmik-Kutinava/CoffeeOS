# frozen_string_literal: true

require "test_helper"

# Quick Repeat: per-card pay; без общей «повторить в 1 клик» и «+ещё» (заказчик 2026-07-24).
class Shop::QuickRepeatActionsTest < ActionDispatch::IntegrationTest
  test "store keeps repeat helpers for card pay and feedback" do
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))

    assert_includes store, "export async function repeatPayOneClickItem"
    assert_includes store, "export async function repeatAllToCart"
    assert_includes store, "addToCart("
    assert_includes store, "modifier_options"
    assert_includes store, "selected_modifiers"
    assert_includes store, "export const repeatFeedback"
    assert_operator store.lines.count, :<=, 120
  end

  test "RepeatSection has per-card pay only — no global one-click or more" do
    section = File.read(Rails.root.join("app/frontend/components/RepeatSection.svelte"))

    assert_includes section, 'data-testid="shop-repeat-card-pay"'
    assert_includes section, "оплатить в 1 клик"
    assert_includes section, "bg-[#ff8c42]"
    # Per-card pay: inline widget flow (createRepeatInlineOrder), не global repeatPayOneClickItem
    assert_includes section, "createRepeatInlineOrder"

    refute_includes section, 'data-testid="shop-repeat-one-click"'
    refute_includes section, "повторить в 1 клик"
    refute_includes section, 'data-testid="shop-repeat-more"'
    refute_includes section, "+ещё"

    assert_includes section, 'data-testid="shop-repeat-toast"'
    assert_includes section, "repeatFeedback"
  end

  test "customization flow stays on Product route with cart_line" do
    product = File.read(Rails.root.join("app/frontend/routes/Product.svelte"))

    assert_includes product, "cart_line"
    assert_includes product, "initSelectedFromCartLine"
    assert_includes product, "selected_modifiers"
  end

  test "partial add failure reports honest added-of-total toast" do
    store = File.read(Rails.root.join("app/frontend/lib/frequentRepeatStore.js"))

    assert_includes store, "added", "store считает успешно добавленные позиции"
    assert_includes store, "Добавлено ${added} из ${items.length}",
      "error-тост при частичном добавлении честный: N из M"
    assert_includes store, "Не удалось повторить заказ",
      "полный провал (0 добавлено) — прежнее сообщение"
  end

  test "partial add mirror: message depends on added count" do
    assert_equal "Не удалось повторить заказ", partial_message(0, 3)
    assert_equal "Добавлено 1 из 3 — проверьте корзину", partial_message(1, 3)
    assert_equal "Добавлено 2 из 3 — проверьте корзину", partial_message(2, 3)
  end

  private

  def partial_message(added, total)
    added.positive? ? "Добавлено #{added} из #{total} — проверьте корзину" : "Не удалось повторить заказ"
  end
end
