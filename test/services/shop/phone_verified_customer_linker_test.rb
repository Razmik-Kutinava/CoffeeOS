# frozen_string_literal: true

require "test_helper"

class Shop::PhoneVerifiedCustomerLinkerTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @session = {}
    @phone = "+79005556677"
  end

  test "creates customer by phone" do
    cid = Shop::PhoneVerifiedCustomerLinker.link!(
      session: @session,
      tenant_id: @tenant.id,
      phone: @phone
    )
    assert cid.present?
    customer = MobileCustomer.find(cid)
    assert_equal @phone, customer.phone
    assert_equal cid, Shop::CustomerSession.customer_id(@session, @tenant.id)
  end

  test "attaches phone to session customer that has email" do
    email = "link-phone-#{SecureRandom.hex(3)}@example.com"
    existing = MobileCustomer.create!(email: email, first_name: "Гость", is_active: true)
    Shop::CustomerSession.set_customer_id!(@session, @tenant.id, existing.id)

    cid = Shop::PhoneVerifiedCustomerLinker.link!(
      session: @session,
      tenant_id: @tenant.id,
      phone: @phone
    )
    assert_equal existing.id, cid
    assert_equal @phone, existing.reload.phone
    assert_equal email, existing.email
  end

  test "merges phone customer into session email customer on conflict" do
    email = "merge-email-#{SecureRandom.hex(3)}@example.com"
    email_customer = MobileCustomer.create!(email: email, first_name: "Mail", is_active: true, email_verified: true)
    Shop::CustomerSession.set_customer_id!(@session, @tenant.id, email_customer.id)

    phone_customer = MobileCustomer.create!(phone: @phone, first_name: "Phone", is_active: true, phone_verified: true)

    cid = Shop::PhoneVerifiedCustomerLinker.link!(
      session: @session,
      tenant_id: @tenant.id,
      phone: @phone
    )
    assert_equal email_customer.id, cid
    email_customer.reload
    phone_customer.reload
    assert_equal @phone, email_customer.phone
    assert email_customer.phone_verified
    assert_equal email, email_customer.email
    assert_equal false, phone_customer.is_active
    assert_nil phone_customer.phone
  end
end
