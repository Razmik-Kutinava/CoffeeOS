# frozen_string_literal: true

# #71 Патч_2: email «куда прислать чек» после оплаты — отдельно от identity-email.
# mobile_customers.email снова только подтверждённый (OTP), его читает TbankReceiptBuilder
# (Receipt.Email/Phone). Патч_1 писал туда неподтверждённый post-pay email → переносим.
class AddReceiptEmailToMobileCustomers < ActiveRecord::Migration[8.0]
  def up
    add_column :mobile_customers, :receipt_email, :string, limit: 255

    execute <<~SQL.squish
      UPDATE mobile_customers
         SET receipt_email = email
       WHERE email IS NOT NULL AND email_verified = false
    SQL
    # Без телефона email — единственный контакт (validate phone_or_email_present) → оставляем.
    execute <<~SQL.squish
      UPDATE mobile_customers
         SET email = NULL
       WHERE email IS NOT NULL AND email_verified = false AND phone IS NOT NULL
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE mobile_customers mc
         SET email = mc.receipt_email
       WHERE mc.email IS NULL
         AND mc.receipt_email IS NOT NULL
         AND NOT EXISTS (SELECT 1 FROM mobile_customers o WHERE o.email = mc.receipt_email)
         AND mc.id = (SELECT MIN(d.id::text)::uuid FROM mobile_customers d WHERE d.receipt_email = mc.receipt_email)
    SQL

    remove_column :mobile_customers, :receipt_email
  end
end
