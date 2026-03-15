class MobileCustomer < ApplicationRecord
  has_many :mobile_sessions, dependent: :destroy
  has_many :orders, dependent: :nullify

  validates :phone, presence: true, uniqueness: true, format: { with: /\A[+]?[0-9]{10,15}\z/ }
  validates :email, uniqueness: true, allow_nil: true
  validates :is_active, inclusion: { in: [true, false] }
  validates :push_enabled, inclusion: { in: [true, false] }

  scope :active, -> { where(is_active: true) }
  scope :with_push, -> { where(push_enabled: true) }

  def full_name
    [first_name, last_name].compact.join(' ')
  end

  def update_last_login!
    update!(last_login_at: Time.current)
  end
end
