# frozen_string_literal: true

class ShopEmailOtpAndNullableCustomerPhone < ActiveRecord::Migration[8.0]
  def change
    change_column_null :mobile_customers, :phone, true

    create_table :shop_email_otp_codes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :email, null: false, limit: 255
      t.string :code, null: false, limit: 6
      t.datetime :expires_at, null: false
      t.integer :attempts, null: false, default: 0
      t.boolean :is_used, null: false, default: false
      t.timestamps
    end

    add_index :shop_email_otp_codes, :email
    add_index :shop_email_otp_codes, :expires_at
    add_index :shop_email_otp_codes, [:email, :is_used]

    execute <<~SQL.squish
      COMMENT ON TABLE shop_email_otp_codes IS 'OTP коды подтверждения email на витрине /shop';
    SQL
  end
end
