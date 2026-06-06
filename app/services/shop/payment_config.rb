# frozen_string_literal: true

module Shop
  module PaymentConfig
    module_function

    TBANK_SCRIPT_URL = "https://integrationjs.t-static.ru/integration.js"

    def simulate?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOP_SIMULATE_PAYMENT", "1"))
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
