# frozen_string_literal: true

# Stub T-Bank Init для интеграционных тестов без SHOP_SIMULATE_PAYMENT.
module FakeTbankInit
  mattr_accessor :enabled, default: false
  mattr_accessor :provider_payment_id, default: nil

  module Override
    def init_payment(pay_type: nil, data: nil, **)
      unless FakeTbankInit.enabled
        return super
      end

      {
        payment_url: "https://pay.tbank.ru/test-init",
        provider_payment_id: FakeTbankInit.provider_payment_id
      }
    end
  end

  def self.install!
    return if @prepended

    Payments::TbankAdapter.prepend(Override)
    @prepended = true
  end

  def self.enable_for_test!(provider_payment_id: nil)
    install!
    self.enabled = true
    self.provider_payment_id = provider_payment_id || "fake-pay-#{SecureRandom.hex(4)}"
  end

  def self.disable!
    self.enabled = false
  end
end
