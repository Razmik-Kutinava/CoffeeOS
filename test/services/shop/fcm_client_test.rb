# frozen_string_literal: true

require "test_helper"

class Shop::FcmClientTest < ActiveSupport::TestCase
  setup do
    @old_json = ENV["FIREBASE_SERVICE_ACCOUNT_JSON"]
    @old_project = ENV["FIREBASE_PROJECT_ID"]
    @old_simulate = ENV["FCM_SIMULATE"]
    ENV.delete("FIREBASE_SERVICE_ACCOUNT_JSON")
    ENV.delete("FIREBASE_PROJECT_ID")
    ENV.delete("FCM_SIMULATE")
    Shop::FirebaseConfig.reset_cache!
  end

  teardown do
    ENV["FIREBASE_SERVICE_ACCOUNT_JSON"] = @old_json
    ENV["FIREBASE_PROJECT_ID"] = @old_project
    if @old_simulate.nil?
      ENV.delete("FCM_SIMULATE")
    else
      ENV["FCM_SIMULATE"] = @old_simulate
    end
    Shop::FirebaseConfig.reset_cache!
  end

  test "deliver stubs when service account missing" do
    result = Shop::FcmClient.deliver!(token: "x", title: "T", body: "B")
    assert_equal({ stub: true }, result)
  end

  test "deliver simulates when FCM_SIMULATE is set" do
    ENV["FCM_SIMULATE"] = "1"
    result = Shop::FcmClient.deliver!(token: "sim-token", title: "CoffeeOS", body: "Тест")
    assert_equal true, result[:simulated]
    assert_equal "sim-token", result[:token]
  end

  # #94: web/PWA background — SW must own showNotification (tag/actions).
  # Top-level FCM `notification` makes Android skip onBackgroundMessage.
  test "#94 build_message is data-only with title/body in data" do
    client = Shop::FcmClient.new
    payload = client.send(
      :build_message,
      token: "tok-1",
      title: "CoffeeOS",
      body: "🟩⬜⬜ Заказ принят",
      data: { order_id: "ord-1", tag: "order-ord-1", actions: %w[cancel] }
    )

    message = payload.fetch(:message)
    refute message.key?(:notification), "must not send top-level notification for web SW"
    data = message.fetch(:data)
    assert_equal "tok-1", message.fetch(:token)
    assert_equal "CoffeeOS", data["title"]
    assert_equal "🟩⬜⬜ Заказ принят", data["body"]
    assert_equal "ord-1", data["order_id"]
    assert_equal "order-ord-1", data["tag"]
    assert_equal '["cancel"]', data["actions"]
  end
end
