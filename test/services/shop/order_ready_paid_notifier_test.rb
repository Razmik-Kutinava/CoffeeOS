# frozen_string_literal: true

require "test_helper"

# #48 [TDD-RED]: OrderReadyPaidNotifier пишет sms_id из SmsRuClient::SendResult в payload лога.
class Shop::OrderReadyPaidNotifierTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(
      phone: "+79004880001",
      email: "notifier-#{SecureRandom.hex(3)}@example.com"
    )
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Notifier",
      order_number: "202608-4801",
      source: :mobile,
      status: :ready,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
  end

  teardown do
    if @send_message_original
      Shop::SmsRuClient.define_singleton_method(:send_message!, @send_message_original)
    end
  end

  test "#48 writes sms_id into order_notification_logs.payload on sent" do
    @send_message_original = Shop::SmsRuClient.method(:send_message!)
    fake = Struct.new(:sms_id).new("000000-48000001")
    Shop::SmsRuClient.define_singleton_method(:send_message!) do |**_|
      fake
    end

    Shop::OrderReadyPaidNotifier.call(order: @order)

    log = OrderNotificationLog.where(order_id: @order.id, channel: "sms", status: "sent").order(:created_at).last
    assert log, "expected sms sent log"
    assert_equal "000000-48000001", log.payload["sms_id"]
  end
end
