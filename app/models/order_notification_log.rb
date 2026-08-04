# frozen_string_literal: true

# #39 — лог каскада уведомлений (Telegram / SMS).
class OrderNotificationLog < ApplicationRecord
  CHANNELS = %w[telegram sms].freeze
  STATUSES = %w[pending sent failed skipped].freeze

  belongs_to :order
  belongs_to :tenant

  validates :channel, inclusion: { in: CHANNELS }
  validates :status, inclusion: { in: STATUSES }
end
