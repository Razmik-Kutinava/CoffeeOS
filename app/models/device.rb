class Device < ApplicationRecord
  belongs_to :tenant
  belongs_to :registered_by, class_name: 'User', optional: true
  has_many :device_sessions, dependent: :destroy
  has_many :order_status_logs, dependent: :nullify
  has_many :kiosk_settings, dependent: :destroy
  has_many :kiosk_carts, dependent: :destroy
  has_many :kiosk_sessions, dependent: :destroy

  validates :device_type, presence: true, inclusion: { in: %w[barista_tablet tv_board kiosk smart_locker] }
  validates :name, presence: true
  validates :device_token, uniqueness: true, allow_nil: true

  scope :active, -> { where(is_active: true) }
  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :online, -> { where('last_seen_at > ?', 2.minutes.ago) }

  def online?
    last_seen_at.present? && last_seen_at > 2.minutes.ago
  end

  def token_valid?
    return false if device_token.blank?
    return true if token_expires_at.blank?

    token_expires_at > Time.current
  end
end
