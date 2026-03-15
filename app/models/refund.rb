class Refund < ApplicationRecord
  enum status: { pending: 'pending', succeeded: 'succeeded', failed: 'failed' }

  belongs_to :tenant
  belongs_to :payment
  belongs_to :order
  belongs_to :initiated_by, class_name: 'User', optional: true
  has_many :fiscal_receipts, dependent: :destroy

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :reason, presence: true
  validates :status, presence: true

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :pending, -> { where(status: 'pending') }
end
