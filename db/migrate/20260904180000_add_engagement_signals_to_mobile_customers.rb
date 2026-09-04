# frozen_string_literal: true

# #77: engagement signals for subscription offer eligibility.
class AddEngagementSignalsToMobileCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :mobile_customers, :pwa_installed_at, :datetime
    add_column :mobile_customers, :push_enabled_at, :datetime
    add_column :mobile_customers, :email_collected_at, :datetime
  end
end
