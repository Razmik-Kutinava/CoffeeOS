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

  # V3-SEC-OTP-MERGE: switch to OTP profile — do NOT absorb donor cards into guest session.
  test "switches session to existing phone customer instead of absorbing into guest" do
    guest = MobileCustomer.create!(email: "guest-#{SecureRandom.hex(3)}@example.com", first_name: "Гость", is_active: true)
    Shop::CustomerSession.set_customer_id!(@session, @tenant.id, guest.id)

    phone_customer = MobileCustomer.create!(
      phone: @phone,
      first_name: "Phone",
      is_active: true,
      phone_verified: true
    )
    card = MobilePaymentMethod.create!(
      customer_id: phone_customer.id,
      payment_type: "card",
      card_token: "rebill-otp-#{SecureRandom.hex(4)}",
      card_masked: "4300****0777",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )

    cid = Shop::PhoneVerifiedCustomerLinker.link!(
      session: @session,
      tenant_id: @tenant.id,
      phone: @phone
    )

    assert_equal phone_customer.id, cid
    assert_equal phone_customer.id, Shop::CustomerSession.customer_id(@session, @tenant.id)
    assert_equal phone_customer.id, card.reload.customer_id
    assert_equal 0, MobilePaymentMethod.where(customer_id: guest.id).count
    assert Payments::BindingStepUp.requires_step_up?(
      phone_customer.reload,
      session: @session,
      tenant_id: @tenant.id
    )
  end
end
