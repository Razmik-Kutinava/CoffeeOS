# frozen_string_literal: true

require "test_helper"

# #38 шаг 3 [TDD-RED] — enrich .pkpass: face / back links / strip из прогресса PWA.
class Shop::AppleWallet::PassBuilderTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    ENV["WALLET_SIMULATE"] = "1"
    @tenant = create_tenant!
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_name: "Pass",
      order_number: "202608-3803",
      source: :mobile,
      status: :accepted,
      total_amount: 120,
      discount_amount: 0,
      final_amount: 120
    )
  end

  teardown do
    ENV.delete("WALLET_SIMULATE")
    ENV.delete("WALLET_FORCE_UNAVAILABLE")
    ENV.delete("WALLET_FORCE_GEN_ERROR")
  end

  test "#38 accepted pass has status face, back chat/tips, strip progress 🟩⬜⬜" do
    built = Shop::AppleWallet::PassBuilder.build!(
      order: @order,
      status_label: "accepted",
      serial_number: "ser-1",
      authentication_token: "tok-1"
    )

    assert built[:simulated]
    assert_equal "status", built.dig(:face, :kind)
    assert_match(/принят|оплачен|accepted/i, built.dig(:face, :text).to_s)

    assert_equal "/shop/#/order/#{@order.id}?action=chat", built.dig(:back, :chat_url)
    assert_equal "/shop/#/order/#{@order.id}?action=tips", built.dig(:back, :tips_url)

    assert_equal "🟩⬜⬜", built.dig(:strip, :progress)
    assert_equal "order_status_progress", built.dig(:strip, :source)
    assert built.dig(:strip, :fill_percent).present?
  end

  test "#38 preparing strip uses 🟩🟩⬜ from push matrix" do
    @order.update!(status: :preparing)
    built = Shop::AppleWallet::PassBuilder.build!(
      order: @order.reload,
      status_label: "preparing",
      serial_number: "ser-2",
      authentication_token: "tok-2"
    )

    assert_equal "🟩🟩⬜", built.dig(:strip, :progress)
    assert_equal "status", built.dig(:face, :kind)
  end

  test "#38 ready face is QR with order number payload" do
    @order.update!(status: :ready)
    built = Shop::AppleWallet::PassBuilder.build!(
      order: @order.reload,
      status_label: "ready",
      serial_number: "ser-3",
      authentication_token: "tok-3"
    )

    assert_equal "qr", built.dig(:face, :kind)
    assert_includes built.dig(:face, :qr_payload).to_s, @order.order_number
    assert_equal "🟩🟩🟩", built.dig(:strip, :progress)
    assert_equal "/shop/#/order/#{@order.id}?action=chat", built.dig(:back, :chat_url)
  end

  test "#38 force gen error raises GenerationError for API 500 path" do
    ENV["WALLET_FORCE_GEN_ERROR"] = "1"

    assert_raises(Shop::AppleWallet::GenerationError) do
      Shop::AppleWallet::PassBuilder.build!(
        order: @order,
        status_label: "accepted",
        serial_number: "ser-x",
        authentication_token: "tok-x"
      )
    end
  end
end
