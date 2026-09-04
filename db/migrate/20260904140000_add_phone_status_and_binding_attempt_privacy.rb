# frozen_string_literal: true

class AddPhoneStatusAndBindingAttemptPrivacy < ActiveRecord::Migration[8.0]
  def up
    add_column :mobile_customers, :phone_status, :string, limit: 32, null: false, default: "unknown"
    add_column :card_binding_attempts, :phone_digest, :string, limit: 64
    add_index :card_binding_attempts, :phone_digest, name: "idx_card_binding_attempts_phone_digest"
    add_index :card_binding_attempts, [ :is_growth_event, :phone_digest ],
      name: "idx_card_binding_attempts_growth_phone_digest"

    execute <<~SQL.squish
      UPDATE mobile_customers
      SET phone_status = CASE
        WHEN phone IS NULL OR phone = '' THEN 'unknown'
        WHEN phone_verified IS TRUE THEN 'verified'
        ELSE 'unverified'
      END
    SQL

    pepper = ENV["CARD_HASH_PEPPER"].presence ||
      Rails.application.credentials.dig(:payments, :card_hash_pepper).presence ||
      Rails.application.secret_key_base

    say_with_time "backfill card_binding_attempts.phone_digest" do
      connection.select_rows("SELECT id, phone FROM card_binding_attempts WHERE phone IS NOT NULL").each do |id, phone|
        digits = phone.to_s.gsub(/\D/, "")
        next if digits.blank?

        digest = OpenSSL::HMAC.hexdigest("SHA256", pepper, "card_binding_attempts.phone.v1:#{digits}")
        connection.execute(
          "UPDATE card_binding_attempts SET phone_digest = #{connection.quote(digest)}, phone = NULL WHERE id = #{connection.quote(id)}"
        )
      end
    end
  end

  def down
    remove_index :card_binding_attempts, name: "idx_card_binding_attempts_growth_phone_digest"
    remove_index :card_binding_attempts, name: "idx_card_binding_attempts_phone_digest"
    remove_column :card_binding_attempts, :phone_digest
    remove_column :mobile_customers, :phone_status
  end
end
