# frozen_string_literal: true

require "test_helper"

# #75 [TDD][RED] card bind refusal maps to blocked_method_taken; method_hash alias.
class Payments::SavedCardStoreBindingResultTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer_a = create_mobile_customer!(email: "bind-res-a-#{SecureRandom.hex(3)}@example.com")
    @customer_b = create_mobile_customer!(email: "bind-res-b-#{SecureRandom.hex(3)}@example.com")
  end

  teardown do
    Current.reset
  end

  test "method_hash aliases card_hash on mobile_payment_method" do
    card = persist!(@customer_a, card_id: "card-alias-1", rebill: "rebill-alias-1", pan: "220220******8782")
    assert card.persisted?
    assert_equal card.card_hash, card.method_hash
  end

  test "foreign bind returns blocked_method_taken symbol without raising" do
    first = persist!(@customer_a, card_id: "card-taken-1", rebill: "rebill-taken-a", pan: "220220******1111")
    assert first.persisted?

    result = persist!(@customer_b, card_id: "card-taken-1", rebill: "rebill-taken-b", pan: "220220******1111")
    assert_equal :blocked_method_taken, result
  end

  private

  def persist!(customer, card_id:, rebill:, pan:)
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: customer.id,
      customer_name: "Hash Guest",
      order_number: "",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 100,
      method: :card,
      provider: "tbank",
      status: :succeeded,
      provider_payment_id: "pay-bind-#{SecureRandom.hex(4)}",
      provider_data: { "save_card" => true }
    )

    payload = {
      "Status" => "CONFIRMED",
      "RebillId" => rebill,
      "Pan" => pan,
      "ExpDate" => "1228",
      "CardType" => "MIR",
      "CardId" => card_id
    }

    Payments::SavedCardStore.persist_from_tbank!(payment: payment, payload: payload)
  end
end
