# frozen_string_literal: true

class CreateSolidCacheEntries < ActiveRecord::Migration[8.1]
  def change
    # Защита от повторного создания таблицы
    return if table_exists?(:solid_cache_entries)

    create_table :solid_cache_entries, primary_key: [:key, :namespace] do |t|
      t.binary :value, limit: 1.megabyte
      t.integer :key_hash, null: false
      t.integer :byte_size, null: false
      t.datetime :created_at, null: false
      t.datetime :expires_at
      t.string :key, null: false
      t.string :namespace, null: false
      t.index [:key_hash, :namespace], name: "index_solid_cache_entries_on_key_hash_and_namespace", unique: true
    end
  end
end
