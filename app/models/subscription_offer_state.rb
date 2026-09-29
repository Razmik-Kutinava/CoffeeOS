# frozen_string_literal: true

# TASK_95: состояние оффера подписки на гостя (одна запись на customer_id, point-agnostic).
class SubscriptionOfferState < ApplicationRecord
  belongs_to :customer, class_name: "MobileCustomer"

  enum :status, {
    not_shown: "not_shown",
    shown: "shown",
    dismissed: "dismissed",
    viewed_in_lk: "viewed_in_lk",
    purchased: "purchased"
  }, validate: true

  def self.for_customer!(customer_id)
    find_or_create_by!(customer_id: customer_id)
  rescue ActiveRecord::RecordNotUnique
    find_by!(customer_id: customer_id)
  end
end
