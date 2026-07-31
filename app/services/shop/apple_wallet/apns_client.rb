# frozen_string_literal: true

module Shop
  module AppleWallet
    # APNs empty push для обновления pass на lock screen.
    class ApnsClient
      class Error < StandardError; end

      def self.notify_pass_update!(pass:)
        new.notify_pass_update!(pass: pass)
      end

      def notify_pass_update!(pass:)
        if Config.simulate? || !Config.certs_configured?
          Rails.logger.info(
            "[Shop::AppleWallet::ApnsClient] simulate pass update serial=#{pass.serial_number} rev=#{pass.revision}"
          )
          return { simulated: true }
        end

        raise Error, "APNs Wallet push not configured (need device tokens + APNs key)"
      end
    end
  end
end
