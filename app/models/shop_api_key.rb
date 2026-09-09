# frozen_string_literal: true

# V3-SEC-SHOP-API-KEYS: server key for /shop/api — digest only, never store raw.
class ShopApiKey < ApplicationRecord
  belongs_to :tenant, optional: true

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validates :global_ops, inclusion: { in: [ true, false ] }
  validate :tenant_xor_global_ops

  scope :usable, lambda {
    where(active: true, revoked_at: nil)
      .where("expires_at IS NULL OR expires_at > ?", Time.current)
  }

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw.to_s)
  end

  def self.generate_raw_token
    "sk_#{SecureRandom.hex(24)}"
  end

  def usable?
    active? && revoked_at.blank? && (expires_at.blank? || expires_at > Time.current)
  end

  private

  # tenant_id nullable for global_ops — skip ApplicationRecord tenant auto-fill/raise.
  def tenant_id_column?
    false
  end

  def tenant_xor_global_ops
    if global_ops
      errors.add(:tenant_id, "must be blank for global_ops") if tenant_id.present?
    elsif tenant_id.blank?
      errors.add(:tenant_id, "required unless global_ops")
    end
  end
end
