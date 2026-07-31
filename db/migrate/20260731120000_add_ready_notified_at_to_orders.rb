# frozen_string_literal: true

# #35 C1 — идемпотентность ready-push. Откат: remove_column :orders, :ready_notified_at
class AddReadyNotifiedAtToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :ready_notified_at, :timestamptz,
      comment: "Timestamp первого ready-push (#35 C1); NULL = ещё не уведомляли"
  end
end
