# frozen_string_literal: true

# t.references :semifinished уже создаёт index_production_batches_on_semifinished_id;
# оставляем один индекс с именем из батча B5.
class RemoveDuplicateProductionBatchesSemifinishedIndex < ActiveRecord::Migration[8.1]
  def up
    remove_index :production_batches, name: "index_production_batches_on_semifinished_id", if_exists: true
  end

  def down
    add_index :production_batches, :semifinished_id, name: "index_production_batches_on_semifinished_id", if_not_exists: true
  end
end
