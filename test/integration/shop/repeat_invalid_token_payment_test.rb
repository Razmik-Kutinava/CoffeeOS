# frozen_string_literal: true

require "test_helper"
require "open3"

# Repeat order invalid token — PaymentMethod BottomSheet (ТЗ шаги 1–6).
# RED: mirror/grep контракт Svelte + локальный store (не auth refresh).
class Shop::RepeatInvalidTokenPaymentTest < ActionDispatch::IntegrationTest
  I18N   = Rails.root.join("app/frontend/lib/paymentMethodI18n.js")
  STORE  = Rails.root.join("app/frontend/lib/repeatInvalidTokenStore.js")
  SHEET  = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte")
  CART   = Rails.root.join("app/frontend/components/CartSheet.svelte")
  CHECKOUT = Rails.root.join("app/frontend/routes/Checkout.svelte")

  test "step1 CartSheet exposes Add card CTA when invalid rebill in repeat context" do
    src = File.read(CART)
    assert_includes src, 'data-testid="shop-cart-add-card"'
    assert_includes src, "repeatInvalidTokenStore"
    assert_includes src, "shouldShowAddCardCta"
    assert_includes src, "ctaAddCard"
  end

  test "step2 PaymentMethodsSheet inline load error and i18n labels" do
    src = File.read(SHEET)
    assert_includes src, 'data-testid="payment-method-inline-error"'
    assert_includes src, 'data-testid="payment-method-load-retry"'
    assert_includes src, "paymentMethodI18n"
    assert_includes src, "formatCardRowLabel"
    assert_includes src, "labelAddCard"
    assert_includes src, "inlineError"
    assert_includes src, "loadError"
    assert_includes src, "onRetryLoad"
  end

  test "step3 PaymentMethodsSheet enables SBP deep link row" do
    src = File.read(SHEET)
    assert_includes src, 'data-testid="payment-method-sbp"'
    assert_includes src, "shopSbpPay"
    assert_includes src, "onSelectSbp"
    refute_match(
      /data-testid="payment-method-sbp"[\s\S]{0,120}?^\s*disabled\s*$/m,
      src,
      "SBP больше не permanently disabled (эпик deep link)"
    )
  end

  test "step5 Checkout wires invalid rebill store and sheet inline errors" do
    checkout = File.read(CHECKOUT)
    assert_includes checkout, "repeatInvalidTokenStore"
    assert_includes checkout, "setTokenInvalid"
    assert_includes checkout, "inlineError"
    assert_includes checkout, "isInvalidRebillPaymentError"
    refute_includes checkout, "silentRefreshSession", "auth refresh store must not be modified"
  end

  test "support modules exist on disk" do
    assert File.exist?(I18N), "expected paymentMethodI18n.js"
    assert File.exist?(STORE), "expected repeatInvalidTokenStore.js"
  end

  test "i18n card row label matches SBP mask «**** 1594»" do
    assert File.exist?(I18N)
    assert_equal "**** 1594", js_export("formatCardRowLabel", {
      "pan" => "*1594", "payment_system" => "VISA"
    })
  end

  test "store shouldShowAddCardCta true only for invalid token + repeat context" do
    assert File.exist?(STORE)
    assert_equal true, js_export("shouldShowAddCardCta", {
      "isTokenInvalid" => true,
      "hasRepeatContext" => true,
      "cartItemCount" => 1
    })
    assert_equal false, js_export("shouldShowAddCardCta", {
      "isTokenInvalid" => false,
      "hasRepeatContext" => true,
      "cartItemCount" => 1
    })
  end

  private

  def js_export(fn, arg)
    import_path = "./#{STORE.relative_path_from(Rails.root).to_s.tr('\\', '/')}"
    i18n_path = "./#{I18N.relative_path_from(Rails.root).to_s.tr('\\', '/')}"
    script = <<~JS
      import * as store from #{import_path.inspect};
      import * as i18n from #{i18n_path.inspect};
      const mod = store.#{fn} ? store : i18n;
      const result = mod.#{fn}(#{JSON.generate(arg)});
      process.stdout.write(JSON.stringify(result));
    JS
    stdout, stderr, status = Open3.capture3(
      "node", "--input-type=module", "-e", script,
      chdir: Rails.root.to_s
    )
    flunk "Node: #{stderr}" unless status.success?
    JSON.parse(stdout)
  end
end
