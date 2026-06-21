# frozen_string_literal: true

require "test_helper"

class Payments::TbankPaymentSyncTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer = create_mobile_customer!(email: "sync-#{SecureRandom.hex(4)}@example.com")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Sync Guest",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 179,
      discount_amount: 0,
      final_amount: 179
    )
    @payment = Payment.create!(
      order_id: @order.id,
      tenant_id: @tenant.id,
      amount: 179,
      method: :card,
      provider: "tbank",
      status: :pending,
      provider_payment_id: "pay-sync-1"
    )
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    Current.reset
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  test "sync accepts order and saves card when GetState returns CONFIRMED" do
    assert sync_with_state(
      "Status" => "CONFIRMED",
      "PaymentId" => "pay-sync-1",
      "RebillId" => "sync-rebill-1",
      "Pan" => "430000******5953"
    )

    assert @order.reload.accepted?
    assert @payment.reload.succeeded?

    card = MobilePaymentMethod.primary_for(@customer.id)
    assert_equal "sync-rebill-1", card.card_token
    assert_equal "430000******5953", card.card_masked
  end

  test "sync saves card without Pan when RebillId present in GetState" do
    assert sync_with_state(
      "Status" => "CONFIRMED",
      "PaymentId" => "pay-sync-1",
      "RebillId" => "sync-rebill-no-pan"
    )

    card = MobilePaymentMethod.primary_for(@customer.id)
    assert_equal "sync-rebill-no-pan", card.card_token
    assert_equal "•••• ****", card.card_masked
  end

  test "sync on accepted order backfills missing saved card" do
    @payment.update!(status: :succeeded, paid_at: Time.current)
    @order.update!(status: :accepted)

    assert sync_with_state(
      "Status" => "CONFIRMED",
      "PaymentId" => "pay-sync-1",
      "RebillId" => "backfill-rebill",
      "Pan" => "555555******4444"
    )

    card = MobilePaymentMethod.primary_for(@customer.id)
    assert_equal "backfill-rebill", card.card_token
  end

  private

  def sync_with_state(fields)
    adapter = fake_adapter(fields)
    Payments::TbankPaymentSync.sync_order!(order: @order.reload, adapter: adapter)
  end

  def fake_adapter(fields)
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:get_payment_state) do |**|
      { "Success" => true, "ErrorCode" => "0" }.merge(fields)
    end
    adapter
  end
end
