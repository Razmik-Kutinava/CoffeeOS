class MobileCustomer < ApplicationRecord
  has_many :mobile_sessions, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :push_notifications, foreign_key: :customer_id, dependent: :destroy

  validates :phone, uniqueness: true, allow_nil: true,
                    format: { with: /\A[+]?[0-9]{10,15}\z/ }, if: -> { phone.present? }
  validates :email, presence: true, uniqueness: true,
                    format: { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/ }, if: -> { email.present? }
  validate :phone_or_email_present
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

  private

  def phone_or_email_present
    return if phone.present? || email.present?

    errors.add(:base, "Укажите телефон или email")
  end
end
