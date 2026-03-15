class Tenant < ApplicationRecord
  enum type: { sales_point: 'sales_point', production_kitchen: 'production_kitchen' }
  enum status: { active: 'active', warning: 'warning', suspended: 'suspended', blocked: 'blocked', frozen: 'frozen' }

  has_many :users, dependent: :nullify
  has_many :orders, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :cash_shifts, dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :product_tenant_settings, dependent: :destroy
  has_many :ingredient_tenant_stocks, dependent: :destroy
  has_many :stock_movements, dependent: :destroy
  has_many :feature_flags, dependent: :destroy
  has_many :kiosk_settings, dependent: :destroy
  has_many :kiosk_carts, dependent: :destroy
  has_many :kiosk_sessions, dependent: :destroy
  has_many :shifts, dependent: :destroy
  has_many :shift_staffs, dependent: :destroy
  has_many :shift_cash_operations, dependent: :destroy

  validates :name, presence: true
  validates :type, presence: true
  validates :status, presence: true
  validates :country, presence: true, length: { is: 2 }
  validates :currency, presence: true, length: { is: 3 }
end
