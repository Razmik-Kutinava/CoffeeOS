class KioskCart < ApplicationRecord
  belongs_to :tenant
  belongs_to :device

  validates :session_token, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :items_format

  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def empty?
    items.blank? || items == []
  end

  private

  def items_format
    return if items.is_a?(Array)

    errors.add(:items, 'должен быть массивом')
  end
end
