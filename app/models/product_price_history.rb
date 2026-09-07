class ProductPriceHistory < ApplicationRecord
  belongs_to :tenant
  belongs_to :product
  belongs_to :changed_by, class_name: "User", optional: true

  validates :price_new, presence: true, numericality: { greater_than_or_equal_to: Payments::AmountLimits::MIN_CHARGE_RUB }
  validates :price_old, numericality: { greater_than_or_equal_to: Payments::AmountLimits::MIN_CHARGE_RUB }, allow_nil: true

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :recent, -> { order(created_at: :desc) }
end
