# frozen_string_literal: true

require "test_helper"

# TASK_92 Патч 1 — временная ошибка FCM наружу только по запросу ReadyPushJob.
class Shop::SendPushNotificationJobTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(
      phone: "+79001113504",
      email: "send-push-#{SecureRandom.hex(3)}@example.com"
    )
    @customer.update!(push_enabled: true, push_token: "fcm-send-push")
    @notification = PushNotification.create!(
      customer_id: @customer.id,
      tenant_id: @tenant.id,
      notification_type: "order_status",
      title: "Заказ готовится",
      body: "Ваш заказ начали готовить",
      payload: { "status" => "preparing" },
      status: :pending
    )
  end

  test "TASK_92 P1 default mode: transient error marks failed and does not raise" do
    with_fcm_raising(Shop::FcmClient::TransientError.new("FCM v1 503")) do
      Shop::SendPushNotificationJob.perform_now(@notification.id)
    end

    assert_equal "failed", @notification.reload.status
    assert_equal "FCM v1 503", @notification.error_message
  end

  test "TASK_92 P1 raise_transient: transient error marks failed and raises" do
    with_fcm_raising(Shop::FcmClient::TransientError.new("FCM v1 503")) do
      assert_raises(Shop::FcmClient::TransientError) do
        Shop::SendPushNotificationJob.perform_now(@notification.id, raise_transient: true)
      end
    end

    assert_equal "failed", @notification.reload.status
  end

  test "TASK_92 P1 raise_transient: permanent error marks failed and does not raise" do
    with_fcm_raising(Shop::FcmClient::Error.new("FCM v1 404: UNREGISTERED")) do
      Shop::SendPushNotificationJob.perform_now(@notification.id, raise_transient: true)
    end

    assert_equal "failed", @notification.reload.status
  end

  private

  def with_fcm_raising(error)
    original = Shop::FcmClient.method(:deliver!)
    Shop::FcmClient.define_singleton_method(:deliver!) { |**_kw| raise error }
    yield
  ensure
    Shop::FcmClient.singleton_class.send(:define_method, :deliver!, original)
  end
end
