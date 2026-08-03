# frozen_string_literal: true

module Shop
  # #38 — FCM tag / actions / unicode progress по матрице статусов.
  class OrderStatusPushPayload
    class Error < StandardError; end

    PROGRESS = {
      "accepted" => "🟩⬜⬜",
      "preparing" => "🟩🟩⬜",
      "ready" => "🟩🟩🟩"
    }.freeze

    ACTIONS = {
      "accepted" => %w[cancel],
      "preparing" => %w[chat tips],
      "ready" => %w[chat tips]
    }.freeze

    def self.enrichable?(order)
      PROGRESS.key?(order.status.to_s)
    end

    def self.build!(order:)
      raise Error, "forced payload error" if force_error?

      status = order.status.to_s
      progress = PROGRESS[status]
      raise Error, "unsupported status for enriched push: #{status}" if progress.blank?

      {
        tag: "order-#{order.id}",
        actions: ACTIONS.fetch(status),
        progress: progress
      }
    end

    def self.force_error?
      ActiveModel::Type::Boolean.new.cast(ENV["PUSH_PAYLOAD_FORCE_ERROR"])
    end
  end
end
