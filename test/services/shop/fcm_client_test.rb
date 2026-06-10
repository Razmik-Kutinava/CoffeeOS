# frozen_string_literal: true

require "test_helper"

class Shop::FcmClientTest < ActiveSupport::TestCase
  setup do
    @old_json = ENV["FIREBASE_SERVICE_ACCOUNT_JSON"]
    @old_project = ENV["FIREBASE_PROJECT_ID"]
    ENV.delete("FIREBASE_SERVICE_ACCOUNT_JSON")
    ENV.delete("FIREBASE_PROJECT_ID")
    Shop::FirebaseConfig.reset_cache!
  end

  teardown do
    ENV["FIREBASE_SERVICE_ACCOUNT_JSON"] = @old_json
    ENV["FIREBASE_PROJECT_ID"] = @old_project
    Shop::FirebaseConfig.reset_cache!
  end

  test "deliver stubs when service account missing" do
    result = Shop::FcmClient.deliver!(token: "x", title: "T", body: "B")
    assert_equal({ stub: true }, result)
  end
end
