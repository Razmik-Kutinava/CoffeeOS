# frozen_string_literal: true

require "test_helper"

# #38 шаг 1 [TDD-RED] — матрица FCM tag / actions / unicode progress.
class Shop::OrderStatusPushPayloadTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_name: "Payload",
      order_number: "202608-3801",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
  end

  test "#38 accepted: tag, cancel action, unicode 🟩⬜⬜" do
    result = Shop::OrderStatusPushPayload.build!(order: @order)

    assert_equal "order-#{@order.id}", result[:tag]
    assert_equal %w[cancel], result[:actions]
    assert_equal "🟩⬜⬜", result[:progress]
  end

  test "#38 preparing: tag, chat+tips, unicode 🟩🟩⬜" do
    @order.update!(status: :preparing)
    result = Shop::OrderStatusPushPayload.build!(order: @order.reload)

    assert_equal "order-#{@order.id}", result[:tag]
    assert_equal %w[chat tips], result[:actions]
    assert_equal "🟩🟩⬜", result[:progress]
  end

  test "#38 ready: tag, chat+tips, unicode 🟩🟩🟩" do
    @order.update!(status: :ready)
    result = Shop::OrderStatusPushPayload.build!(order: @order.reload)

    assert_equal "order-#{@order.id}", result[:tag]
    assert_equal %w[chat tips], result[:actions]
    assert_equal "🟩🟩🟩", result[:progress]
  end

  test "#38 unknown status raises for soft-fail path" do
    @order.update_column(:status, "pending_payment")

    assert_raises(Shop::OrderStatusPushPayload::Error) do
      Shop::OrderStatusPushPayload.build!(order: @order.reload)
    end
  end
end
