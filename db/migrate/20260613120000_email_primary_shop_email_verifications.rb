# frozen_string_literal: true

class EmailPrimaryShopEmailVerifications < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      DELETE FROM shop_email_verifications a
      USING shop_email_verifications b
      WHERE a.tenant_id = b.tenant_id
        AND a.email = b.email
        AND a.id <> b.id
        AND (
          a.expires_at < b.expires_at
          OR (a.expires_at = b.expires_at AND a.id::text < b.id::text)
        )
    SQL

    remove_index :shop_email_verifications, name: "index_shop_email_verifications_on_tenant_and_session"
    remove_index :shop_email_verifications, name: "index_shop_email_verifications_on_tenant_and_email"

    change_column_null :shop_email_verifications, :session_id, true

    add_index :shop_email_verifications, %i[tenant_id email], unique: true,
      name: "index_shop_email_verifications_on_tenant_and_email_unique"

    execute <<~SQL.squish
      COMMENT ON TABLE shop_email_verifications IS
        'Подтверждённый email гостя на витрине: tenant + email, TTL 24ч; общая для всех web-инстансов'
    SQL
  end

  def down
    remove_index :shop_email_verifications, name: "index_shop_email_verifications_on_tenant_and_email_unique"

    change_column_null :shop_email_verifications, :session_id, false,
      default: "_legacy"

    add_index :shop_email_verifications, %i[tenant_id session_id], unique: true,
      name: "index_shop_email_verifications_on_tenant_and_session"
    add_index :shop_email_verifications, %i[tenant_id email],
      name: "index_shop_email_verifications_on_tenant_and_email"

    execute <<~SQL.squish
      COMMENT ON TABLE shop_email_verifications IS
        'Подтверждённый email гостя на витрине: tenant + browser session, TTL 24ч; общая для всех web-инстансов'
    SQL
  end
end
