# frozen_string_literal: true

class ShopEmailOtpCode < ApplicationRecord
  validates :email, presence: true
  validates :code, presence: true, length: { is: 6 }
  validates :expires_at, presence: true

  scope :active, ->(email) {
    where(email: email, is_used: false).where("expires_at > ?", Time.current)
  }
end
