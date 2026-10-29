# frozen_string_literal: true

require "test_helper"

# TASK_112 [TDD][RED] Subtask 7, 8, 12: нормализация события окружения
class Shop::EnvironmentEventRecorderTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @other = create_tenant!
  end

  def full_payload(**over)
    {
      "event_kind" => "session_open",
      "os_family" => "ios",
      "standalone" => "standalone",
      "notification_state" => "granted",
      "push_manager" => "available",
      "service_worker" => "available",
      "storage_local" => "available",
      "storage_session" => "unavailable",
      "inapp_label" => "none",
      "ua_snippet" => nil
    }.merge(over.transform_keys(&:to_s))
  end

  def record(payload)
    Shop::EnvironmentEventRecorder.call(point_id: @tenant.id, payload: payload)
  end

  test "valid payload stored as is, point from argument" do
    result = record(full_payload)
    assert result.ok?
    event = result.event.reload
    assert_equal @tenant.id, event.point_id
    assert_equal "ios", event.os_family
    assert_equal "standalone", event.standalone
    assert_equal "granted", event.notification_state
    assert_equal "unavailable", event.storage_session
    assert_nil event.ua_snippet
  end

  test "Subtask 12: missing event_kind → session_open; empty payload accepted" do
    result = record(full_payload.except("event_kind"))
    assert result.ok?
    assert_equal "session_open", result.event.event_kind

    empty = record({})
    assert empty.ok?
    e = empty.event
    assert_equal "session_open", e.event_kind
    assert_equal "other", e.os_family
    assert_equal "unavailable", e.standalone
    assert_equal "unavailable", e.notification_state
    assert_equal "unavailable", e.storage_local
    assert_equal "other_inapp", e.inapp_label
  end

  # TASK_111: install_banner_shown стал разрешённым видом — пример неизвестного вида заменён явно.
  test "Subtask 7: unknown event_kind rejected, nothing stored" do
    assert_no_difference -> { ShopEnvironmentEvent.count } do
      result = record(full_payload(event_kind: "bogus_kind"))
      assert_not result.ok?
      assert_equal :unknown_event_kind, result.error
    end
  end

  test "Subtask 7: invalid values normalized to unavailable / other / other_inapp" do
    result = record(full_payload(
      os_family: "windows", standalone: true, notification_state: "prompt",
      push_manager: "yes", service_worker: 1, storage_local: nil, storage_session: { "x" => 1 },
      inapp_label: "tiktok"
    ))
    assert result.ok?
    e = result.event
    assert_equal "other", e.os_family
    assert_equal "unavailable", e.standalone
    assert_equal "unavailable", e.notification_state
    assert_equal "unavailable", e.push_manager
    assert_equal "unavailable", e.service_worker
    assert_equal "unavailable", e.storage_local
    assert_equal "unavailable", e.storage_session
    assert_equal "other_inapp", e.inapp_label
    assert_nil e.ua_snippet
  end

  test "Subtask 7, 8: unknown keys and point/tenant from body ignored" do
    result = record(full_payload(
      point_id: @other.id, tenant_id: @other.id, customer_id: SecureRandom.uuid,
      phone: "+79990000000", user_agent: "Mozilla/5.0 raw", ip: "203.0.113.1"
    ))
    assert result.ok?
    assert_equal @tenant.id, result.event.point_id
  end

  test "Subtask 8: ua_snippet kept only for other_inapp, last 300 chars" do
    ua = "#{'a' * 400}TAIL"
    kept = record(full_payload(inapp_label: "other_inapp", ua_snippet: ua))
    assert_equal 300, kept.event.ua_snippet.length
    assert kept.event.ua_snippet.end_with?("TAIL")

    dropped = record(full_payload(inapp_label: "telegram", ua_snippet: ua))
    assert_nil dropped.event.ua_snippet
  end

  test "point_id required" do
    result = Shop::EnvironmentEventRecorder.call(point_id: nil, payload: full_payload)
    assert_not result.ok?
  end
end
