# frozen_string_literal: true

# #39 — Telegram chat id гостя для каскада «Заказ готов».
# Откат: remove_column :mobile_customers, :telegram_chat_id
class AddTelegramChatIdToMobileCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :mobile_customers, :telegram_chat_id, :string, limit: 64,
      comment: "Telegram chat_id гостя для OrderReadyCascade (#39)"

    add_index :mobile_customers, :telegram_chat_id,
      unique: true,
      where: "telegram_chat_id IS NOT NULL",
      name: "idx_mobile_customers_telegram_chat_id"
  end
end
