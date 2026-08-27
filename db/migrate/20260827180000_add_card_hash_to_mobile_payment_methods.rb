# frozen_string_literal: true

# #74: nullable card_hash (backfill + dedupe rake до unique index — см. 20260827180100).
class AddCardHashToMobilePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    add_column :mobile_payment_methods, :card_hash, :string, limit: 64, if_not_exists: true
  end
end
