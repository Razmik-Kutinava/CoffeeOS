# frozen_string_literal: true

require "test_helper"

# #39 v2 — OrderReadyCascadeJob: presence → SMS.ru (без Telegram)
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
    ENV["SMS_RU_API_ID"] = "test-api-id"
    ENV["SMS_RU_FROM"] = "CoffeeOS"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
  end

  teardown do
    Rails.cache.clear
    %w[SMS_RU_API_ID SMS_RU_FROM SHOP_OTP_LOG_FALLBACK].each { |k| ENV.delete(k) }
  end

  test "#39 v2 OrderReadyCascadeJob is an ApplicationJob and accepts order_id" do
    assert Shop::OrderReadyCascadeJob < ApplicationJob
    assert_nothing_raised do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
  end

  test "#39 v2 ReadyPushJob still enqueues on first ready alongside cascade path" do
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

    assert_enqueued_with(job: Shop::ReadyPushJob, args: [ fresh.id, "preparing" ]) do
      assert_enqueued_with(job: Shop::OrderReadyCascadeJob, args: [ fresh.id ]) do
        Shop::GuestOrderBroadcaster.call(order: fresh, old_status: "preparing")
      end
    end
  ensure
    ENV.delete("FCM_SIMULATE")
    ENV.delete("WALLET_SIMULATE")
  end

  test "#39 v2 when user online via WS skips SMS" do
    Shop::OrderReadyPresence.mark_online!(@order.id)

    logs = capture_cascade_logs do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end

    assert_match(
      /\[Cascade\]\[Order ##{@order.id}\] User is online via WebSocket\. SMS skipped\./,
      logs
    )
    assert_equal 0, OrderNotificationLog.where(order_id: @order.id).count
  end

  test "#39 v2 when user offline does not log SMS skipped" do
    Shop::OrderReadyPresence.mark_offline!(@order.id)

    logs = capture_cascade_logs do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end

    assert_no_match(/SMS skipped\./, logs)
  end

  test "#39 v2 cache read failure re-raises and does not swallow" do
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

  test "#39 v2 offline sends SMS with msg <= 70 and does not use telegram channel" do
    Shop::OrderReadyPresence.mark_offline!(@order.id)
    @customer.update!(telegram_chat_id: "183760838")

    assert_difference -> { OrderNotificationLog.where(channel: "sms").count } => 1 do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
    log = OrderNotificationLog.where(order_id: @order.id, channel: "sms").order(:created_at).last
    assert_equal "sent", log.status
    assert_operator log.payload["msg"].to_s.length, :<=, 70
    assert_equal 0, OrderNotificationLog.where(order_id: @order.id, channel: "telegram").count
  end

  test "Group 4: second cascade does not send duplicate SMS when already sent" do
    Shop::OrderReadyPresence.mark_offline!(@order.id)

    assert_difference -> { OrderNotificationLog.where(order_id: @order.id, channel: "sms", status: "sent").count } => 1 do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end

    logs = capture_cascade_logs do
      assert_no_difference -> { OrderNotificationLog.where(order_id: @order.id, channel: "sms").count } do
        Shop::OrderReadyCascadeJob.perform_now(@order.id)
      end
    end

    assert_match(/SMS skipped: already sent/, logs)
  end

  test "Group 4: cascade enqueued with SMS_GRACE after ready" do
    source = File.read(Rails.root.join("app/services/shop/guest_order_broadcaster.rb"))
    assert_match(/SMS_GRACE/, source)
    assert_operator Shop::OrderReadyCascadeJob::SMS_GRACE, :>=, 5.seconds
  end

  test "#39 v2 online presence creates no notification logs even with telegram_chat_id" do
    Shop::OrderReadyPresence.mark_online!(@order.id)
    @customer.update!(telegram_chat_id: "183760838")

    assert_no_difference -> { OrderNotificationLog.count } do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
  end

  test "#39 v2 SMS network error logs failed and does not raise" do
    Shop::OrderReadyPresence.mark_offline!(@order.id)
    original = Shop::SmsRuClient.method(:send_message!)
    Shop::SmsRuClient.define_singleton_method(:send_message!) do |**_|
      raise Shop::SmsRuClient::Error.new("simulated 502", http_status: 502)
    end

    logs = capture_cascade_logs do
      assert_nothing_raised { Shop::OrderReadyCascadeJob.perform_now(@order.id) }
    end

    assert_match(/SMS\.ru delivery failed:/, logs)
    assert OrderNotificationLog.exists?(order_id: @order.id, channel: "sms", status: "failed")
  ensure
    Shop::SmsRuClient.define_singleton_method(:send_message!, original) if original
  end

  test "#39 v2 PaidNotifier source does not call TelegramBotClient" do
    source = File.read(Rails.root.join("app/services/shop/order_ready_paid_notifier.rb"))
    assert_no_match(/TelegramBotClient/, source)
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
