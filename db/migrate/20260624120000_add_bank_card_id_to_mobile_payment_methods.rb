# frozen_string_literal: true

# B1.12-R1 rev2: CardId из ответа Т-Банка (UserCards.card_id в ТЗ).
class AddBankCardIdToMobilePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    add_column :mobile_payment_methods, :bank_card_id, :string, limit: 64, if_not_exists: true
  end
end
