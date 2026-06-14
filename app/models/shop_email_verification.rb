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

  def self.upsert_verified!(tenant_id:, email:, expires_at:, session_id: nil)
    normalized = Shop::EmailVerificationSession.normalize(email)
    raise ArgumentError, "email required" if normalized.blank?

    record = find_or_initialize_by(tenant_id: tenant_id, email: normalized)
    record.expires_at = expires_at
    assign_legacy_session_id!(record, session_id: session_id, email: normalized)
    record.save!
    record
  end

  def self.assign_legacy_session_id!(record, session_id:, email:)
    return unless record.has_attribute?(:session_id)

    sid = session_id.to_s.presence
    record.session_id = sid if sid.present?
    return if record.session_id.present?

    col = columns_hash["session_id"]
    return if col.nil? || col.null

    record.session_id = "email:#{Digest::SHA256.hexdigest(email.to_s)[0, 16]}"
  end
  private_class_method :assign_legacy_session_id!
end
