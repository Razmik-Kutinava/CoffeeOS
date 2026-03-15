class KioskSession < ApplicationRecord
  enum end_reason: {
    timeout: 'timeout',
    order_completed: 'order_completed',
    manual_reset: 'manual_reset',
    device_offline: 'device_offline'
  }

  belongs_to :device
  belongs_to :tenant

  validates :session_token, presence: true, uniqueness: true

  scope :active, -> { where(ended_at: nil) }
  scope :ended, -> { where.not(ended_at: nil) }
  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :recent, -> { order(last_activity_at: :desc) }

  def active?
    ended_at.nil?
  end

  def end!(reason)
    update!(ended_at: Time.current, end_reason: reason)
  end
end
