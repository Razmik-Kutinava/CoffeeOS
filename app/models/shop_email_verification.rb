# frozen_string_literal: true

class ShopEmailVerification < ApplicationRecord
  belongs_to :tenant

  validates :email, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.active_for(tenant_id:, email:)
    normalized = Shop::EmailVerificationSession.normalize(email)
    return nil if normalized.blank?

    active.find_by(tenant_id: tenant_id, email: normalized)
  end

  def self.upsert_verified!(tenant_id:, email:, expires_at:)
    normalized = Shop::EmailVerificationSession.normalize(email)
    raise ArgumentError, "email required" if normalized.blank?

    record = find_or_initialize_by(tenant_id: tenant_id, email: normalized)
    record.expires_at = expires_at
    record.save!
    record
  end
end
