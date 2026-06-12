# frozen_string_literal: true

class AddClientOrderUuidToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :client_order_uuid, :uuid, comment: "Идемпотентность shop PWA offline queue"
    add_index :orders, %i[tenant_id client_order_uuid],
      unique: true,
      where: "client_order_uuid IS NOT NULL",
      name: "idx_orders_tenant_client_order_uuid"
  end
end
