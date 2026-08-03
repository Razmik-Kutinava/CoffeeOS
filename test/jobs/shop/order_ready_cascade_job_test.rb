# frozen_string_literal: true

require "test_helper"

# #39 шаг 1 [TDD-RED]: skeleton OrderReadyCascadeJob (enqueue from Broadcaster)
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
end
