class ShiftCashOperation < ApplicationRecord
  enum operation_type: { deposit: 'deposit', withdrawal: 'withdrawal', collection: 'collection' }

  belongs_to :shift
  belongs_to :tenant
  belongs_to :created_by, class_name: 'User', optional: true

  validates :operation_type, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :recent, -> { order(created_at: :desc) }
end
