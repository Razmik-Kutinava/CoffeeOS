# frozen_string_literal: true

require "test_helper"

class Payments::TbankAdapterAmountTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @order = Order.create!(
      tenant: @tenant,
      order_number: "ORD-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "pending_payment",
      total_amount: 500,
      discount_amount: 0,
      final_amount: 500
    )
    @payment = Payment.create!(
      order: @order,
      tenant: @tenant,
      amount: 500,
      method: "card",
      provider: "tbank",
      status: "pending"
    )
  end

  test "notification_amount_matches accepts kopecks matching payment and order" do
    assert Payments::TbankAdapter.notification_amount_matches?(@payment, { "Amount" => 50_000 })
  end

  test "notification_amount_matches rejects wrong kopecks" do
    assert_not Payments::TbankAdapter.notification_amount_matches?(@payment, { "Amount" => 100 })
  end

  test "notification_amount_matches rejects when Amount absent" do
    assert_not Payments::TbankAdapter.notification_amount_matches?(@payment, {})
  end
end
