# frozen_string_literal: true

require "test_helper"

class SlowRequestUxTest < ActionDispatch::IntegrationTest
  test "slow page route sleeps and returns success in local env" do
    skip "slow routes only in local env" unless Rails.env.local?

    ENV["SLOW_QUERY_SLEEP"] = "5.1"
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    get test_slow_page_path
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    assert_response :success
    assert_operator elapsed, :>=, 5.0
    assert_includes response.body, "slow-request-overlay"
    assert_includes response.body, 'data-controller="slow-request"'
  ensure
    ENV.delete("SLOW_QUERY_SLEEP")
  end

  test "slow json route returns payload after delay" do
    skip "slow routes only in local env" unless Rails.env.local?

    ENV["SLOW_QUERY_SLEEP"] = "0.1"
    get test_slow_json_path
    assert_response :success
    assert_equal({ "ok" => true }, response.parsed_body)
  ensure
    ENV.delete("SLOW_QUERY_SLEEP")
  end
end
