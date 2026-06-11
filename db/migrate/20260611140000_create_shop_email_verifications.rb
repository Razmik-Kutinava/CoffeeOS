# frozen_string_literal: true

class CreateShopEmailVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_email_verifications, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :tenant_id, null: false
      t.string :email, null: false, limit: 255
      t.string :session_id, null: false, limit: 64
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :shop_email_verifications, [:tenant_id, :session_id], unique: true,
      name: "index_shop_email_verifications_on_tenant_and_session"
    add_index :shop_email_verifications, [:tenant_id, :email],
      name: "index_shop_email_verifications_on_tenant_and_email"
    add_index :shop_email_verifications, :expires_at

    add_foreign_key :shop_email_verifications, :tenants, column: :tenant_id

    execute <<~SQL.squish
      COMMENT ON TABLE shop_email_verifications IS
        'Подтверждённый email гостя на витрине: tenant + browser session, TTL 24ч; общая для всех web-инстансов';
    SQL
  end
end
