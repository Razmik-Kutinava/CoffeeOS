class MobileOtpCode < ApplicationRecord
  validates :phone, presence: true, format: { with: /\A[+]?[0-9]{10,15}\z/ }
  validates :code, presence: true, format: { with: /\A[0-9]{6}\z/ }
  validates :attempts, numericality: { less_than_or_equal_to: 5 }

  scope :active, -> { where(is_used: false).where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :used, -> { where(is_used: true) }

  def expired?
    expires_at <= Time.current
  end

  def valid?
    !is_used && !expired? && attempts < 5
  end

  def increment_attempts!
    increment!(:attempts)
  end

  def mark_as_used!
    update!(is_used: true)
  end
end
