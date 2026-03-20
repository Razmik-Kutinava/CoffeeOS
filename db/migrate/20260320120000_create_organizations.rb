# frozen_string_literal: true

class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :organizations, :slug, unique: true

    add_reference :tenants, :organization, type: :uuid, foreign_key: true, null: true

    add_reference :users, :organization, type: :uuid, foreign_key: true, null: true
  end
end
