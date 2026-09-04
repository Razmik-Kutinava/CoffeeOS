# frozen_string_literal: true

# #75: журнал попыток привязки card/sbp (method_hash — основной идентификатор).
class CardBindingAttempt < ApplicationRecord
  METHOD_TYPES = %w[card sbp].freeze

  validates :method_type, inclusion: { in: METHOD_TYPES }
  validates :result, presence: true

  def self.record!(attrs)
    create!(
      method_type: attrs.fetch(:method_type),
      method_hash: attrs[:method_hash],
      phone: attrs[:phone],
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
    return false if phone.blank?

    where(is_growth_event: true, phone: phone.to_s).exists?
  end

  def self.growth_used_for_method_hash?(method_hash)
    return false if method_hash.blank?

    where(is_growth_event: true, method_hash: method_hash.to_s).exists?
  end
end
