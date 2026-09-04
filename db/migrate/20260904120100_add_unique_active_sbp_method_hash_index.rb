# frozen_string_literal: true

# #75: partial unique на активный SBP method_hash (колонка card_hash).
class AddUniqueActiveSbpMethodHashIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :mobile_payment_methods, :card_hash,
      unique: true,
      name: "idx_mpm_active_sbp_method_hash_unique",
      where: "((is_active = true) AND (card_hash IS NOT NULL) AND ((payment_type)::text = 'sbp'::text))"
  end
end
