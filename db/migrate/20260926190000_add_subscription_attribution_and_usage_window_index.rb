# frozen_string_literal: true

# Задачи-3 Патч 1: attribution на purchase + index для 7d usage window.
class AddSubscriptionAttributionAndUsageWindowIndex < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :utm_campaign, :string, limit: 255
    add_column :subscriptions, :utm_content, :string, limit: 255
    add_column :subscriptions, :offer_channel, :string, limit: 32

    add_check_constraint :subscriptions,
                         "offer_channel IS NULL OR offer_channel IN ('banner', 'lk', 'push')",
                         name: "chk_subscriptions_offer_channel"

    add_index :subscription_usage_events,
              [ :subscription_id, :created_at ],
              name: "idx_subscription_usage_events_sub_created"
  end
end
