# frozen_string_literal: true

module Shop
  module AppleWallet
    # Upsert pass metadata + build + APNs. Unavailable → UnavailableError (caller fallback).
    class PassUpdater
      def self.call!(order:)
        new(order: order).call!
      end

      def initialize(order:)
        @order = order
      end

      def call!
        raise UnavailableError, "wallet unavailable" unless Config.available?

        pass = OrderWalletPass.find_or_initialize_by(order_id: @order.id)
        if pass.new_record?
          pass.tenant_id = @order.tenant_id
          pass.customer_id = @order.customer_id
          pass.serial_number = SecureRandom.hex(16)
          pass.authentication_token = SecureRandom.hex(16)
          pass.pass_type_identifier = Config.pass_type_identifier
          pass.revision = 1
        else
          pass.revision = pass.revision.to_i + 1
        end
        pass.status_label = @order.status

        built = PassBuilder.build!(
          order: @order,
          status_label: pass.status_label,
          serial_number: pass.serial_number,
          authentication_token: pass.authentication_token
        )
        pass.save!

        ApnsClient.notify_pass_update!(pass: pass)
        { pass: pass, built: built }
      end
    end
  end
end
