# frozen_string_literal: true

require "test_helper"

class SyncContactToCrmJobTest < ActiveJob::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(phone: "+79001234567")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202609-crm-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    clear_enqueued_jobs
  end

  test "ST-9 enqueues job when marketing_consent true" do
    assert_enqueued_with(job: SyncContactToCrmJob) do
      OrderEmail.create!(
        order: @order,
        email: "crm-yes-#{SecureRandom.hex(3)}@example.com",
        marketing_consent: true,
        status: :pending
      )
    end
  end

  test "ST-9 does not enqueue when marketing_consent false" do
    assert_no_enqueued_jobs(only: SyncContactToCrmJob) do
      OrderEmail.create!(
        order: @order,
        email: "crm-no-#{SecureRandom.hex(3)}@example.com",
        marketing_consent: false,
        status: :pending
      )
    end
  end

  test "ST-9 perform calls CrmContactSync with identity fields" do
    order_email = OrderEmail.create!(
      order: @order,
      email: "sync-#{SecureRandom.hex(3)}@example.com",
      marketing_consent: true,
      status: :pending
    )
    clear_enqueued_jobs

    called = nil
    original = Shop::CrmContactSync.method(:call!)
    Shop::CrmContactSync.define_singleton_method(:call!) do |order:, order_email:|
      called = {
        order_id: order.id,
        email: order_email.email,
        customer_id: order.customer_id,
        tenant_id: order.tenant_id
      }
      { "id" => 42 }
    end

    SyncContactToCrmJob.perform_now(order_email.id)

    assert_not_nil called, "CrmContactSync.call! must be invoked"
    assert_equal @order.id, called[:order_id]
    assert_equal order_email.email, called[:email]
    assert_equal @customer.id, called[:customer_id]
    assert_equal @tenant.id, called[:tenant_id]
  ensure
    Shop::CrmContactSync.define_singleton_method(:call!, original) if original
  end

  test "ST-11 bounced skips CRM sync" do
    order_email = OrderEmail.create!(
      order: @order,
      email: "bounce-#{SecureRandom.hex(3)}@example.com",
      marketing_consent: true,
      status: :pending
    )
    order_email.update!(status: :bounced)
    clear_enqueued_jobs

    called = false
    original = Shop::CrmContactSync.method(:call!)
    Shop::CrmContactSync.define_singleton_method(:call!) do |**|
      called = true
    end

    SyncContactToCrmJob.perform_now(order_email.id)

    refute called
  ensure
    Shop::CrmContactSync.define_singleton_method(:call!, original) if original
  end

  test "ST-9 CRM error schedules Solid Queue retry" do
    order_email = OrderEmail.create!(
      order: @order,
      email: "err-#{SecureRandom.hex(3)}@example.com",
      marketing_consent: true,
      status: :pending
    )
    clear_enqueued_jobs

    original = Shop::CrmContactSync.method(:call!)
    Shop::CrmContactSync.define_singleton_method(:call!) do |**|
      raise Shop::CrmContactSync::Error, "CRM down"
    end

    assert_enqueued_with(job: SyncContactToCrmJob) do
      SyncContactToCrmJob.perform_now(order_email.id)
    end
  ensure
    Shop::CrmContactSync.define_singleton_method(:call!, original) if original
  end
end
