# frozen_string_literal: true

require "test_helper"

# TASK_112 [TDD][RED] Subtask 6, 7, 8, 12: публичный приём события окружения (sendBeacon / fetch keepalive)
class Shop::Api::EnvironmentEventsTest < ActionDispatch::IntegrationTest
  include TestFactories

  URL = "/shop/api/environment_events"

  setup do
    @tenant = create_tenant!
    @other = create_tenant!
  end

  def payload(**over)
    {
      event_kind: "session_open",
      os_family: "android",
      standalone: "browser",
      notification_state: "default",
      push_manager: "available",
      service_worker: "available",
      storage_local: "available",
      storage_session: "available",
      inapp_label: "none"
    }.merge(over)
  end

  def post_beacon(body, tenant_id: @tenant.id, content_type: "application/json")
    url = tenant_id.nil? ? "#{URL}?tenant_id=" : "#{URL}?tenant_id=#{tenant_id}"
    post url, params: body.is_a?(String) ? body : body.to_json, headers: { "CONTENT_TYPE" => content_type }
  end

  test "Subtask 6: guest without auth → 204, event bound to server-resolved point" do
    assert_difference -> { ShopEnvironmentEvent.where(point_id: @tenant.id).count }, 1 do
      post_beacon(payload)
    end
    assert_response :no_content
  end

  test "Subtask 6: beacon without content type (text/plain) parsed too" do
    assert_difference -> { ShopEnvironmentEvent.count }, 1 do
      post_beacon(payload, content_type: "text/plain;charset=UTF-8")
    end
    assert_response :no_content
  end

  test "Subtask 6: point not resolved → refused like other shop API" do
    assert_no_difference -> { ShopEnvironmentEvent.count } do
      post_beacon(payload, tenant_id: nil)
    end
    assert_response :unprocessable_entity

    assert_no_difference -> { ShopEnvironmentEvent.count } do
      post_beacon(payload, tenant_id: SecureRandom.uuid)
    end
    assert_response :not_found
  end

  test "Subtask 12: no event_kind → session_open" do
    post_beacon(payload.except(:event_kind))
    assert_response :no_content
    assert_equal "session_open", ShopEnvironmentEvent.where(point_id: @tenant.id).last.event_kind
  end

  test "Subtask 7: unknown event_kind → 422, nothing stored" do
    assert_no_difference -> { ShopEnvironmentEvent.count } do
      post_beacon(payload(event_kind: "install_banner_shown"))
    end
    assert_response :unprocessable_entity
  end

  test "Subtask 7: oversized body → 413, nothing stored" do
    assert_no_difference -> { ShopEnvironmentEvent.count } do
      post_beacon(payload(junk: "x" * 3000))
    end
    assert_equal 413, response.status
  end

  test "Subtask 7: malformed JSON → 422" do
    assert_no_difference -> { ShopEnvironmentEvent.count } do
      post_beacon("{not json")
    end
    assert_response :unprocessable_entity
  end

  test "Subtask 7, 8: unknown keys, body point_id ignored; no guest data stored" do
    post_beacon(payload(point_id: @other.id, customer_id: SecureRandom.uuid, user_agent: "raw UA", os_family: "symbian"))
    assert_response :no_content
    event = ShopEnvironmentEvent.order(:created_at).last
    assert_equal @tenant.id, event.point_id
    assert_equal "other", event.os_family
    assert_nil event.ua_snippet
  end

  test "scope: table contents not exposed via shop API (GET has no JSON route)" do
    post_beacon(payload)
    get URL, params: { tenant_id: @tenant.id }, headers: { "Accept" => "application/json" }
    assert_not_equal 200, response.status
    assert_not_includes response.body.to_s, "os_family"
  end
end
