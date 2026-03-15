class User < ApplicationRecord
  # Временная замена enum для отладки
  # enum status: { active: 'active', blocked: 'blocked' }
  
  STATUSES = { active: 'active', blocked: 'blocked' }.freeze
  
  def active?
    status == 'active'
  end
  
  def blocked?
    status == 'blocked'
  end

  belongs_to :tenant, optional: true
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :sessions, dependent: :destroy
  has_many :orders_opened, class_name: 'CashShift', foreign_key: 'opened_by', dependent: :restrict_with_error
  has_many :orders_closed, class_name: 'CashShift', foreign_key: 'closed_by', dependent: :nullify

  validates :name, presence: true
  validates :password_hash, presence: true
  validates :status, presence: true
  validate :email_or_phone_present

  scope :for_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }
  # scope :active конфликтует с enum методом active?, используем where(status: 'active') напрямую

  def has_role?(role_code)
    roles.exists?(code: role_code)
  end

  def has_any_role?(*role_codes)
    roles.where(code: role_codes).exists?
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

  def email_or_phone_present
    return if email.present? || phone.present?
    errors.add(:base, 'Email или телефон должен быть указан')
  end
end
