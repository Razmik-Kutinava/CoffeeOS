# frozen_string_literal: true

# TASK_96: событие воронки оффера подписки. Запись — только через Subscriptions::MarketingEventLogger.
class MarketingEvent < ApplicationRecord
  CHANNELS = Subscription::OFFER_CHANNELS

  belongs_to :customer, class_name: "MobileCustomer"
  belongs_to :point, class_name: "Tenant", optional: true

  enum :event_type, {
    banner_shown: "banner_shown",
    banner_dismissed: "banner_dismissed",
    lk_viewed: "lk_viewed",
    offer_opened: "offer_opened",
    push_sent: "push_sent",
    push_opened: "push_opened",
    subscription_purchased: "subscription_purchased"
  }

  OPEN_EVENT_TYPES = %w[offer_opened push_opened].freeze

  validates :occurred_at, presence: true
  validates :channel, inclusion: { in: CHANNELS }, allow_nil: true
end
