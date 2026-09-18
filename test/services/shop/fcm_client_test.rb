# frozen_string_literal: true

require "test_helper"

class Shop::FcmClientTest < ActiveSupport::TestCase
  include TestFactories

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

  # --- TASK_93-J ---

  def with_fcm_service_account!
    key = OpenSSL::PKey::RSA.generate(2048)
    account = {
      "client_email" => "fcm-j@coffeeos-test.iam.gserviceaccount.com",
      "private_key" => key.to_pem,
      "project_id" => "coffeeos-test"
    }
    ENV["FIREBASE_SERVICE_ACCOUNT_JSON"] = JSON.generate(account)
    ENV["FIREBASE_PROJECT_ID"] = "coffeeos-test"
    Shop::FirebaseConfig.reset_cache!
    Rails.cache.clear
    account
  end

  def stub_fcm_http!(client, oauth_bodies:, fcm_response:)
    oauth_calls = 0
    fcm_calls = 0
    client.define_singleton_method(:http_request) do |uri, _request|
      if uri.host.include?("oauth2")
        oauth_calls += 1
        body = oauth_bodies[oauth_calls - 1] || oauth_bodies.last
        resp = Net::HTTPOK.new("1.1", "200", "OK")
        resp.instance_variable_set(:@read, true)
        resp.define_singleton_method(:body) { body }
        resp
      else
        fcm_calls += 1
        code, body = fcm_response
        resp =
          if code.to_i >= 200 && code.to_i < 300
            Net::HTTPOK.new("1.1", code.to_s, "OK")
          else
            Net::HTTPNotFound.new("1.1", code.to_s, "Not Found")
          end
        resp.instance_variable_set(:@read, true)
        resp.define_singleton_method(:body) { body }
        resp
      end
    end
    -> { [ oauth_calls, fcm_calls ] }
  end

  test "T-J2a second deliver reuses cached access_token (one OAuth HTTP)" do
    with_fcm_service_account!
    client = Shop::FcmClient.new
    counters = stub_fcm_http!(
      client,
      oauth_bodies: [ JSON.generate("access_token" => "oauth-cached", "expires_in" => 3600) ],
      fcm_response: [ 200, JSON.generate("name" => "projects/coffeeos-test/messages/1") ]
    )

    2.times do
      client.deliver!(token: "device-token", title: "T", body: "B")
    end

    oauth_calls, fcm_calls = counters.call
    assert_equal 1, oauth_calls, "OAuth token must be cached across deliver! calls"
    assert_equal 2, fcm_calls
  end

  test "T-J2b UNREGISTERED clears customer push_token and push_enabled" do
    customer = create_mobile_customer!(
      phone: "+7900#{SecureRandom.random_number(10_000_000).to_s.rjust(7, "0")}"
    )
    customer.update!(push_enabled: true, push_token: "dead-fcm-token")
    with_fcm_service_account!
    client = Shop::FcmClient.new
    stub_fcm_http!(
      client,
      oauth_bodies: [ JSON.generate("access_token" => "oauth-1", "expires_in" => 3600) ],
      fcm_response: [
        404,
        JSON.generate(
          "error" => {
            "code" => 404,
            "status" => "NOT_FOUND",
            "details" => [ { "errorCode" => "UNREGISTERED" } ]
          }
        )
      ]
    )

    assert_raises(Shop::FcmClient::Error) do
      client.deliver!(token: customer.push_token, title: "T", body: "B", customer: customer)
    end

    customer.reload
    assert_nil customer.push_token
    assert_equal false, customer.push_enabled
  end

  test "T-J2c simulate mode unchanged with customer arg" do
    ENV["FCM_SIMULATE"] = "1"
    customer = create_mobile_customer!(phone: "+79001112233")
    result = Shop::FcmClient.deliver!(token: "sim-token", title: "T", body: "B", customer: customer)
    assert_equal true, result[:simulated]
    assert_equal "sim-token", result[:token]
  end
end
