# frozen_string_literal: true

require "test_helper"

# Полный push pipeline без Google FCM и без физического устройства (FCM_SIMULATE=1).
class Shop::PushPipelineSimulationTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ActiveJob::TestHelper

  setup do
    @old_fcm_simulate = ENV["FCM_SIMULATE"]
    ENV["FCM_SIMULATE"] = "1"

    @tenant = create_tenant!
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista])
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)
    @customer = create_mobile_customer!(email: "push-pipe-#{SecureRandom.hex(4)}@example.com")
    @customer.update!(push_enabled: true, push_token: "fcm-sim-pipeline-token")
    @order = Order.create!(
      tenant_id: @tenant.id,
      cash_shift: @shift,
      customer_id: @customer.id,
      customer_name: "Push Pipeline",
      order_number: "PUSH-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: :accepted,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )
    Current.tenant_id = @tenant.id
    Current.user_id = @barista.id
  end

  teardown do
    Current.reset
    if @old_fcm_simulate.nil?
      ENV.delete("FCM_SIMULATE")
    else
      ENV["FCM_SIMULATE"] = @old_fcm_simulate
    end
  end

  test "barista preparing runs job and marks push sent with b21 body" do
    login_as!(@barista)

    perform_enqueued_jobs do
      patch "/barista/orders/#{@order.id}/update_status",
            params: { status: "preparing" },
            headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_equal "preparing", @order.reload.status

    notification = PushNotification.order(created_at: :desc).first
    assert_not_nil notification
    assert_equal "Ваш заказ начали готовить", notification.body
    assert_equal "sent", notification.status
    assert_not_nil notification.sent_at
  end

  test "notifier plus job simulate ready transition" do
    @order.update!(status: :preparing)

    Shop::OrderStatusPushNotifier.call(order: @order.reload, old_status: "accepted")
    notification = PushNotification.order(created_at: :desc).first

    Shop::SendPushNotificationJob.perform_now(notification.id)

    notification.reload
    assert_equal "Ваш заказ начали готовить", notification.body
    assert_equal "sent", notification.status
  end
end
