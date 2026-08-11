# frozen_string_literal: true

require "test_helper"

class Callbacks::SmsRuControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @api_id = "11111111-2222-3333-4444-555555555555"
    ENV["SMS_RU_API_ID"] = @api_id
    Payments::CacheCounter.clear!

    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @order = Order.create!(
      tenant: @tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "ready",
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    @log = OrderNotificationLog.create!(
      order: @order,
      tenant: @tenant,
      channel: "sms",
      status: "sent",
      payload: { "msg" => "hi", "to" => "79001112233", "sms_id" => "201737-100000" }
    )
  end

  teardown do
    ENV.delete("SMS_RU_API_ID")
    Current.reset
    Payments::CacheCounter.clear!
  end

  test "#61 valid sms_status updates delivery_status and returns 100" do
    entry = "sms_status\n201737-100000\n103\n1786346415"
    post callbacks_sms_ru_path, params: signed_params([entry])

    assert_response :success
    assert_equal "100", response.body

    @log.reload
    assert_equal "103", @log.payload["delivery_status"]
    assert_equal "1786346415", @log.payload["delivery_status_at"]
    assert_equal "sent", @log.status
  end

  test "#61 fail delivery status marks log failed" do
    entry = "sms_status\n201737-100000\n104\n1786346415"
    post callbacks_sms_ru_path, params: signed_params([entry])

    assert_response :success
    assert_equal "100", response.body
    @log.reload
    assert_equal "failed", @log.status
    assert_equal "104", @log.payload["delivery_status"]
  end

  test "#61 callcheck_status returns 100 and caches status" do
    entry = "callcheck_status\n201737-542\n401\n1786346415"
    post callbacks_sms_ru_path, params: signed_params([entry])

    assert_response :success
    assert_equal "100", response.body
    raw = Payments::CacheCounter::STORE.read("sms_ru:callcheck:201737-542")
    assert_includes raw, "401"
  end

  test "#61 invalid hash returns 401 without body 100" do
    post callbacks_sms_ru_path, params: {
      "data" => { "1" => "sms_status\n201737-100000\n103\n1" },
      "hash" => "deadbeef"
    }

    assert_response :unauthorized
    assert_not_equal "100", response.body
  end

  test "#61 duplicate sms_status is idempotent" do
    entry = "sms_status\n201737-100000\n103\n1786346415"
    post callbacks_sms_ru_path, params: signed_params([entry])
    post callbacks_sms_ru_path, params: signed_params([entry])

    assert_response :success
    assert_equal "100", response.body
    @log.reload
    assert_equal 1, Array(@log.payload["delivery_status_history"]).size
  end

  private

  def signed_params(entries)
    data = {}
    entries.each_with_index { |e, i| data[(i + 1).to_s] = e }
    hash = Callbacks::SmsRuWebhook.expected_hash(@api_id, entries)
    { "data" => data, "hash" => hash }
  end
end
