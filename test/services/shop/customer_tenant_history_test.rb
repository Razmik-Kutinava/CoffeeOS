# frozen_string_literal: true

require "test_helper"

class Shop::CustomerTenantHistoryTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @org = create_organization!
    @org_alt = create_organization!(slug: "b114-alt-#{SecureRandom.hex(3)}")
    @tenant_a = create_tenant!(
      slug: "b114-hist-a-#{SecureRandom.hex(3)}",
      organization: @org,
      city: "Москва",
      address: "ул. Ленина, 10",
      latitude: 55.7558,
      longitude: 37.6173
    )
    @tenant_b = create_tenant!(
      slug: "b114-hist-b-#{SecureRandom.hex(3)}",
      organization: @org,
      city: "Москва",
      address: "ул. Пушкина, 5",
      latitude: 55.7619,
      longitude: 37.6056
    )
    @tenant_c = create_tenant!(
      slug: "b114-hist-c-#{SecureRandom.hex(3)}",
      organization: @org_alt,
      city: "Москва",
      address: "ул. Тверская, 12",
      latitude: 55.7568,
      longitude: 37.6158
    )
    @tenant_spb = create_tenant!(
      slug: "b114-hist-spb-#{SecureRandom.hex(3)}",
      organization: @org_alt,
      city: "Санкт-Петербург",
      address: "Невский, 1",
      latitude: 59.9343,
      longitude: 30.3351
    )
    @customer = create_mobile_customer!(email: "b114-hist-#{SecureRandom.hex(4)}@example.com")
    @session = {}
  end

  test "guest lists all sales points in same city sorted by distance" do
    payload = Shop::CustomerTenantHistory.call(session: @session, current_tenant: @tenant_a)

    assert_equal true, payload[:switchable]
    ids = payload[:tenants].map { |t| t[:id] }
    assert_equal [@tenant_a.id, @tenant_c.id, @tenant_b.id], ids
    assert payload[:tenants].first[:is_current]
    assert_nil payload[:last_ordered_tenant_id]
    refute_includes ids, @tenant_spb.id
  end

  test "single tenant in city is not switchable" do
    @tenant_b.update!(city: "Казань")
    payload = Shop::CustomerTenantHistory.call(session: @session, current_tenant: @tenant_b)

    assert_equal false, payload[:switchable]
    assert_equal 1, payload[:tenants].size
  end

  test "last_ordered_tenant_id from mobile orders when customer logged in" do
    create_mobile_order!(tenant: @tenant_a, customer: @customer, created_at: 2.days.ago)
    create_mobile_order!(tenant: @tenant_b, customer: @customer, created_at: 1.hour.ago)
    Shop::CustomerSession.set_customer_id!(@session, @tenant_a.id, @customer.id)

    payload = Shop::CustomerTenantHistory.call(session: @session, current_tenant: @tenant_a)
    assert_equal @tenant_b.id, payload[:last_ordered_tenant_id]
    assert_equal 3, payload[:tenants].size
  end

  test "inactive current tenant is not forced into switchable list" do
    @tenant_a.update!(status: "inactive")
    payload = Shop::CustomerTenantHistory.call(session: @session, current_tenant: @tenant_a)

    ids = payload[:tenants].map { |t| t[:id] }
    refute_includes ids, @tenant_a.id
    assert_includes ids, @tenant_b.id
    assert_includes ids, @tenant_c.id
  end

  test "last_ordered_tenant_id skips inactive tenants" do
    create_mobile_order!(tenant: @tenant_a, customer: @customer, created_at: 2.days.ago)
    create_mobile_order!(tenant: @tenant_b, customer: @customer, created_at: 1.hour.ago)
    @tenant_b.update!(status: "inactive")
    Shop::CustomerSession.set_customer_id!(@session, @tenant_a.id, @customer.id)

    payload = Shop::CustomerTenantHistory.call(session: @session, current_tenant: @tenant_a)
    assert_equal @tenant_a.id, payload[:last_ordered_tenant_id]
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
