class CashShift < ApplicationRecord
  enum status: { open: 'open', closed: 'closed' }

  belongs_to :tenant
  belongs_to :opened_by, class_name: 'User'
  belongs_to :closed_by, class_name: 'User', optional: true

  validates :status, presence: true
  validates :opening_cash, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :closing_cash, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :only_one_open_shift

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :open, -> { where(status: 'open') }
  scope :closed, -> { where(status: 'closed') }
  scope :recent, -> { order(opened_at: :desc) }

  def open?
    status == 'open'
  end

  def close!(closed_by_user, closing_cash_amount)
    update!(
      status: 'closed',
      closed_by: closed_by_user,
      closed_at: Time.current,
      closing_cash: closing_cash_amount
    )
  end

  private

  def only_one_open_shift
    return unless open? && tenant_id

    existing = CashShift.where(tenant_id: tenant_id, status: 'open')
    existing = existing.where.not(id: id) if persisted?

    return unless existing.exists?

    errors.add(:status, 'уже есть открытая смена для этого тенанта')
  end
end
