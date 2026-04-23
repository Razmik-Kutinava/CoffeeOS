class Refund < ApplicationRecord
  enum :status, {
    pending: 'pending',
    succeeded: 'succeeded',
    failed: 'failed'
  }

  belongs_to :tenant
  belongs_to :payment
  belongs_to :order
  belongs_to :initiated_by, class_name: 'User', optional: true
  has_many :fiscal_receipts, dependent: :destroy

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :reason, presence: true
  validates :status, presence: true
  # BUG-009 FIX: Сумма возврата не может превышать неиспользованный остаток платежа.
  validate :amount_does_not_exceed_refundable

  private

  def amount_does_not_exceed_refundable
    return unless amount && payment

    # FIX: Add lock on payment to prevent race condition in refund validation
    already_refunded = payment.lock.refunds.where.not(id: id).where(status: %w[pending succeeded]).sum(:amount)
    refundable = payment.amount - already_refunded
    return if amount <= refundable

    errors.add(:amount, "не может превышать доступную к возврату сумму (#{refundable})")
  end

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :pending, -> { where(status: 'pending') }
end
