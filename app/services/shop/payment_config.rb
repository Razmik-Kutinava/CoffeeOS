# frozen_string_literal: true

module Shop
  module PaymentConfig
    module_function

    TBANK_SCRIPT_URL = "https://integrationjs.tbank.ru/integration.js"

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
