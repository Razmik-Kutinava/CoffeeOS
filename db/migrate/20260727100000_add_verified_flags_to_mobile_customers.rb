# frozen_string_literal: true

class AddVerifiedFlagsToMobileCustomers < ActiveRecord::Migration[8.0]
  def up
    add_column :mobile_customers, :email_verified, :boolean, null: false, default: false
    add_column :mobile_customers, :phone_verified, :boolean, null: false, default: false

    # Backfill: контакт считается подтверждённым, если поле уже заполнено (легаси OTP-входы).
    execute <<~SQL.squish
      UPDATE mobile_customers
      SET email_verified = TRUE
      WHERE email IS NOT NULL AND email <> ''
    SQL
    execute <<~SQL.squish
      UPDATE mobile_customers
      SET phone_verified = TRUE
      WHERE phone IS NOT NULL AND phone <> ''
    SQL
  end

  def down
    remove_column :mobile_customers, :email_verified
    remove_column :mobile_customers, :phone_verified
  end
end
