# frozen_string_literal: true

class AddUniqueOfdReceiptIdToFiscalReceipts < ActiveRecord::Migration[8.0]
  def change
    remove_index :fiscal_receipts, name: "index_fiscal_receipts_on_ofd_receipt_id", if_exists: true
    add_index :fiscal_receipts, :ofd_receipt_id,
              unique: true,
              where: "ofd_receipt_id IS NOT NULL",
              name: "index_fiscal_receipts_on_ofd_receipt_id_unique"
  end
end
