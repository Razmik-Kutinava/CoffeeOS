# frozen_string_literal: true

# TASK_96: журнал событий воронки оффера подписки (customer-scoped, как subscriptions — без RLS;
# point_id = точка, на которой произошло событие; чтение отчёта фильтруется по point_id).
class CreateMarketingEvents < ActiveRecord::Migration[8.0]
  EVENT_TYPES = %w[banner_shown banner_dismissed lk_viewed offer_opened push_sent push_opened subscription_purchased].freeze

  def up
    create_table :marketing_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :event_type, null: false, limit: 32
      t.uuid :customer_id, null: false
      t.uuid :point_id
      t.string :utm_campaign, limit: 100
      t.string :utm_content, limit: 100
      t.string :channel, limit: 16
      t.datetime :occurred_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :marketing_events, %i[point_id occurred_at], name: "idx_marketing_events_point_occurred"
    add_index :marketing_events, %i[customer_id event_type occurred_at], name: "idx_marketing_events_customer_type"
    add_foreign_key :marketing_events, :mobile_customers, column: :customer_id
    add_check_constraint :marketing_events,
                         "event_type::text = ANY (ARRAY[#{EVENT_TYPES.map { |t| "'#{t}'::text" }.join(', ')}])",
                         name: "chk_marketing_events_event_type"
    add_check_constraint :marketing_events,
                         "channel IS NULL OR channel::text = ANY (ARRAY['banner'::text, 'lk'::text, 'push'::text])",
                         name: "chk_marketing_events_channel"

    execute "COMMENT ON TABLE marketing_events IS 'TASK_96: subscription offer funnel events'"
  end

  def down
    drop_table :marketing_events, if_exists: true
  end
end
