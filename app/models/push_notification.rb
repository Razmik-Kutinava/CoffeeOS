# frozen_string_literal: true

class PushNotification < ApplicationRecord
  belongs_to :customer, class_name: "MobileCustomer"
  belongs_to :tenant, optional: true

  enum :status, { pending: "pending", sent: "sent", failed: "failed", read: "read" }

  validates :notification_type, presence: true, length: { maximum: 50 }
  validates :title, presence: true, length: { maximum: 255 }
  validates :body, presence: true

  scope :due, -> { pending.where("scheduled_at IS NULL OR scheduled_at <= ?", Time.current) }
end
