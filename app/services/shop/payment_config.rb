# frozen_string_literal: true

module Shop
  module PaymentConfig
    module_function

    TBANK_SCRIPT_URL = "https://integrationjs.tbank.ru/integration.js"

    # Публичная витрина /shop/api — только онлайн-методы; cash только через barista POS.
    ONLINE_PAYMENT_METHODS = %w[card sbp apple_pay google_pay].freeze
    CASH_ONLINE_ERROR = "cash payment not available online"

    def online_payment_method_allowed?(raw)
      ONLINE_PAYMENT_METHODS.include?(raw.to_s.downcase)
    end

    def validate_online_payment_method!(raw)
      method = raw.to_s.downcase
      raise Shop::OrderCreator::Error, CASH_ONLINE_ERROR if method == "cash"
      return if method.blank?
      return if online_payment_method_allowed?(method)

      raise Shop::OrderCreator::Error, "Unsupported payment method: #{method}"
    end

    def simulate?
      value = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOP_SIMULATE_PAYMENT", "0"))
      if value && Rails.env.production?
        raise "SHOP_SIMULATE_PAYMENT must not be enabled in production"
      end

      value
    end

    def iframe_enabled?
      return false if simulate?

      ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOP_PAYMENT_IFRAME", "1"))
    end

    def terminal_key
      ENV["TBANK_TERMINAL_KEY"].presence
    end

    def client_json
      {
        simulate: simulate?,
        iframe: iframe_enabled?,
        terminal_key: terminal_key,
        integration_script_url: TBANK_SCRIPT_URL
      }
    end
  end
end
