class CreateOrderEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :order_emails do |t|
      t.references :order, null: false, foreign_key: true
      t.string :email, null: false
      t.boolean :marketing_consent, null: false, default: false
      t.string :status, null: false, default: "pending"
      t.string :bounce_reason, null: true
      t.timestamps
    end

    add_index :order_emails, [:order_id, :email], unique: true
    add_index :order_emails, :status
    add_index :order_emails, :created_at
  end
end
