# frozen_string_literal: true

require "test_helper"

class Shop::GuestOrderBroadcasterTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(phone: "+79003334455")
    @customer.update!(push_enabled: true, push_token: "fcm-broadcaster")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202606-0002",
      source: :mobile,
      status: :accepted,
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )
    ENV["WALLET_SIMULATE"] = "1"
    ENV["FCM_SIMULATE"] = "1"
  end

  teardown do
    ENV.delete("WALLET_SIMULATE")
    ENV.delete("FCM_SIMULATE")
    ENV.delete("WALLET_FORCE_UNAVAILABLE")
    ENV.delete("WALLET_FORCE_GEN_ERROR")
  end

  test "broadcasts mobile order without error" do
    @order.update!(status: :preparing)
    assert_nothing_raised do
      Shop::GuestOrderBroadcaster.call(order: @order.reload, old_status: "accepted")
    end
  end

  test "skips non-mobile orders without error" do
    kiosk = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Kiosk",
      order_number: "202606-0003",
      source: :kiosk,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )

    assert_nothing_raised do
      Shop::GuestOrderBroadcaster.call(order: kiosk)
    end
  end

  # --- #38 шаг 4 [TDD-RED]: APNs update если pass уже есть ---

  test "#38 updates existing wallet pass revision and status_label on broadcast" do
    pass = OrderWalletPass.create!(
      order_id: @order.id,
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      serial_number: "ser-#{SecureRandom.hex(8)}",
      authentication_token: SecureRandom.hex(16),
      pass_type_identifier: "pass.ru.coffeeos.order",
      status_label: "accepted",
      revision: 1
    )

    @order.update!(status: :preparing)
    Shop::GuestOrderBroadcaster.call(order: @order.reload, old_status: "accepted")

    pass.reload
    assert_equal "preparing", pass.status_label
    assert_equal 2, pass.revision
  end

  test "#38 does not create OrderWalletPass when guest never added wallet" do
    @order.update!(status: :preparing)

    assert_no_difference -> { OrderWalletPass.count } do
      Shop::GuestOrderBroadcaster.call(order: @order.reload, old_status: "accepted")
    end
  end

  test "#38 wallet update error soft-fails and still enqueues FCM" do
    OrderWalletPass.create!(
      order_id: @order.id,
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      serial_number: "ser-#{SecureRandom.hex(8)}",
      authentication_token: SecureRandom.hex(16),
      pass_type_identifier: "pass.ru.coffeeos.order",
      status_label: "accepted",
      revision: 1
    )
    ENV["WALLET_FORCE_GEN_ERROR"] = "1"

    @order.update!(status: :preparing)
    assert_nothing_raised do
      assert_enqueued_with(job: Shop::SendPushNotificationJob) do
        Shop::GuestOrderBroadcaster.call(order: @order.reload, old_status: "accepted")
      end
    end
  end

  # --- #39 шаг 1 [TDD-RED]: enqueue OrderReadyCascadeJob на ready ---

  test "#39 enqueues OrderReadyCascadeJob when status becomes ready" do
    @order.update!(status: :ready)

    assert_enqueued_with(job: Shop::OrderReadyCascadeJob, args: [@order.id]) do
      Shop::GuestOrderBroadcaster.call(order: @order.reload, old_status: "preparing")
    end
  end

  test "#39 does not enqueue OrderReadyCascadeJob when status is preparing" do
    @order.update!(status: :preparing)

    assert_no_enqueued_jobs(only: Shop::OrderReadyCascadeJob) do
      Shop::GuestOrderBroadcaster.call(order: @order.reload, old_status: "accepted")
    end
  end

  test "#39 cable soft-fail still enqueues OrderReadyCascadeJob on ready" do
    @order.update!(status: :ready)
    original = Shop::GuestOrderChannel.method(:broadcast_to)
    Shop::GuestOrderChannel.define_singleton_method(:broadcast_to) do |*_args|
      raise StandardError, "cable 502"
    end

    assert_nothing_raised do
      assert_enqueued_with(job: Shop::OrderReadyCascadeJob, args: [@order.id]) do
        Shop::GuestOrderBroadcaster.call(order: @order.reload, old_status: "preparing")
      end
    end
  ensure
    Shop::GuestOrderChannel.define_singleton_method(:broadcast_to, original) if original
  end

  test "#39 skips OrderReadyCascadeJob for non-mobile ready order" do
    kiosk = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Kiosk Ready",
      order_number: "202608-3901",
      source: :kiosk,
      status: :ready,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )

    assert_no_enqueued_jobs(only: Shop::OrderReadyCascadeJob) do
      Shop::GuestOrderBroadcaster.call(order: kiosk, old_status: "preparing")
    end
  end
end
