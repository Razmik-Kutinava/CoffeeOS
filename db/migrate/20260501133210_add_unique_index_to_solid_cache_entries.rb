class AddUniqueIndexToSolidCacheEntries < ActiveRecord::Migration[8.1]
  def change
    # Добавляем уникальный индекс на key_hash для SolidCache upsert
    # Удаляем существующий индекс если есть, чтобы избежать конфликта
    remove_index :solid_cache_entries, name: "index_solid_cache_entries_on_key_hash_and_namespace" if index_exists?(:solid_cache_entries, name: "index_solid_cache_entries_on_key_hash_and_namespace")
    add_index :solid_cache_entries, :key_hash, unique: true, name: "index_solid_cache_entries_on_key_hash"
  end
end
