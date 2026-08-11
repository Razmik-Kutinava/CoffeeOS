# frozen_string_literal: true

require "test_helper"

# RED: Shop::SmsRuClient — единый клиент SMS.ru для flash_call (/code/call) и sms (/sms/send).
# Ожидаем: класс Shop::SmsRuClient с методами request_flash_call! и send_sms!, dev-fallback.
class Shop::SmsRuClientTest < ActiveSupport::TestCase
  setup do
    ENV["SMS_RU_API_ID"] = "test-api-id-123"
    ENV["SMS_RU_FROM"] = "CoffeeOS"
    ENV["SHOP_OTP_LOG_FALLBACK"] = "true"
  end

  teardown do
    ENV.delete("SMS_RU_API_ID")
    ENV.delete("SMS_RU_FROM")
    ENV.delete("SHOP_OTP_LOG_FALLBACK")
  end

  # --- flash_call: dev fallback ---

  test "request_flash_call! returns 4-digit code in dev fallback mode" do
    code = Shop::SmsRuClient.request_flash_call!(phone: "+79001112233", ip: "1.2.3.4")
    assert_equal 4, code.length
    assert_match(/\A\d{4}\z/, code)
  end

  test "request_flash_call! accepts phone and ip keyword args" do
    assert_nothing_raised do
      Shop::SmsRuClient.request_flash_call!(phone: "+79001112233", ip: "127.0.0.1")
    end
  end

  # --- sms: dev fallback ---

  test "send_sms! succeeds in dev fallback mode" do
    assert_nothing_raised do
      Shop::SmsRuClient.send_sms!(phone: "+79001112233", code: "5678", ip: "1.2.3.4")
    end
  end

  test "send_sms! accepts phone, code and ip keyword args" do
    assert_nothing_raised do
      Shop::SmsRuClient.send_sms!(phone: "+79001112233", code: "1234", ip: "127.0.0.1")
    end
  end

  # --- error class ---

  test "SmsRuClient::Error is defined" do
    assert_kind_of Class, Shop::SmsRuClient::Error
    assert Shop::SmsRuClient::Error < StandardError
  end

  test "SmsRuClient::Error responds to http_status" do
    err = Shop::SmsRuClient::Error.new("test", http_status: 502)
    assert_equal 502, err.http_status
  end

  # --- #39 шаг 5: send_message! произвольный текст ≤70 ---

  test "#39 send_message! succeeds for msg length 70 in fallback" do
    msg = "x" * 70
    assert_nothing_raised do
      Shop::SmsRuClient.send_message!(phone: "+79001112233", msg: msg)
    end
  end

  test "#39 send_message! raises ValidationError before HTTP when msg > 70" do
    msg = "x" * 71
    err = assert_raises(Shop::SmsRuClient::ValidationError) do
      Shop::SmsRuClient.send_message!(phone: "+79001112233", msg: msg)
    end
    assert_match(/70/, err.message)
  end

  test "#39 send_sms! code path still works (OTP contract)" do
    assert_nothing_raised do
      Shop::SmsRuClient.send_sms!(phone: "+79001112233", code: "9999")
    end
  end

  # --- #48 sms/send Result + sms_id + per-phone ERROR ---

  test "#48 SendResult is defined with sms_id" do
    assert_kind_of Class, Shop::SmsRuClient::SendResult
    result = Shop::SmsRuClient::SendResult.new(sms_id: "000000-1")
    assert_equal "000000-1", result.sms_id
  end

  test "#48 send_message! fallback returns SendResult with fallback sms_id" do
    result = Shop::SmsRuClient.send_message!(phone: "+79001112233", msg: "hi")
    assert_kind_of Shop::SmsRuClient::SendResult, result
    assert_match(/\Afallback-/, result.sms_id.to_s)
  end

  test "#48 send_sms! fallback returns SendResult with fallback sms_id" do
    result = Shop::SmsRuClient.send_sms!(phone: "+79001112233", code: "1234")
    assert_kind_of Shop::SmsRuClient::SendResult, result
    assert_match(/\Afallback-/, result.sms_id.to_s)
  end

  test "#48 send_message! returns sms_id from SMS.ru json when HTTP OK" do
    body = {
      "status" => "OK",
      "status_code" => 100,
      "sms" => {
        "79001112233" => {
          "status" => "OK",
          "status_code" => 100,
          "sms_id" => "000000-10000000"
        }
      },
      "balance" => 4122.56
    }

    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.send_message!(phone: "+79001112233", msg: "hello")
    end

    assert_kind_of Shop::SmsRuClient::SendResult, result
    assert_equal "000000-10000000", result.sms_id
  end

  test "#48 send_message! raises Error when per-phone status is ERROR" do
    body = {
      "status" => "OK",
      "status_code" => 100,
      "sms" => {
        "79001112233" => {
          "status" => "ERROR",
          "status_code" => 207,
          "status_text" => "На этот номер нет маршрута"
        }
      },
      "balance" => 4122.56
    }

    err = assert_raises(Shop::SmsRuClient::Error) do
      with_live_sms_ru_response(body) do
        Shop::SmsRuClient.send_message!(phone: "+79001112233", msg: "hello")
      end
    end
    assert_match(/207/, err.message)
    assert_match(/маршрута|207/, err.message)
    assert_equal 207, err.status_code if err.respond_to?(:status_code)
  end

  # --- #50 sms/status ---

  test "#50 StatusResult is defined" do
    assert_kind_of Class, Shop::SmsRuClient::StatusResult
    r = Shop::SmsRuClient::StatusResult.new(
      sms_id: "000000-1", status_code: 103, status_text: "ok", cost: 0.5, ok: true
    )
    assert_equal 103, r.status_code
    assert r.ok
  end

  test "#50 status! fallback returns delivered StatusResult" do
    results = Shop::SmsRuClient.status!(sms_ids: "fallback-abc")
    assert_equal 1, results.size
    assert_equal "fallback-abc", results.first.sms_id
    assert_equal 103, results.first.status_code
    assert results.first.ok
  end

  test "#50 status! raises ValidationError when sms_ids blank" do
    assert_raises(Shop::SmsRuClient::ValidationError) do
      Shop::SmsRuClient.status!(sms_ids: [])
    end
  end

  test "#50 status! parses json delivery codes" do
    body = {
      "status" => "OK",
      "status_code" => 100,
      "sms" => {
        "000000-000001" => {
          "status" => "OK",
          "status_code" => 103,
          "cost" => 0.50,
          "status_text" => "Сообщение доставлено"
        },
        "000000-000003" => {
          "status" => "ERROR",
          "status_code" => -1,
          "status_text" => "Сообщение не найдено"
        }
      }
    }

    results = nil
    with_live_sms_ru_response(body) do
      results = Shop::SmsRuClient.status!(sms_ids: %w[000000-000001 000000-000003])
    end

    assert_equal 2, results.size
    delivered = results.find { |r| r.sms_id == "000000-000001" }
    missing = results.find { |r| r.sms_id == "000000-000003" }
    assert delivered.ok
    assert_equal 103, delivered.status_code
    refute missing.ok
    assert_equal(-1, missing.status_code)
  end

  test "#50 status! raises when top-level status not OK" do
    body = { "status" => "ERROR", "status_code" => 301, "status_text" => "bad api" }
    err = assert_raises(Shop::SmsRuClient::Error) do
      with_live_sms_ru_response(body) do
        Shop::SmsRuClient.status!(sms_ids: "000000-1")
      end
    end
    assert_equal 301, err.status_code
  end

  private

  # Rails.env.test? всегда включает fallback — для HTTP-пути временно подменяем методы.
  def with_live_sms_ru_response(body)
    klass = Shop::SmsRuClient
    orig_fb = klass.instance_method(:fallback?)
    orig_post = klass.instance_method(:post_json!)
    klass.define_method(:fallback?) { false }
    klass.define_method(:post_json!) { |_uri, _params| body }
    yield
  ensure
    klass.define_method(:fallback?, orig_fb)
    klass.define_method(:post_json!, orig_post)
  end
end
