# frozen_string_literal: true

require "test_helper"

class Payments::BindingStepUpTest < ActiveSupport::TestCase
  include TestFactories

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
end
