class IngredientTenantStock < ApplicationRecord
  belongs_to :tenant
  belongs_to :ingredient

  validates :tenant_id, uniqueness: { scope: :ingredient_id }
  validates :qty, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :min_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :low_stock, -> { where('qty <= min_qty AND min_qty > 0') }
  scope :out_of_stock, -> { where(qty: 0) }

  def low_stock?
    min_qty.present? && min_qty > 0 && qty <= min_qty
  end

  def out_of_stock?
    qty.zero?
  end
end
