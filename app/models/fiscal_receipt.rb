class FiscalReceipt < ApplicationRecord
  enum type: { payment: 'payment', refund: 'refund' }
  enum status: { pending: 'pending', sent: 'sent', confirmed: 'confirmed', failed: 'failed' }

  belongs_to :tenant
  belongs_to :order
  belongs_to :payment
  belongs_to :refund, optional: true

  validates :type, presence: true
  validates :status, presence: true
  validates :ofd_provider, presence: true
  validates :receipt_data, presence: true
  validate :refund_consistency

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :pending, -> { where(status: 'pending') }

  private

  def refund_consistency
    return unless type && refund_id

    if type == 'payment' && refund_id.present?
      errors.add(:refund_id, 'не должен быть указан для чека типа payment')
    elsif type == 'refund' && refund_id.blank?
      errors.add(:refund_id, 'должен быть указан для чека типа refund')
    end
  end
end
