# frozen_string_literal: true

class MobileCustomer < ApplicationRecord
  has_many :mobile_sessions, dependent: :destroy
  has_many :mobile_payment_methods, foreign_key: :customer_id, dependent: :destroy, inverse_of: :customer
  has_many :orders, dependent: :nullify
  has_many :push_notifications, foreign_key: :customer_id, dependent: :destroy

  # #75: явный статус телефона (не NULL-check) для antifraud / step-up.
  enum :phone_status, {
    unknown: "unknown",
    unverified: "unverified",
    verified: "verified",
    recycled_risk: "recycled_risk"
  }, default: :unknown

  validates :phone, uniqueness: true, allow_nil: true,
                    format: { with: /\A[+]?[0-9]{10,15}\z/ }, if: -> { phone.present? }
  validates :email, presence: true, uniqueness: true,
                    format: { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/ }, if: -> { email.present? }
  validates :telegram_chat_id, uniqueness: true, allow_nil: true,
                               length: { maximum: 64 }
  validate :phone_or_email_present
  validates :is_active, inclusion: { in: [ true, false ] }
  validates :push_enabled, inclusion: { in: [ true, false ] }

  before_validation :sync_phone_status_from_flags

  scope :active, -> { where(is_active: true) }
  scope :with_push, -> { where(push_enabled: true) }

  def full_name
    [ first_name, last_name ].compact.join(" ")
  end

  def update_last_login!
    update!(last_login_at: Time.current)
  end

  private

  def sync_phone_status_from_flags
    return if phone_status_changed? && phone_status == "recycled_risk"

    if phone.blank?
      self.phone_status = "unknown"
    elsif phone_verified?
      self.phone_status = "verified"
    elsif phone_status == "unknown" || phone_status.blank?
      self.phone_status = "unverified"
    end
  end

  def phone_or_email_present
    return if phone.present? || email.present?

    errors.add(:base, "Укажите телефон или email")
  end
end
