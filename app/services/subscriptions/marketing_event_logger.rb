# frozen_string_literal: true

module Subscriptions
  # TASK_96: запись событий воронки оффера. Аналитика не должна ломать основной flow:
  # savepoint (requires_new) — чтобы упавший INSERT не абортил внешнюю транзакцию; никогда не бросает.
  class MarketingEventLogger
    def self.log(event_type:, customer_id:, point_id: nil, channel: nil, utm_campaign: nil, utm_content: nil,
                 metadata: {}, occurred_at: Time.current)
      MarketingEvent.transaction(requires_new: true) do
        MarketingEvent.create!(
          event_type: event_type.to_s,
          customer_id: customer_id,
          point_id: point_id,
          channel: channel.presence,
          utm_campaign: utm_campaign.presence,
          utm_content: utm_content.presence,
          metadata: metadata || {},
          occurred_at: occurred_at
        )
      end
    rescue StandardError => e
      Rails.logger.warn("[Subscriptions::MarketingEventLogger] #{event_type}: #{e.class}: #{e.message}")
      nil
    end
  end
end
