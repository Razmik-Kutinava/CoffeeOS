# frozen_string_literal: true

module Shop
  # Публичный ключ Т-Банка для клиентского RSA CardData (B1.12-R2).
  class PaymentCryptoConfig
    def self.rsa_public_key
      ENV["TBANK_RSA_PUBLIC_KEY"].to_s.presence
    end

    def self.as_api_json
      key = rsa_public_key
      {
        rsa_public_key: key,
        card_data_ready: key.present?,
        card_data_format: "PAN=…;ExpDate=MMYY;CardHolder=…;CVV=…"
      }
    end
  end
end
