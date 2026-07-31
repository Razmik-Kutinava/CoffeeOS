# frozen_string_literal: true

module Shop
  module AppleWallet
    # Сборка .pkpass (simulate stub; prod — PKCS7 signing по ENV certs).
    class PassBuilder
      def self.build!(order:, status_label:, serial_number:, authentication_token:)
        raise GenerationError, "forced generation error" if Config.force_gen_error?
        raise UnavailableError, "wallet unavailable" unless Config.available?

        if Config.simulate? || !Config.certs_configured?
          return {
            simulated: true,
            serial_number: serial_number,
            authentication_token: authentication_token,
            status_label: status_label,
            bytes: "PKPASS_STUB:#{order.id}:#{status_label}"
          }
        end

        # Полная PKCS7-подпись — когда появятся WALLET_* certs в Fly secrets.
        raise GenerationError, "WALLET signer configured but PassKit signing not implemented yet"
      end
    end
  end
end
