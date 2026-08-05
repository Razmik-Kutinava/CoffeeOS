# frozen_string_literal: true

require "test_helper"

# #35 B3 — ReadyPushJob: FCM + Apple Wallet (simulate / fallback) [TDD]
class Shop::ReadyPushJobTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(
      phone: "+79001113503",
      email: "ready-job-#{SecureRandom.hex(3)}@example.com"
    )
    @customer.update!(push_enabled: true, push_token: "fcm-ready-job")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Ready Job",
      order_number: "202607-3503",
      source: :mobile,
      status: :ready,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200,
      ready_notified_at: Time.current
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

  test "#35 B3 job delivers FCM and upserts wallet pass when simulated" do
    assert_difference -> { PushNotification.count } => 1,
                      -> { OrderWalletPass.count } => 1 do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing")
    end

    note = PushNotification.order(created_at: :desc).first
    assert_equal "Заказ готов", note.title
    assert_match(/готов/i, note.body)
    assert_equal "sent", note.status

    pass = OrderWalletPass.find_by!(order_id: @order.id)
    assert_equal "ready", pass.status_label
    assert pass.serial_number.present?
    assert pass.authentication_token.present?
  end

  test "#35 B2 ready push body matches customer spec (order, not coffee)" do
    Shop::ReadyPushJob.perform_now(@order.id, "preparing")

    note = PushNotification.order(created_at: :desc).first
    progress = note.payload["progress"]

    assert_equal "#{progress} Ваш заказ готов, заберите на кассе!", note.body
  end

  test "#35 C1 ReadyPushJob claims ready_notified_at and sends push once" do
    @order.update!(ready_notified_at: nil)

    assert_difference -> { PushNotification.count } => 1 do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing")
    end

    assert @order.reload.ready_notified_at.present?, "job must claim ready_notified_at"

    assert_no_difference -> { PushNotification.count } do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing")
    end
  end

  test "#35 B3 wallet unavailable falls back to FCM only" do
    ENV["WALLET_FORCE_UNAVAILABLE"] = "1"

    assert_difference -> { PushNotification.count } => 1 do
      assert_no_difference -> { OrderWalletPass.count } do
        Shop::ReadyPushJob.perform_now(@order.id, "preparing")
      end
    end
  end

  test "#35 B3 pass generation error raises for ActiveJob retry" do
    ENV["WALLET_FORCE_GEN_ERROR"] = "1"

    assert_raises(Shop::AppleWallet::GenerationError) do
      Shop::ReadyPushJob.perform_now(@order.id, "preparing")
    end
  end

  test "#35 notifier enqueues ReadyPushJob on first ready" do
    fresh = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Fresh Ready",
      order_number: "202607-3503b",
      source: :mobile,
      status: :ready,
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )

    assert_enqueued_with(job: Shop::ReadyPushJob, args: [fresh.id, "preparing"]) do
      Shop::OrderStatusPushNotifier.call(order: fresh, old_status: "preparing")
    end
    assert fresh.reload.ready_notified_at.present?
  end

  test "#35 notifier skips ReadyPushJob when already claimed" do
    assert_no_enqueued_jobs(only: Shop::ReadyPushJob) do
      Shop::OrderStatusPushNotifier.call(order: @order.reload, old_status: "preparing")
    end
  end

  # --- #38 шаг 1 [TDD-RED]: ready FCM тоже с tag/actions/unicode ---

  test "#38 ready push payload has tag chat tips and unicode progress" do
    Shop::ReadyPushJob.perform_now(@order.id, "preparing")

    note = PushNotification.order(created_at: :desc).first
    assert_equal "order-#{@order.id}", note.payload["tag"]
    assert_equal %w[chat tips], note.payload["actions"]
    assert_equal "🟩🟩🟩", note.payload["progress"]
    assert_match(/\A🟩🟩🟩/, note.body)
  end

  # --- #38 шаг 4 [TDD-RED]: не дублировать Wallet hard на ready ---

  test "#38 ReadyPushJob skips PassUpdater when pass already at ready" do
    OrderWalletPass.create!(
      order_id: @order.id,
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      serial_number: "ser-#{SecureRandom.hex(8)}",
      authentication_token: SecureRandom.hex(16),
      pass_type_identifier: "pass.ru.coffeeos.order",
      status_label: "ready",
      revision: 3
    )

    Shop::ReadyPushJob.perform_now(@order.id, "preparing")

    pass = OrderWalletPass.find_by!(order_id: @order.id)
    assert_equal 3, pass.revision
    assert_equal "ready", pass.status_label
    assert PushNotification.order(created_at: :desc).first.present?
  end
end
