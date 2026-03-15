class StockMovement < ApplicationRecord
  enum movement_type: {
    receipt: 'receipt',
    write_off: 'write_off',
    inventory: 'inventory',
    order_deduct: 'order_deduct',
    return: 'return'
  }
  enum status: { draft: 'draft', confirmed: 'confirmed', cancelled: 'cancelled' }

  belongs_to :tenant
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :confirmed_by, class_name: 'User', optional: true
  belongs_to :order, foreign_key: 'reference_id', optional: true
  has_many :stock_movement_items, dependent: :destroy

  validates :movement_type, presence: true
  validates :status, presence: true

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :draft, -> { where(status: 'draft') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :recent, -> { order(created_at: :desc) }

  def confirm!(confirmed_by_user)
    update!(
      status: 'confirmed',
      confirmed_by: confirmed_by_user,
      confirmed_at: Time.current
    )
  end

  def cancel!
    update!(status: 'cancelled')
  end
end
