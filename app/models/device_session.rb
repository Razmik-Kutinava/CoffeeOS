class DeviceSession < ApplicationRecord
  belongs_to :device
  belongs_to :tenant

  validates :connection_type, inclusion: { in: %w[websocket http grpc] }

  scope :active, -> { where(disconnected_at: nil) }
  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }

  def active?
    disconnected_at.nil?
  end

  def disconnect!
    update!(disconnected_at: Time.current)
  end
end
