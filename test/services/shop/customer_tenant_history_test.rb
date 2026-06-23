# frozen_string_literal: true

require "test_helper"

class Shop::CustomerTenantHistoryTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant_a = create_tenant!(slug: "b114-hist-a-#{SecureRandom.hex(3)}")
    @tenant_b = create_tenant!(slug: "b114-hist-b-#{SecureRandom.hex(3)}")
    @customer = create_mobile_customer!(email: "b114-hist-#{SecureRandom.hex(4)}@example.com")
    @session = {}
  end

  test "guest payload when no customer in session" do
    payload = Shop::CustomerTenantHistory.call(session: @session, current_tenant: @tenant_a)
    assert_equal false, payload[:switchable]
    assert_equal 1, payload[:tenants].size
    assert_nil payload[:last_ordered_tenant_id]
  end

  test "lists tenants from mobile order history" do
    create_mobile_order!(tenant: @tenant_a, customer: @customer, created_at: 2.days.ago)
    create_mobile_order!(tenant: @tenant_b, customer: @customer, created_at: 1.hour.ago)
    Shop::CustomerSession.set_customer_id!(@session, @tenant_a.id, @customer.id)

    payload = Shop::CustomerTenantHistory.call(session: @session, current_tenant: @tenant_a)
    assert_equal true, payload[:switchable]
    assert_equal 2, payload[:tenants].size
    assert_equal @tenant_b.id, payload[:last_ordered_tenant_id]
  end

  private

  def create_mobile_order!(tenant:, customer:, created_at: Time.current)
    Order.create!(
      tenant: tenant,
      customer_id: customer.id,
      order_number: "B114H-#{SecureRandom.hex(4)}",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100,
      created_at: created_at
    )
  end
end
