# frozen_string_literal: true

require "test_helper"

class Shop::OrderStatusPushNotifierTest < ActiveSupport::TestCase
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(phone: "+79005556677", email: "push-#{SecureRandom.hex(3)}@example.com")
    @customer.update!(push_enabled: true, push_token: "fcm-test-token")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Push Guest",
      order_number: "202606-0099",
      source: :mobile,
      status: :accepted,
      total_amount: 250,
      discount_amount: 0,
      final_amount: 250
    )
  end

  test "queues push notification on status change" do
    assert_enqueued_with(job: Shop::SendPushNotificationJob) do
      Shop::OrderStatusPushNotifier.call(order: @order, old_status: "pending_payment")
    end

    notification = PushNotification.order(created_at: :desc).first
    assert_equal @customer.id, notification.customer_id
    assert_equal "order_status", notification.notification_type
    assert_equal "Заказ оплачен", notification.title
    assert_equal "pending", notification.status
  end

  test "skips when push disabled" do
    @customer.update!(push_enabled: false)

    assert_no_enqueued_jobs(only: Shop::SendPushNotificationJob) do
      Shop::OrderStatusPushNotifier.call(order: @order)
    end
  end

  test "guest order broadcaster triggers push notifier" do
    @order.update!(status: :preparing)
    assert_enqueued_with(job: Shop::SendPushNotificationJob) do
      Shop::GuestOrderBroadcaster.call(order: @order.reload, old_status: "accepted")
    end
  end

  # B2.1 этап 3 — тексты push при смене статуса баристой
  test "b21 accepted to preparing push body" do
    @order.update!(status: :preparing)

    Shop::OrderStatusPushNotifier.call(order: @order.reload, old_status: "accepted")

    notification = PushNotification.order(created_at: :desc).first
    assert_equal "Ваш заказ начали готовить", notification.body
    assert_equal "Заказ готовится", notification.title
  end

  test "b21 preparing to ready enqueues ReadyPushJob (#35 B3)" do
    @order.update!(status: :ready)
    ENV["WALLET_SIMULATE"] = "1"
    ENV["FCM_SIMULATE"] = "1"

    assert_enqueued_with(job: Shop::ReadyPushJob, args: [@order.id, "preparing"]) do
      Shop::OrderStatusPushNotifier.call(order: @order.reload, old_status: "preparing")
    end

    perform_enqueued_jobs

    notification = PushNotification.order(created_at: :desc).first
    assert_equal Shop::ReadyPushJob::READY_BODY, notification.body
    assert_equal "Заказ готов", notification.title
  ensure
    ENV.delete("WALLET_SIMULATE")
    ENV.delete("FCM_SIMULATE")
  end

  # --- #38 шаг 1 [TDD-RED]: обогащённый FCM payload ---

  test "#38 accepted push has tag cancel action and unicode progress in body" do
    Shop::OrderStatusPushNotifier.call(order: @order, old_status: "pending_payment")

    notification = PushNotification.order(created_at: :desc).first
    assert notification.present?
    assert_equal "order-#{@order.id}", notification.payload["tag"]
    assert_equal %w[cancel], notification.payload["actions"]
    assert_equal "🟩⬜⬜", notification.payload["progress"]
    assert_match(/\A🟩⬜⬜/, notification.body)
  end

  test "#38 preparing push has chat tips actions and unicode progress" do
    @order.update!(status: :preparing)
    Shop::OrderStatusPushNotifier.call(order: @order.reload, old_status: "accepted")

    notification = PushNotification.order(created_at: :desc).first
    assert_equal "order-#{@order.id}", notification.payload["tag"]
    assert_equal %w[chat tips], notification.payload["actions"]
    assert_equal "🟩🟩⬜", notification.payload["progress"]
    assert_match(/\A🟩🟩⬜/, notification.body)
  end

  test "#38 payload builder error soft-fails without enqueue or raise" do
    assert defined?(Shop::OrderStatusPushPayload)

    Shop::OrderStatusPushPayload.stub(:build!, ->(*) { raise Shop::OrderStatusPushPayload::Error, "forced 500" }) do
      assert_nothing_raised do
        assert_no_enqueued_jobs(only: Shop::SendPushNotificationJob) do
          assert_no_difference -> { PushNotification.count } do
            Shop::OrderStatusPushNotifier.call(order: @order, old_status: "pending_payment")
          end
        end
      end
    end
  end
end
