# frozen_string_literal: true

class ShopEmailVerification < ApplicationRecord
  belongs_to :tenant

  validates :email, presence: true
  validates :session_id, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.active_for(tenant_id:, session_id:)
    return nil if session_id.blank?

    active.find_by(tenant_id: tenant_id, session_id: session_id.to_s)
  end

  def self.upsert_verified!(tenant_id:, session_id:, email:, expires_at:)
    normalized = Shop::EmailVerificationSession.normalize(email)
    sid = session_id.to_s
    raise ArgumentError, "session_id required" if sid.blank?

    record = find_or_initialize_by(tenant_id: tenant_id, session_id: sid)
    record.email = normalized
    record.expires_at = expires_at
    record.save!
    record
  end
end
