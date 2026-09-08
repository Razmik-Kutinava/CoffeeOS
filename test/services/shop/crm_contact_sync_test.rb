# frozen_string_literal: true

require "test_helper"

class Shop::CrmContactSyncTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @customer = create_mobile_customer!(phone: "+79007654321")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Guest",
      order_number: "202609-crmsync-#{SecureRandom.hex(2)}",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    @order_email = OrderEmail.create!(
      order: @order,
      email: "payload-#{SecureRandom.hex(3)}@example.com",
      marketing_consent: true,
      status: :pending
    )
    @prev_key = ENV["BREVO_API_KEY"]
    @prev_list = ENV["BREVO_CRM_LIST_ID"]
    @prev_enabled = ENV["CRM_SYNC_ENABLED"]
    ENV["BREVO_API_KEY"] = "xkeysib-test-crm-key"
    ENV.delete("BREVO_CRM_LIST_ID")
    ENV.delete("CRM_SYNC_ENABLED")
  end

  teardown do
    if @prev_key.nil?
      ENV.delete("BREVO_API_KEY")
    else
      ENV["BREVO_API_KEY"] = @prev_key
    end
    if @prev_list.nil?
      ENV.delete("BREVO_CRM_LIST_ID")
    else
      ENV["BREVO_CRM_LIST_ID"] = @prev_list
    end
    if @prev_enabled.nil?
      ENV.delete("CRM_SYNC_ENABLED")
    else
      ENV["CRM_SYNC_ENABLED"] = @prev_enabled
    end
  end

  test "ST-9 payload includes email identity and marketing_consent" do
    payload = nil
    original = Shop::CrmContactSync.method(:post_contact!)
    Shop::CrmContactSync.define_singleton_method(:post_contact!) do |body|
      payload = body
      { "id" => 1001 }
    end

    result = Shop::CrmContactSync.call!(order: @order, order_email: @order_email)

    assert_equal 1001, result["id"]
    assert_equal @order_email.email, payload["email"]
    assert_equal true, payload["updateEnabled"]
    attrs = payload["attributes"]
    assert_equal @customer.id.to_s, attrs["COFFEEOS_CUSTOMER_ID"]
    assert_equal @order.id.to_s, attrs["COFFEEOS_ORDER_ID"]
    assert_equal @tenant.id.to_s, attrs["COFFEEOS_TENANT_ID"]
    assert_equal true, attrs["MARKETING_CONSENT"]
    assert_equal @customer.phone, attrs["SMS"]
  ensure
    Shop::CrmContactSync.define_singleton_method(:post_contact!, original) if original
  end

  test "ST-14 second call uses upsert updateEnabled not duplicate create" do
    bodies = []
    original = Shop::CrmContactSync.method(:post_contact!)
    Shop::CrmContactSync.define_singleton_method(:post_contact!) do |body|
      bodies << body
      { "id" => 55 }
    end

    first = Shop::CrmContactSync.call!(order: @order, order_email: @order_email)
    second = Shop::CrmContactSync.call!(order: @order, order_email: @order_email)

    assert_equal first["id"], second["id"]
    assert_equal 2, bodies.size
    assert bodies.all? { |b| b["updateEnabled"] == true }
    assert_equal bodies[0]["email"], bodies[1]["email"]
  ensure
    Shop::CrmContactSync.define_singleton_method(:post_contact!, original) if original
  end

  test "ST-9 raises when BREVO_API_KEY missing" do
    ENV.delete("BREVO_API_KEY")
    assert_raises(Shop::CrmContactSync::Error) do
      Shop::CrmContactSync.call!(order: @order, order_email: @order_email)
    end
  end

  test "ST-9 kill-switch CRM_SYNC_ENABLED=0 is no-op" do
    ENV["CRM_SYNC_ENABLED"] = "0"
    called = false
    original = Shop::CrmContactSync.method(:post_contact!)
    Shop::CrmContactSync.define_singleton_method(:post_contact!) do |*|
      called = true
      { "id" => 1 }
    end

    result = Shop::CrmContactSync.call!(order: @order, order_email: @order_email)

    assert_equal :disabled, result
    refute called
  ensure
    Shop::CrmContactSync.define_singleton_method(:post_contact!, original) if original
  end

  test "ST-9 HTTP error raises for retry" do
    original = Shop::CrmContactSync.method(:post_contact!)
    Shop::CrmContactSync.define_singleton_method(:post_contact!) do |*|
      raise Shop::CrmContactSync::Error, "Brevo Contacts 503"
    end

    assert_raises(Shop::CrmContactSync::Error) do
      Shop::CrmContactSync.call!(order: @order, order_email: @order_email)
    end
  ensure
    Shop::CrmContactSync.define_singleton_method(:post_contact!, original) if original
  end
end
