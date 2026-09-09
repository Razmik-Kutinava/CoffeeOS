# frozen_string_literal: true

require "test_helper"

class Shop::EmailVerifiedCustomerLinkerTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @session = {}
    @email = "otp-email-#{SecureRandom.hex(3)}@example.com"
  end

  test "creates customer by email when none" do
    cid = Shop::EmailVerifiedCustomerLinker.link!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )
    assert cid.present?
    customer = MobileCustomer.find(cid)
    assert_equal @email, customer.email
    assert customer.email_verified
    assert_equal cid, Shop::CustomerSession.customer_id(@session, @tenant.id)
  end

  test "switches session to existing email customer instead of absorbing into guest" do
    guest = MobileCustomer.create!(phone: "+79001112233", first_name: "Гость", is_active: true, phone_verified: true)
    Shop::CustomerSession.set_customer_id!(@session, @tenant.id, guest.id)

    email_customer = MobileCustomer.create!(
      email: @email,
      first_name: "Mail",
      is_active: true,
      email_verified: true
    )
    card = MobilePaymentMethod.create!(
      customer_id: email_customer.id,
      payment_type: "card",
      card_token: "rebill-email-#{SecureRandom.hex(4)}",
      card_masked: "4300****0888",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )

    cid = Shop::EmailVerifiedCustomerLinker.link!(
      session: @session,
      tenant_id: @tenant.id,
      email: @email
    )

    assert_equal email_customer.id, cid
    assert_equal email_customer.id, Shop::CustomerSession.customer_id(@session, @tenant.id)
    assert_equal email_customer.id, card.reload.customer_id
    assert_equal 0, MobilePaymentMethod.where(customer_id: guest.id).count
    assert Payments::BindingStepUp.requires_step_up?(
      email_customer.reload,
      session: @session,
      tenant_id: @tenant.id
    )
  end
end
