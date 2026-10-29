# frozen_string_literal: true

require "test_helper"

# TASK_112 [TDD][RED] Subtask 1, 7, 8, 9, 12: таблица событий окружения витрины
class ShopEnvironmentEventTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Витрина Env")
  end

  def valid_attrs(**over)
    {
      point_id: @tenant.id,
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

  # TASK_110 Subtask 12: + 6 событий воронки согласия на push — переписан явно.
  test "whitelists: session_open + push consent funnel event kinds" do
    assert_equal %w[
      session_open
      push_preprompt_shown push_preprompt_accept push_preprompt_later
      push_permission_granted push_permission_denied push_permission_default
    ], ShopEnvironmentEvent::EVENT_KINDS
    assert_equal %w[ios android other], ShopEnvironmentEvent::OS_FAMILIES
    assert_equal %w[standalone browser unavailable], ShopEnvironmentEvent::STANDALONE_STATES
    assert_equal %w[default granted denied unavailable], ShopEnvironmentEvent::NOTIFICATION_STATES
    assert_equal %w[available unavailable], ShopEnvironmentEvent::AVAILABILITY
    assert_equal %w[telegram instagram facebook other_inapp none], ShopEnvironmentEvent::INAPP_LABELS
    assert_equal 300, ShopEnvironmentEvent::UA_SNIPPET_MAX
  end

  test "Subtask 12: event_kind defaults to session_open" do
    event = ShopEnvironmentEvent.create!(valid_attrs)
    assert_equal "session_open", event.reload.event_kind
  end

  test "Subtask 8: no guest / IP / raw UA columns" do
    cols = ShopEnvironmentEvent.column_names
    %w[customer_id user_id ip ip_address remote_ip user_agent phone email session_id tenant_id].each do |c|
      assert_not_includes cols, c
    end
    assert_includes cols, "point_id"
    assert_includes cols, "ua_snippet"
  end

  test "model rejects unknown values" do
    assert_not ShopEnvironmentEvent.new(valid_attrs(event_kind: "install_shown")).valid?
    assert_not ShopEnvironmentEvent.new(valid_attrs(os_family: "windows")).valid?
    assert_not ShopEnvironmentEvent.new(valid_attrs(storage_local: "yes")).valid?
    assert_not ShopEnvironmentEvent.new(valid_attrs(point_id: nil)).valid?
  end

  test "ua_snippet only with other_inapp" do
    assert_not ShopEnvironmentEvent.new(valid_attrs(ua_snippet: "Mozilla")).valid?
    assert ShopEnvironmentEvent.new(valid_attrs(inapp_label: "other_inapp", ua_snippet: "Mozilla")).valid?
    assert_not ShopEnvironmentEvent.new(valid_attrs(inapp_label: "other_inapp", ua_snippet: "a" * 301)).valid?
  end

  test "DB CHECK guards bypassed validations" do
    now = Time.current
    base = valid_attrs.merge(created_at: now)
    assert_raises(ActiveRecord::StatementInvalid) do
      ShopEnvironmentEvent.transaction(requires_new: true) do
        ShopEnvironmentEvent.insert_all!([ base.merge(event_kind: "install_shown") ])
      end
    end
    assert_raises(ActiveRecord::StatementInvalid) do
      ShopEnvironmentEvent.transaction(requires_new: true) do
        ShopEnvironmentEvent.insert_all!([ base.merge(ua_snippet: "Mozilla") ])
      end
    end
  end

  test "TASK_110 Subtask 12: DB CHECK accepts every funnel event kind" do
    now = Time.current
    ShopEnvironmentEvent::EVENT_KINDS.each do |kind|
      ShopEnvironmentEvent.insert_all!([ valid_attrs.merge(event_kind: kind, created_at: now) ])
    end
    assert_equal ShopEnvironmentEvent::EVENT_KINDS.sort,
      ShopEnvironmentEvent.where(point_id: @tenant.id).distinct.pluck(:event_kind).sort
  end

  test "migration creates the same view SQL as the model" do
    src = Rails.root.glob("db/migrate/*_create_shop_environment_events.rb").first.read
    assert_includes src.squish, ShopEnvironmentEvent::METABASE_VIEW_SQL.squish
  end

  test "Subtask 9: Metabase view exposes day (Moscow), point name and flags" do
    conn = ShopEnvironmentEvent.connection
    conn.execute(ShopEnvironmentEvent::METABASE_VIEW_SQL)
    ShopEnvironmentEvent.create!(valid_attrs(created_at: Time.utc(2026, 10, 27, 22, 30)))

    row = conn.select_one(
      "SELECT point_id, point_name, day, event_kind, os_family, storage_local, inapp_label " \
      "FROM #{ShopEnvironmentEvent::METABASE_VIEW} WHERE point_id = #{conn.quote(@tenant.id)}"
    )
    assert_equal @tenant.id, row["point_id"]
    assert_equal "Витрина Env", row["point_name"]
    assert_equal "2026-10-28", row["day"].to_s
    assert_equal "session_open", row["event_kind"]
    assert_equal "android", row["os_family"]
  end
end
