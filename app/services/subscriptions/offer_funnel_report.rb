# frozen_string_literal: true

module Subscriptions
  # TASK_96: минимальная агрегация воронки оффера по event_type × channel за период на точке.
  class OfferFunnelReport
    def self.call(point_id:, from:, to:)
      new(point_id: point_id, from: from, to: to).call
    end

    def initialize(point_id:, from:, to:)
      @point_id = point_id
      @from = from
      @to = to
    end

    def call
      counts = MarketingEvent.where(point_id: @point_id, occurred_at: @from..@to)
        .group(:event_type, :channel)
        .count

      rows = counts.map { |(event_type, channel), count| { event_type: event_type, channel: channel, count: count } }
        .sort_by { |r| [ r[:event_type], r[:channel].to_s ] }
      totals = rows.each_with_object(Hash.new(0)) { |r, acc| acc[r[:event_type]] += r[:count] }

      { from: @from, to: @to, rows: rows, totals: totals }
    end
  end
end
