# frozen_string_literal: true

# #75: журнал попыток привязки card/sbp (method_hash — основной идентификатор).
class CardBindingAttempt < ApplicationRecord
  METHOD_TYPES = %w[card sbp].freeze
  RETENTION = 90.days
  GROWTH_RETENTION = 2.years

  validates :method_type, inclusion: { in: METHOD_TYPES }
  validates :result, presence: true

  def self.phone_digest_for(phone)
    raw = phone.to_s.gsub(/\D/, "")
    return if raw.blank?

    OpenSSL::HMAC.hexdigest(
      "SHA256",
      Payments::SavedCardStore.card_hash_pepper,
      "card_binding_attempts.phone.v1:#{raw}"
    )
  end

  def self.record!(attrs)
    phone = attrs[:phone]
    create!(
      method_type: attrs.fetch(:method_type),
      method_hash: attrs[:method_hash],
      phone: nil,
      phone_digest: phone_digest_for(phone) || attrs[:phone_digest],
      account_id: attrs[:account_id],
      device_fingerprint: attrs[:device_fingerprint],
      ip: attrs[:ip],
      bin: attrs[:bin],
      point_id: attrs[:point_id],
      result: attrs.fetch(:result, "ok"),
      reason: attrs[:reason],
      verification_charge_required: attrs.fetch(:verification_charge_required, false),
      is_growth_event: attrs.fetch(:is_growth_event, false)
    )
  end

  def self.growth_used_for_phone?(phone)
    digest = phone_digest_for(phone)
    return false if digest.blank?

    where(is_growth_event: true, phone_digest: digest).exists?
  end

  def self.growth_used_for_method_hash?(method_hash)
    return false if method_hash.blank?

    where(is_growth_event: true, method_hash: method_hash.to_s).exists?
  end

  # PII retention: обычные попытки — 90д; growth — 2г (только digest/hash).
  def self.purge_expired!
    deleted = where(is_growth_event: false).where("created_at < ?", RETENTION.ago).delete_all
    deleted += where(is_growth_event: true).where("created_at < ?", GROWTH_RETENTION.ago).delete_all
    deleted
  end
end
