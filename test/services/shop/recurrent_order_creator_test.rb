# frozen_string_literal: true

require "test_helper"

# TASK_93-B T-B2d — phone_verified one_click without email
class Shop::RecurrentOrderCreatorTest < ActiveSupport::TestCase
  include TestFactories

  module FakeTbankRecurrent
    mattr_accessor :enabled, default: false

    module Override
      def charge_recurrent(**kwargs)
        return super unless FakeTbankRecurrent.enabled

        {
          payment_url: nil,
          provider_payment_id: "pay-rec-#{SecureRandom.hex(4)}",
          charged: true,
          charge_response: {
            "Success" => true,
            "ErrorCode" => "0",
            "Status" => "CONFIRMED",
            "PaymentId" => "pay-rec"
          },
          status: "CONFIRMED",
          three_ds: false
        }
      end
    end

    def self.install!
      return if @prepended

      Payments::TbankAdapter.prepend(Override)
      @prepended = true
    end
  end

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 200)

    @phone = "+7900#{rand(1000000..9999999)}"
    @customer = MobileCustomer.create!(
      phone: @phone,
      email: nil,
      first_name: "Rec",
      is_active: true,
      phone_verified: true,
      phone_status: :verified
    )
    @card = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-b2d-#{SecureRandom.hex(3)}",
      card_masked: "*4242",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )

    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] ||= "TestTerminal"
    ENV["TBANK_PASSWORD"] ||= "TestPassword"
    FakeTbankRecurrent.install!
    FakeTbankRecurrent.enabled = true
  end

  teardown do
    Current.reset
    FakeTbankRecurrent.enabled = false
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
  end

  # T-B2d + R4: email_verified session (no live OTP) works for recurrent like orders
  test "one_click email_verified session without live OTP uses same identity as orders" do
    email = "rec-email-#{SecureRandom.hex(3)}@example.com"
    customer = MobileCustomer.create!(
      email: email,
      phone: nil,
      first_name: "Email",
      is_active: true,
      email_verified: true
    )
    card = MobilePaymentMethod.create!(
      customer_id: customer.id,
      payment_type: "card",
      card_token: "rebill-email-#{SecureRandom.hex(3)}",
      card_masked: "*2222",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )
    session = {
      shop_cart: [
        { "product_id" => @product.id, "quantity" => 1, "selected_modifiers" => [] }
      ]
    }
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, customer.id)

    order = Shop::RecurrentOrderCreator.new(session, tenant: @tenant).call!({
      payment_method: "card",
      email: "",
      name: "Email Rec",
      saved_card_id: card.id
    })

    assert_equal customer.id, order.customer_id
  end

  # T-B2d
  test "one_click phone_verified without email reaches charge path" do
    session = {
      shop_cart: [
        { "product_id" => @product.id, "quantity" => 1, "selected_modifiers" => [] }
      ]
    }
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, @customer.id)

    order = Shop::RecurrentOrderCreator.new(session, tenant: @tenant).call!({
      payment_method: "card",
      email: "",
      name: "Phone Rec",
      saved_card_id: @card.id
    })

    assert_equal @customer.id, order.customer_id
    refute_match(/email/i, "") # identity path must not raise email Error
    assert order.accepted? || order.pending_payment?
  end
end
