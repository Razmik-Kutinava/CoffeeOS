# frozen_string_literal: true

module Shop
  # #38 — FCM tag / actions / unicode progress по матрице статусов; cancelled — только tag.
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

    # TASK_92 Патч 2: только tag — уведомление отмены заменяет прежнее, без кнопок и прогресса.
    TAG_ONLY_STATUSES = %w[cancelled].freeze

    def self.enrichable?(order)
      status = order.status.to_s
      PROGRESS.key?(status) || TAG_ONLY_STATUSES.include?(status)
    end

    def self.build!(order:)
      raise Error, "forced payload error" if force_error?

      status = order.status.to_s
      return { tag: "order-#{order.id}" } if TAG_ONLY_STATUSES.include?(status)

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
