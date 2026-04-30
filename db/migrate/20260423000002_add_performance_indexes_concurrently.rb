# frozen_string_literal: true

# BACK-001: Добавляем performance-индексы с CONCURRENTLY чтобы не блокировать таблицы в production.
# disable_ddl_transaction! обязателен при algorithm: :concurrently.
class AddPerformanceIndexesConcurrently < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # payments.created_at — запросы в ReportsController фильтруют по диапазону дат
    unless index_exists?(:payments, :created_at, name: "idx_payments_created_at")
      add_index :payments, :created_at,
                name: "idx_payments_created_at",
                algorithm: :concurrently
    end

    # refunds.created_at — то же для возвратов
    unless index_exists?(:refunds, :created_at, name: "idx_refunds_created_at")
      add_index :refunds, :created_at,
                name: "idx_refunds_created_at",
                algorithm: :concurrently
    end

    # stock_movements (tenant_id, created_at) — отчёты по движениям склада за период
    unless index_exists?(:stock_movements, [:tenant_id, :created_at], name: "idx_stock_movements_tenant_created")
      add_index :stock_movements, [:tenant_id, :created_at],
                name: "idx_stock_movements_tenant_created",
                order: { created_at: :desc },
                algorithm: :concurrently
    end

    # orders.created_at — нужен для сортировки без составного индекса (tenant_id, created_at уже есть)
    # Пропускаем — составной idx покрывает запросы с tenant_id
  end

  def down
    remove_index :payments, name: "idx_payments_created_at", if_exists: true
    remove_index :refunds, name: "idx_refunds_created_at", if_exists: true
    remove_index :stock_movements, name: "idx_stock_movements_tenant_created", if_exists: true
  end
end
