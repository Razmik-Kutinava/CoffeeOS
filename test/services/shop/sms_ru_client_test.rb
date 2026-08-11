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

  # --- #51 sms/cost ---

  test "#51 CostResult is defined" do
    assert_kind_of Class, Shop::SmsRuClient::CostResult
  end

  test "#51 cost! fallback returns zero cost" do
    result = Shop::SmsRuClient.cost!(phone: "+79001112233", msg: "hi")
    assert_kind_of Shop::SmsRuClient::CostResult, result
    assert result.ok
    assert_equal 0, result.cost
    assert_equal 1, result.sms_count
  end

  test "#51 cost! raises ValidationError when phone or msg blank" do
    assert_raises(Shop::SmsRuClient::ValidationError) do
      Shop::SmsRuClient.cost!(phone: "", msg: "hi")
    end
    assert_raises(Shop::SmsRuClient::ValidationError) do
      Shop::SmsRuClient.cost!(phone: "+79001112233", msg: "")
    end
  end

  test "#51 cost! parses total_cost and per-phone cost" do
    body = {
      "status" => "OK",
      "status_code" => 100,
      "sms" => {
        "79001112233" => {
          "status" => "OK",
          "status_code" => 100,
          "cost" => 0.50,
          "sms" => 1
        }
      },
      "total_cost" => 0.50,
      "total_sms" => 1
    }

    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.cost!(phone: "+79001112233", msg: "hello")
    end

    assert result.ok
    assert_equal 0.50, result.cost
    assert_equal 0.50, result.total_cost
    assert_equal 1, result.sms_count
    assert_equal "79001112233", result.phone
  end

  test "#51 cost! per-phone ERROR sets ok false" do
    body = {
      "status" => "OK",
      "status_code" => 100,
      "sms" => {
        "79001112233" => {
          "status" => "ERROR",
          "status_code" => 207,
          "status_text" => "нет маршрута"
        }
      },
      "total_cost" => 0,
      "total_sms" => 0
    }

    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.cost!(phone: "+79001112233", msg: "hello")
    end

    refute result.ok
    assert_equal 207, result.status_code
  end

  # --- #52 callcheck ---

  test "#52 callcheck_add! fallback returns check_id and call_phone" do
    result = Shop::SmsRuClient.callcheck_add!(phone: "+79001112233")
    assert_kind_of Shop::SmsRuClient::CallcheckAddResult, result
    assert_match(/\Afallback-/, result.check_id)
    assert_equal "74995555555", result.call_phone
    assert_match(/\+7/, result.call_phone_pretty)
  end

  test "#52 callcheck_add! raises when phone blank" do
    assert_raises(Shop::SmsRuClient::ValidationError) do
      Shop::SmsRuClient.callcheck_add!(phone: "")
    end
  end

  test "#52 callcheck_add! parses json" do
    body = {
      "status" => "OK",
      "status_code" => 100,
      "check_id" => "201737-542",
      "call_phone" => "78005008275",
      "call_phone_pretty" => "+7 (800) 500-8275"
    }
    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.callcheck_add!(phone: "+79001112233")
    end
    assert_equal "201737-542", result.check_id
    assert_equal "78005008275", result.call_phone
  end

  test "#52 callcheck_status! fallback is pending" do
    result = Shop::SmsRuClient.callcheck_status!(check_id: "fallback-1")
    refute result.confirmed
    assert_equal Shop::SmsRuClient::CALLCHECK_PENDING, result.check_status
  end

  test "#52 callcheck_status! confirmed when 401" do
    body = {
      "status" => "OK",
      "status_code" => 100,
      "check_status" => "401",
      "check_status_text" => "Авторизация по звонку: номер подтвержден"
    }
    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.callcheck_status!(check_id: "201737-542")
    end
    assert result.confirmed
    assert_equal 401, result.check_status
  end

  # --- #53 my/balance ---

  test "#53 balance! fallback returns zero" do
    result = Shop::SmsRuClient.balance!
    assert_kind_of Shop::SmsRuClient::BalanceResult, result
    assert_equal 0.0, result.balance
  end

  test "#53 balance! parses json balance" do
    body = { "status" => "OK", "status_code" => 100, "balance" => 4762.58 }
    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.balance!
    end
    assert_in_delta 4762.58, result.balance, 0.001
  end

  test "#53 balance! raises on top-level ERROR" do
    body = { "status" => "ERROR", "status_code" => 301 }
    err = assert_raises(Shop::SmsRuClient::Error) do
      with_live_sms_ru_response(body) do
        Shop::SmsRuClient.balance!
      end
    end
    assert_equal 301, err.status_code
  end

  # --- #54 my/limit ---

  test "#54 limit! fallback returns zeros" do
    result = Shop::SmsRuClient.limit!
    assert_kind_of Shop::SmsRuClient::LimitResult, result
    assert_equal 0, result.total_limit
    assert_equal 0, result.used_today
  end

  test "#54 limit! parses total_limit and used_today" do
    body = { "status" => "OK", "status_code" => 100, "total_limit" => 100, "used_today" => 7 }
    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.limit!
    end
    assert_equal 100, result.total_limit
    assert_equal 7, result.used_today
  end

  test "#54 limit! raises on top-level ERROR" do
    body = { "status" => "ERROR", "status_code" => 200 }
    err = assert_raises(Shop::SmsRuClient::Error) do
      with_live_sms_ru_response(body) do
        Shop::SmsRuClient.limit!
      end
    end
    assert_equal 200, err.status_code
  end

  # --- #55 my/free ---

  test "#55 free! fallback returns zeros" do
    result = Shop::SmsRuClient.free!
    assert_kind_of Shop::SmsRuClient::FreeResult, result
    assert_equal 0, result.total_free
    assert_equal 0, result.used_today
  end

  test "#55 free! parses total_free and used_today" do
    body = { "status" => "OK", "status_code" => 100, "total_free" => 5, "used_today" => 3 }
    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.free!
    end
    assert_equal 5, result.total_free
    assert_equal 3, result.used_today
  end

  test "#55 free! raises on top-level ERROR" do
    body = { "status" => "ERROR", "status_code" => 301 }
    err = assert_raises(Shop::SmsRuClient::Error) do
      with_live_sms_ru_response(body) do
        Shop::SmsRuClient.free!
      end
    end
    assert_equal 301, err.status_code
  end

  # --- #56 my/senders ---

  test "#56 senders! fallback returns empty list" do
    result = Shop::SmsRuClient.senders!
    assert_kind_of Shop::SmsRuClient::SendersResult, result
    assert_equal [], result.senders
  end

  test "#56 senders! parses senders array" do
    body = { "status" => "OK", "status_code" => 100, "senders" => %w[sender1 sender2] }
    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.senders!
    end
    assert_equal %w[sender1 sender2], result.senders
  end

  test "#56 senders! raises on top-level ERROR" do
    body = { "status" => "ERROR", "status_code" => 200 }
    err = assert_raises(Shop::SmsRuClient::Error) do
      with_live_sms_ru_response(body) do
        Shop::SmsRuClient.senders!
      end
    end
    assert_equal 200, err.status_code
  end

  # --- #57 auth/check ---

  test "#57 auth_check! fallback returns ok" do
    result = Shop::SmsRuClient.auth_check!
    assert_kind_of Shop::SmsRuClient::AuthCheckResult, result
    assert result.ok
    assert_equal 100, result.status_code
  end

  test "#57 auth_check! parses OK response" do
    body = { "status" => "OK", "status_code" => 100 }
    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.auth_check!
    end
    assert result.ok
    assert_equal 100, result.status_code
  end

  test "#57 auth_check! raises on invalid api_id" do
    body = { "status" => "ERROR", "status_code" => 301 }
    err = assert_raises(Shop::SmsRuClient::Error) do
      with_live_sms_ru_response(body) do
        Shop::SmsRuClient.auth_check!
      end
    end
    assert_equal 301, err.status_code
  end

  # --- #58 stoplist/add ---

  test "#58 stoplist_add! fallback returns ok" do
    result = Shop::SmsRuClient.stoplist_add!(phone: "+79001112233", text: "spam")
    assert_kind_of Shop::SmsRuClient::StoplistAddResult, result
    assert result.ok
    assert_equal 100, result.status_code
  end

  test "#58 stoplist_add! raises ValidationError when phone or text blank" do
    assert_raises(Shop::SmsRuClient::ValidationError) do
      Shop::SmsRuClient.stoplist_add!(phone: "", text: "spam")
    end
    assert_raises(Shop::SmsRuClient::ValidationError) do
      Shop::SmsRuClient.stoplist_add!(phone: "+79001112233", text: "")
    end
  end

  test "#58 stoplist_add! parses OK response" do
    body = { "status" => "OK", "status_code" => 100 }
    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.stoplist_add!(phone: "+79001112233", text: "spam")
    end
    assert result.ok
    assert_equal 100, result.status_code
  end

  test "#58 stoplist_add! raises on ERROR" do
    body = { "status" => "ERROR", "status_code" => 202 }
    err = assert_raises(Shop::SmsRuClient::Error) do
      with_live_sms_ru_response(body) do
        Shop::SmsRuClient.stoplist_add!(phone: "+79001112233", text: "spam")
      end
    end
    assert_equal 202, err.status_code
  end

  # --- #59 stoplist/del ---

  test "#59 stoplist_del! fallback returns ok" do
    result = Shop::SmsRuClient.stoplist_del!(phone: "+79001112233")
    assert_kind_of Shop::SmsRuClient::StoplistDelResult, result
    assert result.ok
    assert_equal 100, result.status_code
  end

  test "#59 stoplist_del! raises ValidationError when phone blank" do
    assert_raises(Shop::SmsRuClient::ValidationError) do
      Shop::SmsRuClient.stoplist_del!(phone: "")
    end
  end

  test "#59 stoplist_del! parses OK response" do
    body = { "status" => "OK", "status_code" => 100 }
    result = nil
    with_live_sms_ru_response(body) do
      result = Shop::SmsRuClient.stoplist_del!(phone: "+79001112233")
    end
    assert result.ok
    assert_equal 100, result.status_code
  end

  test "#59 stoplist_del! raises on ERROR" do
    body = { "status" => "ERROR", "status_code" => 202 }
    err = assert_raises(Shop::SmsRuClient::Error) do
      with_live_sms_ru_response(body) do
        Shop::SmsRuClient.stoplist_del!(phone: "+79001112233")
      end
    end
    assert_equal 202, err.status_code
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
