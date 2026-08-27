# frozen_string_literal: true

# #74: partial unique — одна активная card-привязка на card_hash (после data-migration).
class AddUniqueActiveCardHashIndexToMobilePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    add_index :mobile_payment_methods,
              :card_hash,
              unique: true,
              where: "is_active = true AND card_hash IS NOT NULL AND payment_type = 'card'",
              name: "idx_mpm_active_card_hash_unique",
              if_not_exists: true
  end
end
