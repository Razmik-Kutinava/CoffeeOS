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
end
