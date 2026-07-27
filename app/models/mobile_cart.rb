# frozen_string_literal: true

class MobileCart < ApplicationRecord
  belongs_to :customer, class_name: "MobileCustomer", foreign_key: :customer_id, optional: false
end
