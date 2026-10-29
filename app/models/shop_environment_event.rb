# frozen_string_literal: true

# TASK_112: снимок окружения витрины. Запись — только через Shop::EnvironmentEventRecorder.
# Наружу (shop API, панели) не отдаётся: читают Metabase (через view) и тесты.
class ShopEnvironmentEvent < ApplicationRecord
  # TASK_110: воронка согласия на push — тот же снимок окружения, свой event_kind.
  EVENT_KINDS = %w[
    session_open
    push_preprompt_shown push_preprompt_accept push_preprompt_later
    push_permission_granted push_permission_denied push_permission_default
  ].freeze
  OS_FAMILIES = %w[ios android other].freeze
  STANDALONE_STATES = %w[standalone browser unavailable].freeze
  NOTIFICATION_STATES = %w[default granted denied unavailable].freeze
  AVAILABILITY = %w[available unavailable].freeze
  INAPP_LABELS = %w[telegram instagram facebook other_inapp none].freeze
  UA_SNIPPET_MAX = 300

  METABASE_VIEW = "v_shop_environment_events"
  # schema.rb не хранит view: тесты создают его этим SQL; миграция содержит ту же копию.
  METABASE_VIEW_SQL = <<~SQL
    CREATE OR REPLACE VIEW v_shop_environment_events AS
    SELECT e.id, e.point_id, t.name AS point_name, e.event_kind,
      (e.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Moscow')::date AS day,
      e.created_at, e.os_family, e.standalone, e.notification_state, e.push_manager,
      e.service_worker, e.storage_local, e.storage_session, e.inapp_label, e.ua_snippet
    FROM shop_environment_events e
    LEFT JOIN tenants t ON t.id = e.point_id
  SQL

  validates :point_id, presence: true
  validates :event_kind, inclusion: { in: EVENT_KINDS }
  validates :os_family, inclusion: { in: OS_FAMILIES }
  validates :standalone, inclusion: { in: STANDALONE_STATES }
  validates :notification_state, inclusion: { in: NOTIFICATION_STATES }
  validates :push_manager, :service_worker, :storage_local, :storage_session, inclusion: { in: AVAILABILITY }
  validates :inapp_label, inclusion: { in: INAPP_LABELS }
  validates :ua_snippet, length: { maximum: UA_SNIPPET_MAX }, allow_nil: true
  validates :ua_snippet, absence: true, unless: -> { inapp_label == "other_inapp" }
end
