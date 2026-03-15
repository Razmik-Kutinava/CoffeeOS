class KioskSetting < ApplicationRecord
  belongs_to :tenant
  belongs_to :device

  validates :tenant_id, uniqueness: { scope: :device_id }
  validates :idle_timeout_seconds, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 600 }
  validates :welcome_text, presence: true
  validate :at_least_one_payment_method

  scope :active, -> { where(is_active: true) }
  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }

  def allow_any_payment?
    allow_cash || allow_card
  end

  private

  def at_least_one_payment_method
    return if allow_cash || allow_card

    errors.add(:base, 'Должен быть разрешён хотя бы один способ оплаты')
  end
end
