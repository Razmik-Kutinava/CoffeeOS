class ProductTenantSetting < ApplicationRecord
  belongs_to :tenant
  belongs_to :product
  belongs_to :price_updated_by, class_name: 'User', optional: true

  validates :tenant_id, uniqueness: { scope: :product_id }
  validates :price, numericality: { greater_than: 0 }, allow_nil: true
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :enabled_requires_price
  validate :sold_out_reason_consistency

  scope :enabled, -> { where(is_enabled: true) }
  scope :sold_out, -> { where(is_sold_out: true) }
  scope :available, -> { where(is_enabled: true, is_sold_out: false) }

  def available?
    is_enabled && !is_sold_out && price.present?
  end

  private

  def enabled_requires_price
    return unless is_enabled && price.blank?

    errors.add(:price, 'должна быть указана для включённого продукта')
  end

  def sold_out_reason_consistency
    return if is_sold_out == false && sold_out_reason.blank?
    return if is_sold_out == true && sold_out_reason.in?(%w[manual stock_empty])

    errors.add(:sold_out_reason, 'должна быть manual или stock_empty при is_sold_out=true')
  end
end
