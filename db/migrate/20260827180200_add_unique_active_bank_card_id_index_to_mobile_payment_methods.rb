# frozen_string_literal: true

# #74: race-safe uniqueness по raw CardId (legacy rows с card_hash NULL до backfill).
class AddUniqueActiveBankCardIdIndexToMobilePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    add_index :mobile_payment_methods,
              :bank_card_id,
              unique: true,
              where: "is_active = true AND bank_card_id IS NOT NULL AND payment_type = 'card'",
              name: "idx_mpm_active_bank_card_id_unique",
              if_not_exists: true
  end
end
