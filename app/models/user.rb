class User < ApplicationRecord
  # Временная замена enum для отладки
  # enum status: { active: 'active', blocked: 'blocked' }

  STATUSES = { active: "active", blocked: "blocked" }.freeze

  def active?
    status == "active"
  end

  def blocked?
    status == "blocked"
  end

  belongs_to :tenant, optional: true
  belongs_to :organization, optional: true
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :sessions, dependent: :destroy
  has_many :orders_opened, class_name: "CashShift", foreign_key: "opened_by_id", dependent: :restrict_with_error
  has_many :orders_closed, class_name: "CashShift", foreign_key: "closed_by_id", dependent: :nullify

  validates :name, presence: true
  validates :password_hash, presence: true
  validates :status, presence: true
  validate :email_or_phone_present

  before_validation :normalize_blank_phone

  scope :for_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }
  # scope :active конфликтует с enum методом active?, используем where(status: 'active') напрямую

  def has_role?(role_code)
    roles.exists?(code: role_code)
  end

  def has_any_role?(*role_codes)
    roles.where(code: role_codes).exists?
  end

  # IB Phase 2: role in tenant/org context (see STAFF_RBAC_MATRIX.md).
  # barista/shift_manager/general_manager/prep_kitchen_* — user_roles.tenant_id must match context
  # (or tenant_id nil [TECH DEBT]). franchise_manager — org match. ук_global_admin — global.
  def has_role_in_context?(role_code, tenant_id: Current.tenant_id, organization_id: nil)
    code = role_code.to_s
    return false unless roles.exists?(code: code)

    case code
    when "ук_global_admin"
      true
    when "franchise_manager"
      franchise_manager? && organization_context_match?(organization_id)
    when "barista", "shift_manager", "general_manager"
      point_staff_role_in_context?(code, tenant_id)
    when "prep_kitchen_manager", "prep_kitchen_worker"
      point_staff_role_in_context?(code, tenant_id || self.tenant_id)
    else
      roles.exists?(code: code)
    end
  end

  def has_any_role_in_context?(*role_codes, tenant_id: Current.tenant_id, organization_id: nil)
    role_codes.any? do |code|
      has_role_in_context?(code, tenant_id: tenant_id, organization_id: organization_id)
    end
  end

  def franchise_manager?
    roles.exists?(code: "franchise_manager")
  end

  def uk_global_admin?
    roles.exists?(code: "ук_global_admin")
  end

  def accessible_manager_tenants
    return Tenant.none unless organization_id

    Tenant.where(organization_id: organization_id).order(:name)
  end

  # Проверка пароля через bcrypt
  def authenticate(password)
    return false if password_hash.blank? || password.blank?

    begin
      BCrypt::Password.new(password_hash) == password
    rescue BCrypt::Errors::InvalidHash
      false
    end
  end

  # Установка пароля (хеширование через bcrypt)
  def password=(new_password)
    return if new_password.blank?
    self.password_hash = BCrypt::Password.create(new_password, cost: 12)
  end

  private

  def organization_context_match?(organization_id)
    oid = organization_id || self.organization_id
    oid.present? && self.organization_id&.to_s == oid.to_s
  end

  def point_staff_role_in_context?(role_code, tenant_id)
    role = Role.find_by(code: role_code)
    return false unless role

    bindings = user_roles.where(role_id: role.id)
    return false unless bindings.exists?

    # [TECH DEBT] global user_roles without tenant_id — Phase 3+
    return true if bindings.where(tenant_id: nil).exists?

    tid = tenant_id&.to_s
    return false if tid.blank?

    bindings.where(tenant_id: tid).exists?
  end

  def email_or_phone_present
    return if email.present? || phone.present?
    errors.add(:base, "Email или телефон должен быть указан")
  end

  def normalize_blank_phone
    self.phone = nil if phone.blank?
  end
end
