# frozen_string_literal: true

require "test_helper"

# TASK_93-F — F3 StuckPayments GetState + дожим
class Payments::StuckPaymentsCheckJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include TestFactories
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    clear_enqueued_jobs
    Payments::StuckPaymentsCheckJob.sync_adapter = nil
  end

  teardown do
    Current.reset
    Payments::StuckPaymentsCheckJob.sync_adapter = nil
    clear_enqueued_jobs
  end

  def create_stuck_payment!(provider_payment_id:, created_at:, amount: 200)
    order = Order.create!(
      tenant: @tenant,
      order_number: "ORD-STUCK-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "pending_payment",
      total_amount: amount,
      discount_amount: 0,
      final_amount: amount,
      created_at: created_at
    )
    Payment.create!(
      order: order,
      tenant: @tenant,
      amount: amount,
      method: "card",
      provider: "tbank",
      status: "pending",
      provider_payment_id: provider_payment_id,
      created_at: created_at
    )
  end

  def fake_adapter(fields)
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:get_payment_state) do |**|
      { "Success" => true, "ErrorCode" => "0" }.merge(fields)
    end
    adapter
  end

  # T-F3a
  test "T-F3a syncs stuck pending via GetState to succeeded" do
    payment = create_stuck_payment!(
      provider_payment_id: "pay-stuck-ok",
      created_at: 45.minutes.ago
    )
    Payments::StuckPaymentsCheckJob.sync_adapter = fake_adapter(
      "Status" => "CONFIRMED",
      "PaymentId" => "pay-stuck-ok",
      "Amount" => 20_000
    )

    assert_no_enqueued_jobs(only: TelegramAlertJob) do
      Payments::StuckPaymentsCheckJob.perform_now
    end

    assert_equal "succeeded", payment.reload.status
    assert_equal "accepted", payment.order.reload.status
  end

  # T-F3b
  test "T-F3b alerts when stuck without provider_payment_id" do
    payment = create_stuck_payment!(
      provider_payment_id: nil,
      created_at: 45.minutes.ago
    )
    payment.update_columns(provider_payment_id: nil)

    assert_enqueued_with(job: TelegramAlertJob) do
      Payments::StuckPaymentsCheckJob.perform_now
    end
    assert_equal "pending", payment.reload.status
  end

  # T-F3c
  test "T-F3c GetState failure still alerts and continues" do
    bad = create_stuck_payment!(
      provider_payment_id: "pay-stuck-bad",
      created_at: 50.minutes.ago
    )
    good = create_stuck_payment!(
      provider_payment_id: "pay-stuck-good",
      created_at: 40.minutes.ago,
      amount: 150
    )

    boom = Payments::TbankAdapter.new
    boom.define_singleton_method(:get_payment_state) do |payment_id:, **|
      raise Payments::TbankAdapter::ApiError.new(error_code: "99", message: "boom") if payment_id == "pay-stuck-bad"

      {
        "Success" => true,
        "ErrorCode" => "0",
        "Status" => "CONFIRMED",
        "PaymentId" => payment_id,
        "Amount" => 15_000
      }
    end
    Payments::StuckPaymentsCheckJob.sync_adapter = boom

    assert_enqueued_jobs 1, only: TelegramAlertJob do
      assert_nothing_raised { Payments::StuckPaymentsCheckJob.perform_now }
    end

    assert_equal "pending", bad.reload.status
    assert_equal "succeeded", good.reload.status
  end

  # T-F3d
  test "T-F3d ignores fresh payments under threshold" do
    payment = create_stuck_payment!(
      provider_payment_id: "pay-fresh",
      created_at: 5.minutes.ago
    )
    called = false
    adapter = Payments::TbankAdapter.new
    adapter.define_singleton_method(:get_payment_state) do |**|
      called = true
      { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED", "PaymentId" => "pay-fresh", "Amount" => 20_000 }
    end
    Payments::StuckPaymentsCheckJob.sync_adapter = adapter

    assert_no_enqueued_jobs(only: TelegramAlertJob) do
      Payments::StuckPaymentsCheckJob.perform_now
    end
    assert_not called, "fresh payment must not call GetState"
    assert_equal "pending", payment.reload.status
  end
end
