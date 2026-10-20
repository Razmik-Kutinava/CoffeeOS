# frozen_string_literal: true

require "test_helper"

# RUBY-1R: внешний клиент шлёт Client-IP, не совпадающий с X-Forwarded-For →
# ActionDispatch::RemoteIp::IpSpoofAttackError в Rails::Rack::Logger → 500 на любом пути.
class ClientIpHeaderSpoofTest < ActionDispatch::IntegrationTest
  SPOOF_HEADERS = {
    "Client-IP" => "198.51.100.7",
    "X-Forwarded-For" => "203.0.113.10"
  }.freeze

  test "mismatched Client-IP and X-Forwarded-For does not raise" do
    assert_nothing_raised { get "/up", headers: SPOOF_HEADERS }
    assert_response :success
  end

  test "remote_ip comes from X-Forwarded-For, Client-IP is ignored" do
    get "/up", headers: SPOOF_HEADERS

    assert_equal "203.0.113.10", request.remote_ip
  end
end
