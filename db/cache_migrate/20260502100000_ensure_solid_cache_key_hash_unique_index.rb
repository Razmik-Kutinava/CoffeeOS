# frozen_string_literal: true

# Solid Cache (production cache DB) ожидает upsert по unique_by: :key_hash — нужен уникальный индекс только на key_hash.
# Дубликаты индекса с primary db/migrate допустимы: index_exists? пропускает, если уже есть.
class EnsureSolidCacheKeyHashUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    return unless table_exists?(:solid_cache_entries)

    remove_index :solid_cache_entries,
      name: "index_solid_cache_entries_on_key_hash_and_namespace",
      if_exists: true

    return if index_exists?(:solid_cache_entries, :key_hash, name: "index_solid_cache_entries_on_key_hash")

    add_index :solid_cache_entries, :key_hash, unique: true, name: "index_solid_cache_entries_on_key_hash"
  end
end
