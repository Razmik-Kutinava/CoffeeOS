# frozen_string_literal: true

require "test_helper"

class Payments::BindingStepUpTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @session = {}
  end

  test "otp phone comes from account not form" do
    customer = create_mobile_customer!(phone: "+79001234567", email: "step-#{SecureRandom.hex(3)}@ex.com")
    assert_equal "+79001234567", Payments::BindingStepUp.otp_phone_for(customer)
    assert_equal "+79001234567",
      Payments::BindingStepUp.resolve_otp_destination(customer: customer, form_phone: "+79009998877")
  end

  test "requires step up for recycled_risk and unverified" do
    c = create_mobile_customer!(phone: "+79007654321", email: "risk-#{SecureRandom.hex(3)}@ex.com")
    c.update!(phone_status: :recycled_risk)
    assert Payments::BindingStepUp.requires_step_up?(c)

    c2 = create_mobile_customer!(phone: "+79007654322", email: "uv-#{SecureRandom.hex(3)}@ex.com")
    c2.update_columns(phone_verified: false, phone_status: "unverified")
    assert Payments::BindingStepUp.requires_step_up?(c2)
  end

  # V3-SEC-OTP-MERGE: after OTP login into profile with cards, charge locked until unlock.
  test "session lock after otp login blocks one click until unlock" do
    customer = create_mobile_customer!(phone: "+79003334455", email: "lock-#{SecureRandom.hex(3)}@ex.com")
    customer.update!(phone_verified: true, phone_status: :verified)
    MobilePaymentMethod.create!(
      customer_id: customer.id,
      payment_type: "card",
      card_token: "rebill-lock-#{SecureRandom.hex(4)}",
      card_masked: "4300****0666",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )
    Shop::CustomerSession.set_customer_id!(@session, @tenant.id, customer.id)
    Payments::BindingStepUp.lock_payments!(@session, @tenant.id)

    assert Payments::BindingStepUp.requires_step_up?(
      customer,
      session: @session,
      tenant_id: @tenant.id
    )

    err = assert_raises(Shop::OrderCreator::Error) do
      Shop::OneClickPaymentService.new(@session, tenant: @tenant).call!(
        saved_card_id: MobilePaymentMethod.find_by!(customer_id: customer.id).id,
        items: []
      )
    end
    assert_match(/step.?up|подтверд/i, err.message)
    assert_equal true, err.step_up_required

    Payments::BindingStepUp.unlock_payments!(@session, @tenant.id)
    refute Payments::BindingStepUp.requires_step_up?(
      customer,
      session: @session,
      tenant_id: @tenant.id
    )
  end
end
