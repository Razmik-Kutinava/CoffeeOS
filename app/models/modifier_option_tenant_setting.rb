class ModifierOptionTenantSetting < ApplicationRecord
  belongs_to :tenant
  belongs_to :option, class_name: 'ProductModifierOption', foreign_key: 'option_id'
  belongs_to :updated_by, class_name: 'User', optional: true

  validates :price_delta_override, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tenant_id, uniqueness: { scope: :option_id }
end
