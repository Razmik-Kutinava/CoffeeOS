class Tenant < ApplicationRecord
  # Отключаем STI, так как type используется как обычное поле
  self.inheritance_column = nil

  # Временная замена enum для отладки
  # enum type: { sales_point: 'sales_point', production_kitchen: 'production_kitchen' }
  # enum status: { active: 'active', warning: 'warning', suspended: 'suspended', blocked: 'blocked', frozen: 'frozen' }

  TYPES = { sales_point: "sales_point", production_kitchen: "production_kitchen" }.freeze
  STATUSES = { active: "active", warning: "warning", suspended: "suspended", blocked: "blocked", frozen: "frozen" }.freeze

  def sales_point?
    type == "sales_point"
  end

  def production_kitchen?
    type == "production_kitchen"
  end

  def active?
    status == "active"
  end

  def warning?
    status == "warning"
  end

  def suspended?
    status == "suspended"
  end

  def blocked?
    status == "blocked"
  end

  def frozen?
    status == "frozen"
  end

  belongs_to :organization, optional: true

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
  has_many :weekday_schedules, class_name: "TenantWeekdaySchedule", dependent: :destroy
  has_one :subscription_offer_setting, class_name: "SubscriptionOfferSetting", foreign_key: :point_id,
                                       inverse_of: :point, dependent: :destroy
  has_many :point_campaign_settings, class_name: "PointCampaignSetting", foreign_key: :point_id,
           inverse_of: :point, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :type, presence: true
  validates :status, presence: true
  validates :country, presence: true, length: { is: 2 }
  validates :currency, presence: true, length: { is: 3 }
  validates :code_black_member, inclusion: { in: [ true, false ] }
  validate :slug_not_reserved_for_shop_subdomain
  validate :code_black_member_only_for_sales_point

  # TASK_115: сеть CODE:BLACK — только явный признак; organization_id, slug, название
  # и status не участвуют (закрытая точка остаётся в сети).
  scope :code_black_network, -> { where(code_black_member: true, type: "sales_point") }

  private

  def code_black_member_only_for_sales_point
    return unless code_black_member && !sales_point?

    errors.add(:code_black_member, "Сеть CODE:BLACK — только для точки продаж")
  end

  def slug_not_reserved_for_shop_subdomain
    return if slug.blank?

    reserved = Platform::TenantOnboarding::UrlBuilder::RESERVED_SUBDOMAINS
    return unless reserved.include?(slug.to_s.downcase)

    errors.add(
      :slug,
      "зарезервирован (#{reserved.join(', ')}) — нельзя использовать как поддомен витрины"
    )
  end
end
