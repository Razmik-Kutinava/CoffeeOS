# frozen_string_literal: true

# BACK-003: Создаём таблицу promo_codes для системы промокодов.
# Промокоды дают скидку на заказ, ограничены по датам и количеству использований.
class CreatePromoCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :promo_codes, id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Промокоды для скидок" do |t|
      t.string :code, null: false, limit: 50, comment: "Код промокода (уникальный в тенанте)"
      t.decimal :discount_percentage, precision: 5, scale: 2, null: false, default: 0, comment: "Процент скидки (0-100)"
      t.datetime :valid_from, null: false, comment: "Начало действия промокода"
      t.datetime :valid_to, null: false, comment: "Окончание действия промокода"
      t.integer :max_uses, null: false, default: 0, comment: "Максимальное количество использований (0 = безлимит)"
      t.integer :used_count, null: false, default: 0, comment: "Сколько раз уже использован"
      t.uuid :tenant_id, null: false, comment: "Тенант (точка)"
      t.boolean :is_active, null: false, default: true, comment: "Активен ли промокод"
      t.text :description, comment: "Описание промокода для админа"

      t.timestamps
    end

    add_index :promo_codes, [:tenant_id, :code], unique: true, name: "idx_promo_codes_tenant_code"
    add_index :promo_codes, :tenant_id
    add_index :promo_codes, :is_active
    add_index :promo_codes, :valid_from
    add_index :promo_codes, :valid_to
  end
end
