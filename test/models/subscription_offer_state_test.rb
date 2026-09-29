# frozen_string_literal: true

require "test_helper"

# TASK_95 [TDD][RED] Subtask 1–3: subscription_offer_states — одна запись на гостя
class SubscriptionOfferStateTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @customer = create_mobile_customer!(email: "sos-#{SecureRandom.hex(4)}@example.com")
  end

  test "table has required columns" do
    cols = SubscriptionOfferState.column_names
    %w[customer_id status first_shown_at last_dismissed_at completed_orders_count_at_dismissal
       unread_since created_at updated_at].each do |col|
      assert_includes cols, col
    end
  end

  test "defaults to not_shown and supports all statuses" do
    state = SubscriptionOfferState.create!(customer_id: @customer.id)
    assert_equal "not_shown", state.status

    %w[shown dismissed viewed_in_lk purchased not_shown].each do |status|
      state.update!(status: status)
      assert_equal status, state.reload.status
    end
  end

  test "db enforces one state per customer" do
    SubscriptionOfferState.create!(customer_id: @customer.id)
    assert_raises(ActiveRecord::RecordNotUnique) do
      SubscriptionOfferState.insert!({ customer_id: @customer.id, status: "shown" })
    end
  end

  test "for_customer! is find-or-create without duplicates" do
    first = SubscriptionOfferState.for_customer!(@customer.id)
    second = SubscriptionOfferState.for_customer!(@customer.id)

    assert_equal first.id, second.id
    assert_equal 1, SubscriptionOfferState.where(customer_id: @customer.id).count
  end
end
