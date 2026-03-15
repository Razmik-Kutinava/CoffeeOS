class Payment < ApplicationRecord
  enum method: {
    card: 'card',
    cash: 'cash',
    sbp: 'sbp',
    apple_pay: 'apple_pay',
    google_pay: 'google_pay',
    internal_balance: 'internal_balance',
    mixed: 'mixed'
  }
  enum status: {
    pending: 'pending',
    processing: 'processing',
    succeeded: 'succeeded',
    failed: 'failed',
    refunded: 'refunded',
    partially_refunded: 'partially_refunded',
    requires_review: 'requires_review'
  }

  belongs_to :tenant
  belongs_to :order
  has_many :payment_status_logs, dependent: :destroy
  has_many :payment_polling_attempts, dependent: :destroy
  has_many :refunds, dependent: :destroy
  has_many :fiscal_receipts, dependent: :destroy

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :method, presence: true
  validates :status, presence: true
  validates :provider, presence: true

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :succeeded, -> { where(status: 'succeeded') }
  scope :pending_or_processing, -> { where(status: ['pending', 'processing']) }
end
