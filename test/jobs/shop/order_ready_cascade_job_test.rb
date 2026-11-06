# frozen_string_literal: true

require "test_helper"

# #39 v2 — OrderReadyCascadeJob: presence → SMS.ru (без Telegram)
class Shop::OrderReadyCascadeJobTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

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

  test "ready mobile sends SMS even when guest is online on the socket" do
    Shop::OrderReadyPresence.mark_online!(@order.id)
    assert Shop::OrderReadyPresence.online?(@order.id)

    assert_difference -> { OrderNotificationLog.where(order_id: @order.id, channel: "sms", status: "sent").count }, 1 do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end

    msg = OrderNotificationLog.where(order_id: @order.id, channel: "sms", status: "sent").last.payload["msg"].to_s
    assert_match(%r{\ACODE:BLACK\. Готов! coffeeos\.fly\.dev/o/}, msg)
    assert_operator msg.length, :<=, 70
  end

  test "#39 v2 when user offline does not log SMS skipped" do
    Shop::OrderReadyPresence.mark_offline!(@order.id)

    logs = capture_cascade_logs do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end

    assert_no_match(/SMS skipped\./, logs)
  end

  test "cache failure does not block ready SMS (presence is not consulted)" do
    original = Rails.cache.method(:read)
    Rails.cache.define_singleton_method(:read) do |*_args|
      raise StandardError, "cache 500"
    end

    assert_difference -> { OrderNotificationLog.where(order_id: @order.id, channel: "sms", status: "sent").count }, 1 do
      assert_nothing_raised do
        Shop::OrderReadyCascadeJob.perform_now(@order.id)
      end
    end
  ensure
    Rails.cache.define_singleton_method(:read, original) if original
  end

  test "enqueue does not open an SMS grace window" do
    Shop::OrderReadyPresence.mark_online!(@order.id)

    Shop::GuestOrderBroadcaster.send(:enqueue_ready_cascade!, @order)

    assert_not Shop::OrderReadyPresence.in_sms_grace?(@order.id)
    assert Shop::OrderReadyPresence.online?(@order.id), "presence stays; SMS no longer depends on it"
  end

  test "blank phone does not send ready SMS" do
    @customer.update!(phone: nil)

    assert_no_difference -> { OrderNotificationLog.where(order_id: @order.id, channel: "sms").count } do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
  end

  test "#39 v2 offline sends SMS with msg <= 70 and does not use telegram channel" do
    Shop::OrderReadyPresence.mark_offline!(@order.id)
    @customer.update!(telegram_chat_id: "183760838")

    assert_difference -> { OrderNotificationLog.where(channel: "sms").count } => 1 do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
    log = OrderNotificationLog.where(order_id: @order.id, channel: "sms").order(:created_at).last
    assert_equal "sent", log.status
    msg = log.payload["msg"].to_s
    assert_operator msg.length, :<=, 70
    assert_match(%r{\ACODE:BLACK\. Готов! coffeeos\.fly\.dev/o/}, msg)
    refute_match(%r{codeblack\.xyz}, msg)
    assert_no_match(/##{@order.order_number}/, msg)
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

  test "cascade job source does not skip SMS when the socket is online" do
    source = File.read(Rails.root.join("app/jobs/shop/order_ready_cascade_job.rb"))
    assert_no_match(/presence_online\?/, source)
    assert_no_match(/OrderReadyPresence/, source)
    assert_no_match(/User is online via WebSocket/, source)
    assert_not Shop::OrderReadyCascadeJob.const_defined?(:SMS_GRACE)
    assert_not Shop::OrderReadyCascadeJob.const_defined?(:SMS_GRACE_JOB_BUFFER)
  end

  test "online presence still sends SMS and does not use telegram" do
    Shop::OrderReadyPresence.mark_online!(@order.id)
    @customer.update!(telegram_chat_id: "183760838")

    assert_difference -> { OrderNotificationLog.where(order_id: @order.id, channel: "sms", status: "sent").count }, 1 do
      Shop::OrderReadyCascadeJob.perform_now(@order.id)
    end
    assert_equal 0, OrderNotificationLog.where(order_id: @order.id, channel: "telegram").count
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
