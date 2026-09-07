class MobileSession < ApplicationRecord
  belongs_to :customer, class_name: "MobileCustomer", foreign_key: "customer_id"

  validates :refresh_token, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  # Bulk revoke — never update_all with one shared refresh_token (UniqueViolation / RUBY-1G).
  def self.deactivate_each!(relation = all)
    relation.find_each(&:deactivate!)
  end

  def active?
    is_active && expires_at > Time.current
  end

  def deactivate!
    update!(
      is_active: false,
      # Unique revoked token: keeps unique index; prevents replay of old refresh_token.
      refresh_token: "revoked-#{id}-#{SecureRandom.hex(16)}"
    )
  end

  def update_last_used!
    update!(last_used_at: Time.current, expires_at: 90.days.from_now)
  end
end
