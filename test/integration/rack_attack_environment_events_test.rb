# frozen_string_literal: true

require "test_helper"

# TASK_112 [TDD][RED] Subtask 7: частота событий окружения ограничена (Rack::Attack)
class RackAttackEnvironmentEventsTest < ActionDispatch::IntegrationTest
  include TestFactories
  include RackAttackTestHelper

  setup do
    @tenant = create_tenant!
  end

  def post_event(ip)
    post "/shop/api/environment_events?tenant_id=#{@tenant.id}",
         params: { event_kind: "session_open" }.to_json,
         headers: { "CONTENT_TYPE" => "application/json", "REMOTE_ADDR" => ip }
  end

  test "throttle rule exists" do
    assert Rack::Attack.throttles.key?("shop/environment_events/ip")
  end

  test "30 events per minute from one IP pass, 31st → 429" do
    with_rack_attack do
      ip = "203.0.113.40"
      30.times do
        post_event(ip)
        assert_response :no_content
      end
      post_event(ip)
      assert_response :too_many_requests
    end
  end
end
