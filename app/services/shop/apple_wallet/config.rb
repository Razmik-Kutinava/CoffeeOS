# frozen_string_literal: true

module Shop
  module AppleWallet
    # Конфиг PassKit / APNs. Без сертификатов — simulate или unavailable.
    class Config
      def self.simulate?
        return false if force_unavailable?
        return true if ActiveModel::Type::Boolean.new.cast(ENV["WALLET_SIMULATE"])
        return true if Rails.env.test? && !certs_configured?

        false
      end

      def self.available?
        return false if force_unavailable?

        simulate? || certs_configured?
      end

      def self.certs_configured?
        pass_type_identifier.present? &&
          ENV["WALLET_TEAM_ID"].present? &&
          ENV["WALLET_SIGNER_CERT_PEM"].present? &&
          ENV["WALLET_SIGNER_KEY_PEM"].present?
      end

      def self.pass_type_identifier
        ENV["WALLET_PASS_TYPE_ID"].presence || "pass.ru.coffeeos.order"
      end

      def self.force_unavailable?
        ActiveModel::Type::Boolean.new.cast(ENV["WALLET_FORCE_UNAVAILABLE"])
      end

      def self.force_gen_error?
        ActiveModel::Type::Boolean.new.cast(ENV["WALLET_FORCE_GEN_ERROR"])
      end
    end
  end
end
