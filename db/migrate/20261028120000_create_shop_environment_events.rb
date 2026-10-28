# frozen_string_literal: true

# TASK_112: снимок окружения гостя при открытии витрины (session_open, одно событие на вкладку).
# Без RLS — по прецеденту marketing_events (20260929150000): point_id пишет только сервер
# из tenant resolution, гостя / IP / сырой User-Agent не храним, читают только Metabase и тесты.
# Решение владельца 2026-10-15; пересмотреть до запуска дашбордов для франчайзи.
# point_id без FK, как marketing_events.point_id: журнал не должен мешать удалению точек.
class CreateShopEnvironmentEvents < ActiveRecord::Migration[8.0]
  AVAILABILITY = %w[available unavailable].freeze
  CHECKS = {
    "event_kind" => %w[session_open],
    "os_family" => %w[ios android other],
    "standalone" => %w[standalone browser unavailable],
    "notification_state" => %w[default granted denied unavailable],
    "push_manager" => AVAILABILITY,
    "service_worker" => AVAILABILITY,
    "storage_local" => AVAILABILITY,
    "storage_session" => AVAILABILITY,
    "inapp_label" => %w[telegram instagram facebook other_inapp none]
  }.freeze

  def up
    create_table :shop_environment_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :point_id, null: false
      t.string :event_kind, null: false, limit: 32, default: "session_open"
      t.string :os_family, null: false, limit: 16
      t.string :standalone, null: false, limit: 16
      t.string :notification_state, null: false, limit: 16
      t.string :push_manager, null: false, limit: 16
      t.string :service_worker, null: false, limit: 16
      t.string :storage_local, null: false, limit: 16
      t.string :storage_session, null: false, limit: 16
      t.string :inapp_label, null: false, limit: 16
      t.string :ua_snippet, limit: 300
      t.datetime :created_at, null: false
    end
    add_index :shop_environment_events, %i[point_id created_at], name: "idx_shop_environment_events_point_created"

    CHECKS.each do |column, values|
      list = values.map { |v| "'#{v}'::text" }.join(", ")
      add_check_constraint :shop_environment_events,
                           "#{column}::text = ANY (ARRAY[#{list}])",
                           name: "chk_shop_environment_events_#{column}"
    end
    add_check_constraint :shop_environment_events,
                         "ua_snippet IS NULL OR inapp_label::text = 'other_inapp'::text",
                         name: "chk_shop_environment_events_ua_snippet"

    execute "COMMENT ON TABLE shop_environment_events IS 'TASK_112: shop environment snapshot (session_open), no guest data'"

    execute <<~SQL
      CREATE OR REPLACE VIEW v_shop_environment_events AS
      SELECT e.id, e.point_id, t.name AS point_name, e.event_kind,
        (e.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Moscow')::date AS day,
        e.created_at, e.os_family, e.standalone, e.notification_state, e.push_manager,
        e.service_worker, e.storage_local, e.storage_session, e.inapp_label, e.ua_snippet
      FROM shop_environment_events e
      LEFT JOIN tenants t ON t.id = e.point_id
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS v_shop_environment_events"
    drop_table :shop_environment_events, if_exists: true
  end
end
