# frozen_string_literal: true

require "test_helper"

class Payments::SavedCardStoreTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "saved-card-#{SecureRandom.hex(4)}@example.com")
    @order = create_shop_order!(tenant: @tenant, customer: @customer, status: :pending_payment)
    @payment = Payment.create!(
      order_id: @order.id,
      tenant_id: @tenant.id,
      amount: @order.final_amount,
      method: :card,
      provider: "tbank",
      status: :pending
    )
  end

  teardown do
    Current.reset
  end

  test "persists RebillId and masked Pan on CONFIRMED webhook" do
    payload = {
      "Status" => "CONFIRMED",
      "RebillId" => "rebill-token-123",
      "Pan" => "430000******0777",
      "PaymentId" => "999",
      "OrderId" => @order.id.to_s
    }

    assert_difference -> { MobilePaymentMethod.count }, 1 do
      Payments::SavedCardStore.persist_from_tbank!(payment: @payment, payload: payload)
    end

    card = MobilePaymentMethod.primary_for(@customer.id)
    assert_equal "rebill-token-123", card.card_token
    assert_equal "430000******0777", card.card_masked
    assert_equal "Visa", card.card_brand
    assert card.is_default?
  end

  test "second card stays stored primary switches to latest payment" do
    first = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      card_token: "old-token",
      card_masked: "411111******1111",
      card_brand: "Visa",
      payment_type: "card",
      is_active: true,
      is_default: true
    )

    payload = {
      "Status" => "CONFIRMED",
      "RebillId" => "new-token",
      "Pan" => "555555******4444"
    }

    Payments::SavedCardStore.persist_from_tbank!(payment: @payment, payload: payload)

    assert MobilePaymentMethod.exists?(id: first.id)
    assert_not first.reload.is_default?
    assert MobilePaymentMethod.find_by(card_token: "new-token").is_default?
  end

  test "ignores webhook without RebillId" do
    assert_no_difference -> { MobilePaymentMethod.count } do
      Payments::SavedCardStore.persist_from_tbank!(
        payment: @payment,
        payload: { "Status" => "CONFIRMED", "Pan" => "430000******0777" }
      )
    end
  end

  private

  def create_shop_order!(tenant:, customer:, status:)
    Order.create!(
      tenant_id: tenant.id,
      customer_id: customer.id,
      customer_name: customer.full_name,
      order_number: "",
      source: :mobile,
      status: status,
      total_amount: 179,
      discount_amount: 0,
      final_amount: 179
    )
  end
end
