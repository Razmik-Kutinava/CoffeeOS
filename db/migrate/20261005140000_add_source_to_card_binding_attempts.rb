# frozen_string_literal: true

# TASK_102 / #75 Патч 1: происхождение growth-записи журнала + backfill legacy карт/СБП.
# Backfill повторяем вручную: bin/rails growth_ledger:backfill:apply (идемпотентно).
class AddSourceToCardBindingAttempts < ActiveRecord::Migration[8.0]
  def up
    add_column :card_binding_attempts, :source, :string, limit: 32

    CardBindingAttempt.reset_column_information
    Payments::GrowthLedgerBackfill.run!
  end

  def down
    execute <<~SQL.squish
      DELETE FROM card_binding_attempts
       WHERE source IN ('backfill_pre_promo', 'saved_without_promo')
    SQL
    remove_column :card_binding_attempts, :source
  end
end
