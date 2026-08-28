# frozen_string_literal: true

require "test_helper"

class SendOrderReceiptEmailJobTest < ActiveJob::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202608-receipt-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    @order_email = OrderEmail.create!(order: @order, email: "receipt-#{SecureRandom.hex(3)}@example.com", status: :pending)
    clear_enqueued_jobs
    @order_email.update!(status: :pending)
  end

  test "delivers receipt via Brevo and marks sent" do
    SendOrderReceiptEmailJob.perform_now(@order_email.id)

    assert_equal "sent", @order_email.reload.status
    assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob)
  end

  test "marks failed when Brevo raises" do
    original = Shop::BrevoClient.method(:deliver_html!)
    Shop::BrevoClient.define_singleton_method(:deliver_html!) do |**|
      raise Shop::BrevoClient::Error, "BREVO_API_KEY не задан"
    end

    SendOrderReceiptEmailJob.perform_now(@order_email.id)

    assert_equal "failed", @order_email.reload.status
  ensure
    Shop::BrevoClient.define_singleton_method(:deliver_html!, original)
  end
end
