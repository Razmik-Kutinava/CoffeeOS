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

  test "sync accepts order when GetState returns CONFIRMED" do
    assert sync_with_state(
      "Status" => "CONFIRMED",
      "PaymentId" => "pay-sync-1"
    )

    assert @order.reload.accepted?
    assert @payment.reload.succeeded?
  end

  test "sync persists UserCards when GetState CONFIRMED includes RebillId and save_card true" do
    @payment.update!(provider_data: { "save_card" => true })

    assert sync_with_state(
      "Status" => "CONFIRMED",
      "PaymentId" => "pay-sync-1",
      "RebillId" => "rebill-sync-5953",
      "Pan" => "220220******5953",
      "ExpDate" => "0927",
      "CardType" => "MIR"
    )

    card = MobilePaymentMethod.find_by(customer_id: @customer.id, card_token: "rebill-sync-5953")
    assert card, "finalize/GetState должен создать UserCards при RebillId"
    assert_equal "*5953", card.pan_display
    assert_equal "MIR", card.card_brand
  end

  test "sync_for_rebill retries GetState until RebillId then persists UserCards" do
    @payment.update!(provider_data: { "save_card" => true }, status: :succeeded)
    @order.update!(status: :accepted)
    attempts = 0
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:get_payment_state) do |**|
      attempts += 1
      base = { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED", "PaymentId" => "pay-sync-1" }
      if attempts >= 3
        base.merge(
          "RebillId" => "rebill-retry-8782",
          "Pan" => "220196******8782",
          "ExpDate" => "1029",
          "CardType" => "MIR"
        )
      else
        base
      end
    end

    sync = Payments::TbankPaymentSync.new(payment: @payment.reload, adapter: adapter)
    assert sync.sync_for_rebill!(retries: 5, pause: 0)
    assert_equal 3, attempts

    card = MobilePaymentMethod.find_by(customer_id: @customer.id, card_token: "rebill-retry-8782")
    assert card, "retry GetState должен создать UserCards"
    assert_equal "*8782", card.pan_display
  end

  test "sync_for_rebill logs missing RebillId when retries exhausted" do
    @payment.update!(provider_data: { "save_card" => true }, status: :succeeded)
    @order.update!(status: :accepted)

    logs = StringIO.new
    old_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(logs)

    sync = Payments::TbankPaymentSync.new(
      payment: @payment.reload,
      adapter: fake_adapter("Status" => "CONFIRMED", "PaymentId" => "pay-sync-1")
    )
    assert_not sync.sync_for_rebill!(retries: 3, pause: 0)
    assert_match(/\[UserCards\] missing RebillId payment_id=#{@payment.id}/, logs.string)
  ensure
    Rails.logger = old_logger
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
