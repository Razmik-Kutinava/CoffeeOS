# frozen_string_literal: true

require "test_helper"

# #39 — OrderReadyCascadeJob: presence + Telegram → SMS
class Shop::OrderReadyCascadeJobTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(
      phone: "+79003991001",
      email: "cascade-#{SecureRandom.hex(3)}@example.com"
    )
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Cascade",
      order_number: "202608-3902",
      source: :mobile,
      status: :ready,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    Rails.cache.clear
    ENV["TELEGRAM_BOT_TOKEN"] = "test-bot-token"
    ENV["TELEGRAM_SIMULATE"] = "1"
    ENV["SMS_RU_API_ID"] = "test-api-id"
    ENV["SMS_RU_FROM"] = "CoffeeOS"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
  end

  teardown do
    Rails.cache.clear
    %w[
      TELEGRAM_BOT_TOKEN TELEGRAM_SIMULATE TELEGRAM_FORCE_400 TELEGRAM_FORCE_403
      TELEGRAM_FORCE_5XX TELEGRAM_FORCE_TIMEOUT SMS_RU_API_ID SMS_RU_FROM SHOP_OTP_LOG_FALLBACK
    ].each { |k| ENV.delete(k) }
  end

  test "#39 OrderReadyCascadeJob is an ApplicationJob and accepts order_id" do
    assert Shop::OrderReadyCascadeJob < ApplicationJob
    assert_nothing_raised do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
  end

  test "#39 ReadyPushJob still enqueues on first ready alongside cascade path" do
    fresh = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Fresh Cascade",
      order_number: "202608-3903",
      source: :mobile,
      status: :ready,
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )
    @customer.update!(push_enabled: true, push_token: "fcm-cascade")
    ENV["FCM_SIMULATE"] = "1"
    ENV["WALLET_SIMULATE"] = "1"

    assert_enqueued_with(job: Shop::ReadyPushJob, args: [fresh.id, "preparing"]) do
      assert_enqueued_with(job: Shop::OrderReadyCascadeJob, args: [fresh.id]) do
        Shop::GuestOrderBroadcaster.call(order: fresh, old_status: "preparing")
      end
    end
  ensure
    ENV.delete("FCM_SIMULATE")
    ENV.delete("WALLET_SIMULATE")
  end

  test "#39 when user online via WS skips paid channels" do
    Shop::OrderReadyPresence.mark_online!(@order.id)
    @customer.update!(telegram_chat_id: "183760838")

    logs = capture_cascade_logs do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end

    assert_match(
      /\[Cascade\]\[Order ##{@order.id}\] User is online via WebSocket\. Paid channels skipped\./,
      logs
    )
    assert_equal 0, OrderNotificationLog.where(order_id: @order.id).count
  end

  test "#39 when user offline does not log paid channels skipped" do
    Shop::OrderReadyPresence.mark_offline!(@order.id)

    logs = capture_cascade_logs do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end

    assert_no_match(/Paid channels skipped/, logs)
  end

  test "#39 cache read failure re-raises and does not swallow" do
    original = Rails.cache.method(:read)
    Rails.cache.define_singleton_method(:read) do |*_args|
      raise StandardError, "cache 500"
    end

    err = assert_raises(StandardError) do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
    assert_match(/cache 500/, err.message)
  ensure
    Rails.cache.define_singleton_method(:read, original) if original
  end

  test "#39 telegram success logs delivered and does not create SMS log" do
    @customer.update!(telegram_chat_id: "183760838")

    logs = capture_cascade_logs do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end

    assert_match(/Telegram message delivered/, logs)
    assert OrderNotificationLog.exists?(order_id: @order.id, channel: "telegram", status: "sent")
    assert_equal 0, OrderNotificationLog.where(order_id: @order.id, channel: "sms").count
  end

  test "#39 telegram 403 falls back to SMS and logs both" do
    @customer.update!(telegram_chat_id: "183760838")
    ENV["TELEGRAM_FORCE_403"] = "1"

    logs = capture_cascade_logs do
      assert_nothing_raised { Shop::OrderReadyCascadeJob.perform_now(@order.id) }
    end

    assert_match(/Telegram failed.*Fallback to SMS/, logs)
    assert OrderNotificationLog.exists?(order_id: @order.id, channel: "telegram", status: "failed")
    assert OrderNotificationLog.exists?(order_id: @order.id, channel: "sms", status: "sent")
  end

  test "#39 telegram timeout falls back to SMS without failing job" do
    @customer.update!(telegram_chat_id: "183760838")
    ENV["TELEGRAM_FORCE_TIMEOUT"] = "1"

    assert_nothing_raised { Shop::OrderReadyCascadeJob.perform_now(@order.id) }
    assert OrderNotificationLog.exists?(order_id: @order.id, channel: "sms", status: "sent")
  end

  test "#39 telegram 400 clears chat_id and falls back to SMS" do
    @customer.update!(telegram_chat_id: "bad-chat")
    ENV["TELEGRAM_FORCE_400"] = "1"

    assert_nothing_raised { Shop::OrderReadyCascadeJob.perform_now(@order.id) }
    assert_nil @customer.reload.telegram_chat_id
    assert OrderNotificationLog.exists?(order_id: @order.id, channel: "sms", status: "sent")
  end

  test "#39 no telegram_chat_id goes straight to SMS with msg <= 70" do
    @customer.update!(telegram_chat_id: nil)

    assert_difference -> { OrderNotificationLog.where(channel: "sms").count } => 1 do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
    log = OrderNotificationLog.where(order_id: @order.id, channel: "sms").order(:created_at).last
    assert_equal "sent", log.status
    assert_operator log.payload["msg"].to_s.length, :<=, 70
  end

  test "#39 online presence creates no notification logs" do
    Shop::OrderReadyPresence.mark_online!(@order.id)
    @customer.update!(telegram_chat_id: "183760838")

    assert_no_difference -> { OrderNotificationLog.count } do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
  end

  private

  def capture_cascade_logs
    io = StringIO.new
    old = Rails.logger
    Rails.logger = Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = old
  end
end
